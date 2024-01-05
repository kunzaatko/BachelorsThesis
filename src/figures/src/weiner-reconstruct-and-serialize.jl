include("weiner-reconstruction.jl")

modulations = collect(partition(repeat(IP_params[:modulations], inner=3), 3))
phase_offsets = map(IP_params[:phase_offsets]) do ϕ
    ([0, 2π / 3, 4π / 3] .+ ϕ) .% 2π
end
shifts = IP_params[:shifts]

imgs = map(LR_beads) do img
    float64.(gray.(img))
end

otf_model = IdealOTFwithCurvature(488u"nm", 1.4, 1.0, 0.9) # Adams

patch_PSF_weiner_reconstruction(patch) = weiner_reconstruction(imgs, shifts, phase_offsets, modulations, MeasuredPSF(get_psf_averaged_estimate(patch)[:psf], 61u"nm"))
# patch_reconstructions = Dict()
for patch in ["CC", "LT", "RT", "LB", "RB"]
    s_out, f_out = patch_PSF_weiner_reconstruction(patch)
    serialize("data/spatial_weiner_reconstruction_$(patch).ser", s_out)
    serialize("data/fourier_weiner_reconstruction_$(patch).ser", f_out)
    # patch_reconstructions[patch] = (s_out, f_out)
end
# serialize("data/weiner_patch_reconstructions_dict.ser", patch_reconstructions)

s_out_model, f_out_model = weiner_reconstruction(imgs, shifts, phase_offsets, modulations, otf_model)
serialize("data/spatial_weiner_reconstruction_model.ser", s_out_model)
serialize("data/fourier_weiner_reconstruction_model.ser", f_out_model)
