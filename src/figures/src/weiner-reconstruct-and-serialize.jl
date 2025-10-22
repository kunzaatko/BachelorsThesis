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


modulations_ccp = collect(partition(repeat(IP_params_ccp[:modulations], inner=3), 3))
phase_offsets_ccp = map(IP_params_ccp[:phase_offsets]) do ϕ
    ([0, 2π / 3, 4π / 3] .+ ϕ) .% 2π
end
shifts_ccp = IP_params_ccp[:shifts]

imgs_ccp = map(LR_ccp) do img
    float64.(gray.(img))
end

s_out_model_ccp, f_out_model_ccp = weiner_reconstruction(imgs_ccp, shifts_ccp, phase_offsets_ccp, modulations_ccp, otf_model)
serialize("data/spatial_weiner_reconstruction_model_ccp.ser", s_out_model_ccp)
serialize("data/fourier_weiner_reconstruction_model_ccp.ser", f_out_model_ccp)

patch_PSF_weiner_reconstruction_ccp(patch) = weiner_reconstruction(imgs_ccp, shifts_ccp, phase_offsets_ccp, modulations_ccp, MeasuredPSF(get_psf_averaged_estimate(patch)[:psf], 61u"nm"))

for patch in ["CC", "LT", "RT", "LB", "RB"]
    @info "Running patch $patch"
    s_out, f_out = patch_PSF_weiner_reconstruction_ccp(patch)
    serialize("data/spatial_weiner_reconstruction_$(patch)_ccp.ser", s_out)
    serialize("data/fourier_weiner_reconstruction_$(patch)_ccp.ser", f_out)
    # patch_reconstructions[patch] = (s_out, f_out)
end


## CCP_2

modulations_ccp2 = collect(partition(repeat(IP_params_ccp2[:modulations], inner=3), 3))
phase_offsets_ccp2 = map(IP_params_ccp2[:phase_offsets]) do ϕ
    ([0, 2π / 3, 4π / 3] .+ ϕ) .% 2π
end
shifts_ccp2 = IP_params_ccp2[:shifts]

imgs_ccp2 = map(LR_ccp2) do img
    float64.(gray.(img))
end

s_out_model_ccp2, f_out_model_ccp2 = weiner_reconstruction(imgs_ccp2, shifts_ccp2, phase_offsets_ccp2, modulations_ccp2, otf_model)
serialize("data/spatial_weiner_reconstruction_model_ccp2.ser", s_out_model_ccp2)
serialize("data/fourier_weiner_reconstruction_model_ccp2.ser", f_out_model_ccp2)

patch_PSF_weiner_reconstruction_ccp2(patch) = weiner_reconstruction(imgs_ccp2, shifts_ccp2, phase_offsets_ccp2, modulations_ccp2, MeasuredPSF(get_psf_averaged_estimate(patch)[:psf], 61u"nm"))

for patch in ["CC", "LT", "RT", "LB", "RB"]
    @info "Running patch $patch"
    s_out, f_out = patch_PSF_weiner_reconstruction_ccp2(patch)
    serialize("data/spatial_weiner_reconstruction_$(patch)_ccp2.ser", s_out)
    serialize("data/fourier_weiner_reconstruction_$(patch)_ccp2.ser", f_out)
    # patch_reconstructions[patch] = (s_out, f_out)
end


## CCP_3

modulations_ccp3 = collect(partition(repeat(IP_params_ccp3[:modulations], inner=3), 3))
phase_offsets_ccp3 = map(IP_params_ccp3[:phase_offsets]) do ϕ
    ([0, 2π / 3, 4π / 3] .+ ϕ) .% 2π
end
shifts_ccp3 = IP_params_ccp3[:shifts]

imgs_ccp3 = map(LR_ccp3) do img
    float64.(gray.(img))
end

s_out_model_ccp3, f_out_model_ccp3 = weiner_reconstruction(imgs_ccp3, shifts_ccp3, phase_offsets_ccp3, modulations_ccp3, otf_model)

serialize("data/spatial_weiner_reconstruction_model_ccp3.ser", s_out_model_ccp3)
serialize("data/fourier_weiner_reconstruction_model_ccp3.ser", f_out_model_ccp3)

using TransferFunctions: Cosine, apodize
using Interpolations

apo_width = 70
apo = Cosine(1)

f_out_model_ccp3 = apodize(apo, f_out_model_ccp3, 240 + apo_width, apo_width)
s_out_model_ccp3 = ifft(f_out_model_ccp3)

serialize("data/spatial_weiner_reconstruction_model_ccp3_apo.ser", s_out_model_ccp3)
serialize("data/fourier_weiner_reconstruction_model_ccp3_apo.ser", f_out_model_ccp3)

patch_PSF_weiner_reconstruction_ccp3(patch) = weiner_reconstruction(imgs_ccp3, shifts_ccp3, phase_offsets_ccp3, modulations_ccp3, MeasuredPSF(get_psf_averaged_estimate(patch)[:psf], 61u"nm"))

for patch in ["CC", "LT", "RT", "LB", "RB"]
    @info "Running patch $patch"
    s_out, f_out = patch_PSF_weiner_reconstruction_ccp3(patch)
    serialize("data/spatial_weiner_reconstruction_$(patch)_ccp3.ser", s_out)
    serialize("data/fourier_weiner_reconstruction_$(patch)_ccp3.ser", f_out)
    f_out = apodize(apo, f_out, 240 + apo_width, apo_width)
    s_out = ifft(f_out)
    serialize("data/spatial_weiner_reconstruction_$(patch)_ccp3_apo.ser", s_out)
    serialize("data/fourier_weiner_reconstruction_$(patch)_ccp3_apo.ser", f_out)
    # patch_reconstructions[patch] = (s_out, f_out)
end
