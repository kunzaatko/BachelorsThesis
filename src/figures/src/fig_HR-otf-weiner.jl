include("init.jl")
using IterTools
using SIMIlluminationPatterns: IlluminatedImage, separate_components
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

transfer_function = IdealOTFwithCurvature(488u"nm", 1.4, 1.0, 0.9)

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
Δ_OTFs = map(Δs) do s
    otf(transfer_function, HR_size, Δxy_HR; δ=(-1 .* s))
end

denom = sum(otf -> conj(otf) .* otf, Δ_OTFs)#  .+ ω^2

function fig_OTF_HR_model_weiner()
    fig, ax, _ = image(fftshift(denom))

    denom_center_x, denom_center_y = size(denom) ./ 2 .+ 0.5
    ax.xticks, ax.yticks = ([denom_center_x], [L"0"]), ([denom_center_y], [L"0"])
    linesegments!(ax, [size(denom, 1), 0, denom_center_x, denom_center_x], [denom_center_y, denom_center_y, size(denom, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)
    return fig
end

savefig(
    fig_OTF_HR_model_weiner, FIG_NAME;
    skip=[:vector],
    override_theme=merge(NO_SPINE, DATA_ASPECT)
)
