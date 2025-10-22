include("init.jl")
using SIMIlluminationPatterns: IlluminatedImage, ShiftedComponent, separation_matrix # separate_components
using SIMParameterEstimation: separate_components
using TransferFunctions: padtosize, shift, FourierShiftTheorem, ModelTransferFunction, TransferFunction
using Tullio, IterTools, NPZ, FFTW
using ImageFiltering: Fill

# NOTE: HR_size is not fully implemented because it does not work with the shifts... This can be altered by using the
# δ function in `SIMIlluminationPatterns` package <12-12-23> 
function weiner_reconstruction(imgs, shifts, phase_offsets, modulations, transfer_function::TransferFunction; HR_size=(1024, 1024), Δxy_LR=61u"nm", ω=0.05)
    Δxy_HR = Δxy_LR .* size(imgs[1]) ./ HR_size
    IPs = map(modulations, phase_offsets, shifts) do o_ms, o_ϕs, o_Δ
        (Harmonic(m, o_Δ, HR_size, ϕ, Δxy_HR) for (m, ϕ) in zip(o_ms, o_ϕs))
    end
    I_imgs = [(IlluminatedImage(img, ip, Δxy_HR) for (img, ip) in zip(o_imgs, o_IPs)) for (o_imgs, o_IPs) in zip(partition(imgs, 3), IPs)]
    I_imgs = map(collect, I_imgs)
    I_imgs = map(splat(tuple), I_imgs)

    Cs = separate_components.(I_imgs)
    Cs_vec = vcat(map(c -> [c...], Cs)...)
    Δs = map(c -> c.shift, Cs_vec)

    Δ_Cs_vec = map(Cs_vec) do c
        padded = padtosize(c.component, HR_size...; fourier=true) |> fftshift
        Δ_c = TransferFunctions.shift(FourierShiftTheorem(:fourier, true), padded, c.shift) |> ifftshift
        Δ_c
    end

    local Δ_OTFs
    if transfer_function isa ModelTransferFunction
        Δ_OTFs = map(Δs) do s
            otf(transfer_function, HR_size, Δxy_HR; δ=(-1 .* s))
        end
    else # transfer_function isa MeasuredTransferFunctions
        Δ_OTFs = map(Δs) do s
            shift(FourierShiftTheorem(:fourier, false), otf(transfer_function, HR_size, Δxy_HR), s)
        end
    end
    num_Cs = map(Δ_Cs_vec, Δ_OTFs) do c, otf
        conj(otf) .* c
    end
    num = sum(num_Cs)

    denom = sum(otf -> conj(otf) .* otf, Δ_OTFs) .+ ω^2

    fourier_out = num ./ denom
    spatial_out = ifft(fourier_out)

    return spatial_out, fourier_out
end
