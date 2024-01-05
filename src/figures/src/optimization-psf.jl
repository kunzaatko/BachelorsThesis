include("init.jl")
using PaddedViews, Interpolations, IterTools, Tullio, OffsetArrays
using TransferFunctions: taperedges, Cosine

modulations = repeat([2ones(3)], 3)
phase_offsets = map(IP_params[:phase_offsets]) do ϕ
    ([0, 2π / 3, 4π / 3] .+ ϕ) .% 2π
end
shifts = IP_params[:shifts]
HR_size = (1024, 1024)
Δxy_HR = 30.5u"nm"

IPs = map(modulations, phase_offsets, shifts) do o_ms, o_ϕs, o_Δ
    (Harmonic(m, o_Δ, HR_size, ϕ, Δxy_HR) for (m, ϕ) in zip(o_ms, o_ϕs))
end
IPs = vcat(map(collect, IPs)...)
HR_I = map(IPs) do ip
    ip_grid = ip(Float64; Δxy=Δxy_HR)(-512:511, -512:511)
    # NOTE: This has little effect, but is theoretically necessary for consistent sum intensity in the `forward` function
    ip_grid ./= sum(ip_grid) / (HR_size[1] * HR_size[2])
end |> stack

LR_imgs = map(LR_beads) do img
    float64.(gray.(img)) |> transpose
end
LR_stack_resized = map(LR_imgs) do img
    imresize(img, 1024, 1024, method=Constant())
end |> stack
LR_stack_resized = taperedges(Cosine(1), LR_stack_resized, 15, (1, 2))
LR_forward_norm_sums = sum(LR_stack_resized; dims=(1, 2))

# NOTE: The edges are tapered for the HR model estimation, so they should be tapered for the LR optimization data as
# well  
# taperedges(Cosine(1), LR_beads, 10, (1, 2))

HR_model = deserialize("data/beads_model.ser")

# TODO: Need to generate LR model using the illuminations and the model <15-12-23> 
local HR_stack_I, x, y, z
@tullio HR_stack_I[x, y, z] := HR_model[x, y] * HR_I[x, y, z]
f_HR_stack = fft(HR_stack_I, (1, 2))

"""
Takes an `psf` and produces the corresponding `LR_stack_resized`
"""
data_axes = axes(OffsetArrays.centered(f_HR_stack[:, :, 2]))
function forward_model(psf)::Array{Float64,3}
    # TODO: Generate OTF from psf step <15-12-23> 
    # psf = OffsetArrays.centered(psf)
    OTF = fft(psf)
    f_LR_stack = f_HR_stack .* cat(OTF, OTF, OTF, OTF, OTF, OTF, OTF, OTF, OTF, dims=3)
    LR_stack = ifft(f_LR_stack, (1, 2))
    LR_stack_real = real(LR_stack)
    # LR_stack_normed = LR_stack_real .* (LR_forward_norm_sums ./ sum(LR_stack_real; dims=(1, 2)))
    return LR_stack_real
end

rec0 = ones(1024, 1024)

psf_out, _ = invert(LR_stack_resized, rec0, forward_model; iterations=5)

# TODO: Make it into a 60×60 grid instead of optimizing full 1024×1024 <21-12-23> 
