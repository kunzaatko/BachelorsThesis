include("init.jl")
using IterTools
using SIMIlluminationPatterns: IlluminatedImage, separate_components
using TransferFunctions: padtosize, shift, FourierShiftTheorem
using FFTW

const FIG_NAME = getbase(@__FILE__)

modulations = collect(partition(repeat(IP_params[:modulations], inner=3), 3))
phase_offsets = map(IP_params[:phase_offsets]) do ϕ
    ([0, 2π / 3, 4π / 3] .+ ϕ) .% 2π
end
shifts = IP_params[:shifts]

imgs = map(LR_beads) do img
    float64.(gray.(img))
end

Δxy_LR = LR_beads_Δxy
HR_size = (1024, 1024)

# transfer_function = IdealOTFwithCurvature(488u"nm", 1.4, 1.0, 0.9)

Δxy_HR = Δxy_LR .* size(imgs[1]) ./ HR_size

IPs = map(modulations, phase_offsets, shifts) do o_ms, o_ϕs, o_Δ
    (Harmonic(m, o_Δ, HR_size, ϕ, Δxy_HR) for (m, ϕ) in zip(o_ms, o_ϕs))
end
I_imgs = [(IlluminatedImage(img, ip, Δxy_HR) for (img, ip) in zip(o_imgs, o_IPs)) for (o_imgs, o_IPs) in zip(partition(imgs, 3), IPs)]
I_imgs = map(collect, I_imgs)
I_imgs = map(splat(tuple), I_imgs)
Cs = separate_components.(I_imgs)
Cs_vec = vcat(map(c -> [c...], Cs)...)

Δ_Cs_vec = map(Cs_vec) do c
    padded = padtosize(c.component, HR_size...; fourier=true) |> fftshift
    Δ_c = TransferFunctions.shift(FourierShiftTheorem(:fourier, true), padded, c.shift) |> ifftshift
    Δ_c
end

npad = 10
nw, nh = size(Δ_Cs_vec[1])
Cs_mos = map(Cs -> log2.(fftshift(abs.(Cs)) .+ 1), Δ_Cs_vec)[[3, 1, 2, 6, 4, 5, 9, 7, 8]]
Cs_mos = map(Cs -> scaleminmax(extrema(stack(Cs_mos))...).(Cs), Cs_mos)
mos = mosaic(Cs_mos...; ncol=3, rowmajor=true, fillvalue=1, npad)

function fig_shifted_components()
    fig, ax, _ = image(mos)
    x_centers = [(nh + 1) / 2, (3nh + 1) / 2 + npad, (5nh + 1) / 2 + 2npad]
    y_centers = [(nw + 1) / 2, (3nw + 1) / 2 + npad, (5nw + 1) / 2 + 2npad]

    ax.xticks = (x_centers, map(x -> latexstring("n = $x"), 1:3))
    ax.yticks = (y_centers, [L"-\vec{k}^{n}_i", L"\vec{0}", L"\vec{k}^{n}_i"])

    x_linesegments_lims = map(x_centers) do x
        x .+ (-(nw / 2), (nw / 2))
    end

    y_linesegments_lims = map(y_centers) do y
        y .+ (-(nh / 2), (nh / 2))
    end

    segments_x = []
    segments_y = []
    for xl in x_linesegments_lims
        for yl in y_linesegments_lims
            x_mid, y_mid = sum(xl) ./ 2, sum(yl) ./ 2
            append!(segments_x, [xl[1] - 1 / 2, xl[2] - 1 / 2, x_mid, x_mid])
            append!(segments_y, [y_mid, y_mid, yl[1] - 1 / 2, yl[2] - 1 / 2])
        end
    end

    linesegments!(ax, float.(segments_x), float.(segments_y); linestyle=:dashdot, alpha=0.5, color=:white, linewidth=0.5)
    return fig
end

savefig(fig_shifted_components, FIG_NAME; hwratio=1, skip=[:vector], override_theme=merge(NO_SPINE, DATA_ASPECT))

# ax = [Makie.Axis(fig[ceil(Int64, i / 3), (i-1)%3+1], title="$i") for i in 1:9]


# fig, ax, _ = image(fftshift(denom), axis=(; aspect=DataAspect()))
