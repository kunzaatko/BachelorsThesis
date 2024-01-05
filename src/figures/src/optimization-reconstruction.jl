include("init.jl")
using Interpolations, IterTools, Tullio, ProgressMeter
using TransferFunctions: taperedges, Cosine

# FIX: Adam uses m*... and I use m/2*... (for this multiply by 2?) <13-12-23> 
# modulations = collect(partition(repeat(2IP_params[:modulations], inner=3), 3))
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

OTF_model = otf(IdealOTFwithCurvature(488u"nm", 1.4, 1.0, 0.9), 1024, 30.5u"nm")
# OTF_model_stack = stack(OTF_model for _ in Base.OneTo(9))

# NOTE: Using Center bead estimate  
OTF_measured = otf(MeasuredPSF(get_psf_averaged_estimate("CC")[:psf], 61u"nm"), 1024, 30.5u"nm")
# OTF_measured_stack = stack(OTF_measured for _ in Base.OneTo(9))

LR_imgs = map(LR_beads) do img
    float64.(gray.(img)) |> transpose
end
LR_stack_resized = map(LR_imgs) do img
    imresize(img, 1024, 1024, method=Constant())
end |> stack
LR_stack_resized = taperedges(Cosine(1), LR_stack_resized, 15, (1, 2))
LR_forward_norm_sums = sum(LR_stack_resized; dims=(1, 2))

"""
Takes an `HR_img` and produces the corresponding `LR_stack_resized`
"""
function forward_model(HR_img)::Array{Float64,3}
    @tullio HR_stack_I[x, y, z] := HR_img[x, y] * HR_I[x, y, z]
    f_HR_stack = fft(HR_stack_I, (1, 2))
    f_LR_stack = f_HR_stack .* OTF_model
    LR_stack = ifft(f_LR_stack, (1, 2))
    LR_stack_real = real(LR_stack)
    LR_stack_normed = LR_stack_real .* (LR_forward_norm_sums ./ sum(LR_stack_real; dims=(1, 2)))
    return LR_stack_normed
end

function forward_measured(HR_img)::Array{Float64,3}
    @tullio HR_stack_I[x, y, z] := HR_img[x, y] * HR_I[x, y, z]
    f_HR_stack = fft(HR_stack_I, (1, 2))
    f_LR_stack = f_HR_stack .* OTF_measured
    LR_stack = ifft(f_LR_stack, (1, 2))
    LR_stack_real = real(LR_stack)
    LR_stack_normed = LR_stack_real .* (LR_forward_norm_sums ./ sum(LR_stack_real; dims=(1, 2)))
    return LR_stack_normed
end

# rec0 = imresize(LR_beads_sum, 1024, 1024, method = Constant()) .|> gray .|> float64 # initial guess
# FIX: Wiener deconvolution gives a transposed result?! <13-12-23> 
rec0 = deserialize("data/spatial_weiner_reconstruction_model.ser") |> real

iterations = 10
λ = 0.05
loss = Poisson()

regularizer_tv = TV()
if !isfile("data/tv_reconstruction_model.ser")
    @info "Running TV reconstruction model"
    s_out_model_tv, _ = invert(LR_stack_resized, rec0, forward_model; regularizer=regularizer_tv, loss, λ, iterations)
    serialize("data/tv_reconstruction_model.ser", s_out_model_tv)
else
    @info "Skipping TV reconstruction model"
end

if !isfile("data/tv_reconstruction_measured.ser")
    @info "Running TV reconstruction measured"
    s_out_measured_tv, _ = invert(LR_stack_resized, rec0, forward_measured; regularizer=regularizer_tv, loss, λ, iterations)
    serialize("data/tv_reconstruction_measured.ser", s_out_measured_tv)
else
    @info "Skipping TV reconstruction measured"
end

if !isfile("data/tv_reconstructions_model_lambda.ser")
    @info "Running TV reconstructions for λ in 0.01:0.02:0.2 model"
    λ_reconstructions_model_tv = Dict()
    @showprogress for λ in 0.01:0.02:0.2
        s_out, _ = invert(LR_stack_resized, rec0, forward_model; regularizer=regularizer_tv, loss, λ, iterations)
        λ_reconstructions_model_tv[λ] = s_out
    end
    serialize("data/tv_reconstructions_model_lambda.ser", λ_reconstructions_model_tv)
else
    @info "Skipping TV reconstructions for λ in 0.01:0.02:0.2 model"
end

if !isfile("data/tv_reconstructions_measured_lambda.ser")
    @info "Running TV reconstructions for λ in 0.01:0.02:0.2 measured"
    λ_reconstructions_measured_tv = Dict()
    @showprogress for λ in 0.01:0.02:0.2
        s_out, _ = invert(LR_stack_resized, rec0, forward_measured; regularizer=regularizer_tv, loss, λ, iterations)
        λ_reconstructions_measured_tv[λ] = s_out
    end
    serialize("data/tv_reconstructions_measured_lambda.ser", λ_reconstructions_model_tv)
else
    @info "Skipping TV reconstructions for λ in 0.01:0.02:0.2 measured"
end

regularizer_gr = GR()
if !isfile("data/gr_reconstruction_model.ser")
    @info "Running GR reconstruction model"
    s_out_model_gr, _ = invert(LR_stack_resized, rec0, forward_model; regularizer=regularizer_gr, loss, λ, iterations)
    serialize("data/gr_reconstruction_model.ser", s_out_model_gr)
else
    @info "Skipping GR reconstruction model"
end

if !isfile("data/gr_reconstruction_measured.ser")
    @info "Running GR reconstruction measured"
    s_out_measured_gr, _ = invert(LR_stack_resized, rec0, forward_measured; regularizer=regularizer_gr, loss, λ, iterations)
    serialize("data/gr_reconstruction_measured.ser", s_out_measured_gr)
else
    @info "Skipping GR reconstruction measured"
end

if !isfile("data/gr_reconstructions_model_lambda.ser")
    @info "Running GR reconstructions for λ in 0.01:0.02:0.2 model"
    λ_reconstructions_model_gr = Dict()
    @showprogress for λ in 0.01:0.02:0.2
        s_out, _ = invert(LR_stack_resized, rec0, forward_model; regularizer=regularizer_gr, loss, λ, iterations)
        λ_reconstructions_model_gr[λ] = s_out
    end
    serialize("data/gr_reconstructions_model_lambda.ser", λ_reconstructions_model_gr)
else
    @info "Skipping GR reconstructions for λ in 0.01:0.02:0.2 model"
end

if !isfile("data/gr_reconstructions_measured_lambda.ser")
    @info "Running GR reconstructions for λ in 0.01:0.02:0.2 measured"
    λ_reconstructions_measured_gr = Dict()
    @showprogress for λ in 0.01:0.02:0.2
        s_out, _ = invert(LR_stack_resized, rec0, forward_measured; regularizer=regularizer_gr, loss, λ, iterations)
        λ_reconstructions_measured_gr[λ] = s_out
    end
    serialize("data/gr_reconstructions_measured_lambda.ser", λ_reconstructions_measured_gr)
else
    @info "Skipping GR reconstructions for λ in 0.01:0.02:0.2 measured"
end

HR_I_3 = HR_I[:, :, 1:3:9]
LR_forward_norm_sums_3 = LR_forward_norm_sums[:, :, 1:3:9]

function forward_model_3(HR_img)::Array{Float64,3}
    @tullio HR_stack_I[x, y, z] := HR_img[x, y] * HR_I_3[x, y, z]
    f_HR_stack = fft(HR_stack_I, (1, 2))
    f_LR_stack = f_HR_stack .* OTF_model
    LR_stack = ifft(f_LR_stack, (1, 2))
    LR_stack_real = real(LR_stack)
    LR_stack_normed = LR_stack_real .* (LR_forward_norm_sums_3 ./ sum(LR_stack_real; dims=(1, 2)))
    return LR_stack_normed
end

LR_stack_resized_3 = LR_stack_resized[:, :, 1:3:9]

if !isfile("data/tv_reconstruction_model_3.ser")
    @info "Running TV reconstruction model 3 images"
    s_out_model_tv, _ = invert(LR_stack_resized_3, rec0, forward_model_3; regularizer=regularizer_tv, loss, λ, iterations=20)
    serialize("data/tv_reconstruction_model_3.ser", s_out_model_tv)
else
    @info "Skipping TV reconstruction model 3 images"
end

if !isfile("data/gr_reconstruction_model_3.ser")
    @info "Running GR reconstruction model 3 images"
    s_out_model_gr, _ = invert(LR_stack_resized_3, rec0, forward_model_3; regularizer=regularizer_gr, loss, λ, iterations=20)
    serialize("data/gr_reconstruction_model_3.ser", s_out_model_gr)
else
    @info "Skipping GR reconstruction model 3 images"
end
