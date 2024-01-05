include("init.jl")
@info "Generating HR beads model..."
using Unitful: Quantity, 𝐋
using IterTools, ImageFiltering, OffsetArrays, Interpolations, StatsBase, Optim, Zygote, ImageMorphology, ProgressMeter, DataFrames, PaddedViews
using ImageFiltering: Fill
using Distributed
using ImageFiltering: mapwindow
using TransferFunctions: taperedges, Cosine

const PerLength = Quantity{<:Any,inv(𝐋)}

# TODO: bead should have δ in the arguments for the model generation <14-12-23> 
"""
    bead([T=Float64], d::Length, α::PerLength, (Δxy::Length,Δxy::Length))
    bead(d, α, Δxy::Length)

Generate a model of a bead

## Arguments
- `α::PerLength`: evanescent wave attenuation constant
- `pixel_grid_length::Int = 100`: length of each pixel in the grid
- `peak_intensity = 1.0`: peak intensity value

"""
function bead(T::Type{<:Real}, d::Length, α::PerLength, Δxy::NTuple{2,Length}; pixel_grid_length=100, peak_intensity=one(T), subpixel_shift=(0, 0))::OffsetMatrix{T}
    half_wh_px = d ./ (2 .* Δxy) .+ 1 .|> ceil # ½ width-height in pixels +1 for sub-pixel shift
    wh_px_g = (2 .* half_wh_px .+ 1) .* pixel_grid_length .|> Int # ½ width-height in grid, +1 for center
    grid = Matrix{T}(undef, wh_px_g)
    grid_subpixel_shift = subpixel_shift .* pixel_grid_length
    grid_center = wh_px_g ./ 2 .+ 1 / 2 .+ grid_subpixel_shift
    r_grid = map(CartesianIndices(grid)) do xy
        (Tuple(xy) .- grid_center) ./ pixel_grid_length .* Δxy |> splat(hypot)
    end # radii from the center
    supp_grid = r_grid .< (d / 2) # support of the bead
    z_grid = similar(r_grid, Union{Missing,Length}) # z-axes offset from the focal plane
    z_grid[supp_grid.==0] .= missing
    z_grid[supp_grid] .= (d / 2) .- sqrt.((d / 2)^2 .- r_grid[supp_grid] .^ 2)
    intensity_grid = map(z_grid) do z
        ismissing(z) ? zero(T) : exp(-α * z)
    end
    buf = Matrix{T}(undef, Int.(2 .* half_wh_px .+ 1))
    map!(buf, CartesianIndices(buf)) do ind
        indsx, indsy = map(Tuple(ind)) do i
            ((i-1)*pixel_grid_length+1):(i*pixel_grid_length)
        end
        mean(intensity_grid[indsx, indsy])
    end
    buf = OffsetArray(buf, -1 .* (half_wh_px .+ 1) .|> Int)
    buf .*= peak_intensity / buf[0, 0]
    return buf
end
bead(d::Length, α::PerLength, Δxy::NTuple{2,Length}; vargs...) = bead(Float64, d, α, Δxy; vargs...)
bead(T::Type{<:Real}, d::Length, α::PerLength, Δxy::Length; vargs...) = bead(T, d, α, (Δxy, Δxy); vargs...)
bead(d::Length, α::PerLength, Δxy; vargs...) = bead(Float64, d, α, Δxy; vargs...)

@info "Finding approximate bead centers using cross-correlation and intensity filtering..."
HR_img = deserialize("data/spatial_weiner_reconstruction_CC.ser") |> real
taperedges(Cosine(1), HR_img, 20)
HR_bead = bead(100u"nm", 1 / 400u"nm", HR_beads_Δxy; pixel_grid_length=300, peak_intensity=0.5)
LR_bead = bead(100u"nm", 1 / 400u"nm", LR_beads_Δxy; pixel_grid_length=300, peak_intensity=0.5)
serialize("data/HR_bead.ser", HR_bead)
serialize("data/LR_bead.ser", LR_bead)

ccorr_num = imfilter(Float64, HR_img, HR_bead, Algorithm.FIR())
q = sqrt.(imfilter(Float64, HR_img .^ 2, centered(ones(size(HR_bead))), Algorithm.FIR()))
m = sqrt(sum(HR_bead .^ 2))
ccorr = ccorr_num ./ (m * max.(eps(), q))
serialize("data/ccorr.ser", ccorr)

local_mean_wide = mapwindow(mean, HR_img, (201, 201), border="replicate", indices=(1:10:size(HR_img, 1), 1:10:size(HR_img, 2)))
local_mean_wide = imresize(local_mean_wide, 1024, 1024, method=BSpline(Cubic()))

local_mean_narrow = mapwindow(mean, HR_img, (15, 15), border="replicate", indices=(1:3:size(HR_img, 1), 1:3:size(HR_img, 2)))
local_mean_narrow = imresize(local_mean_narrow, 1024, 1024, method=BSpline(Cubic()))

# const α_BEST = 0.74
# const RI_wide_BEST = 4.78
# const RI_narrow_BEST = 2.53

# const α_BEST = 0.6
# const α_BEST = 0.67
const α_BEST = 0.62
const RI_wide_BEST = 7.0
const RI_narrow_BEST = 1.46

function fig_ccorr_thresh()
    fig = Figure()
    ax = [Makie.Axis(fig[1, i]) for i in 1:2]
    linkaxes!(ax...)
    DataInspector(fig)
    sl = SliderGrid(fig[2, 1:2],
        (label=L"α", range=0.4:0.01:1, startvalue=α_BEST),
        (label=L"RI_{\text{wide}}", range=0.0:0.01:7, startvalue=RI_wide_BEST),
        (label=L"RI_{\text{narrow}}", range=0.0:0.01:15, startvalue=RI_narrow_BEST),
    )
    α = sl.sliders[1].value
    RI_wide = sl.sliders[2].value
    RI_narrow = sl.sliders[3].value
    ax[1].title = "CCORR > α"
    seled = @lift(ccorr .* (ccorr .> $α) .* (HR_img .> ((1 + $RI_wide) .* local_mean_wide)) .* (HR_img .> ((1 .+ $RI_narrow) .* local_mean_narrow)))
    image!(ax[1], seled)
    ax[2].title = "BEADS"
    image!(ax[2], HR_img)
    fig, α, RI_wide, RI_narrow
end

serialize("data/ccorr-thresh.ser", ccorr .> α_BEST)
serialize("data/wide-thresh.ser", HR_img .> ((1 .+ RI_wide_BEST) .* local_mean_wide))
serialize("data/narrow-thresh.ser", HR_img .> ((1 .+ RI_narrow_BEST) .* local_mean_narrow))

seled = @. ccorr * (ccorr > α_BEST) * (HR_img > ((1 + RI_wide_BEST) * local_mean_wide)) * (HR_img > ((1 + RI_narrow_BEST) * local_mean_narrow))

function gaussian_model(size, μ)
    xs, ys = (1:size[1]) * ones(size[2])' .- μ[1], ones(size[1]) * (1:size[2])' .- μ[2]
    return (I_0, I, Δx, Δy, σ²) -> @. I_0 + I * exp(-((xs - Δx)^2 + (ys - Δy)^2) / 2σ²)
end

function loss(data, μ)
    model = gaussian_model(size(data), μ)
    p -> sum(abs, data .- model(p...))
end

function gradient(f, args...)
    y, back = pullback(f, args...)
    grad = back(Zygote.sensitivity(y))
    isnothing(grad) ? nothing : map(Zygote._project, args, grad)
end

function fig_gauss_bead_params()
    fig = Figure()
    top_gl = fig[1, 1] = GridLayout()
    sl = SliderGrid(fig[2, 1], (label="σ²", range=0.1:0.01:3, startvalue=0.5))
    σ² = sl.sliders[1].value
    ax_bead, _ = image(top_gl[2, 1], HR_bead.parent)
    ax_bead.title = "Bead"
    gauss_model = gaussian_model(size(HR_bead), size(HR_bead) .÷ 2 .+ 1)
    gauss = @lift(gauss_model(0, HR_bead[0, 0], 0, 0, $σ²))
    ax_gauss, _ = image(top_gl[2, 2], gauss)
    ax_gauss.title = "Gauss"
    ax_diff, _ = image(top_gl[1, :], @lift(HR_bead.parent .- $gauss); colorrange=(-maximum(HR_bead.parent), maximum(HR_bead.parent)))
    ax_diff.title = "Diff"
    linkaxes!(ax_bead, ax_gauss, ax_diff)
    DataInspector(fig)
    return fig
end

# fit(HR_bead.parent, size(HR_bead) .÷ 2 .+ 1, 1, 3)

const σ²_MAX = 2 # NOTE: It must be large for the corner beads to fit  
const σ²_MIN = 0.3 # NOTE: It must be very small to fit the artefacts that we want to filter  
const σ²_0 = 0.8299242005542043 # estimate by fitting HR_bead

function fit(data, μ, Δμ_max, σ²_0=σ²_0, σ²_box=[σ²_MIN, σ²_MAX], I_0=data[round.(Int, μ)...]; optimizer=GradientDescent())
    p_0 = [0.01, I_0, 0, 0, σ²_0]
    p_lower = [0, 0, -Δμ_max, -Δμ_max, σ²_box[1]]
    p_upper = [Inf, Inf, Δμ_max, Δμ_max, σ²_box[2]]
    f = loss(data, μ)
    g!(G, vec) = G .= gradient(f, vec)[1]
    optim_res = Optim.optimize(f, g!, p_lower, p_upper, p_0, Fminbox(optimizer))
    optim_res
end

bead_labels = label_components(seled .> 0)
bead_centers = component_centroids(bead_labels)[2:end]

function fig_found_beads()
    fig, ax, _ = image(HR_img)
    # NOTE: -1/2 because of the misalignment of pixels when plotting in Makie
    scatter!(ax, getindex.(bead_centers, 1) .- 1 / 2, getindex.(bead_centers, 2) .- 1 / 2, alpha=0.4, markerspace=:data, markersize=7)
    fig
end

const SKIP_GUASS_FIT = true
# const SKIP_GUASS_FIT = false
local gauss_fits, beads_fit_data, bead_optim_fits, bead_fits, beads_not_converged, beads_converged

# NOTE: this takes quite a while (approx. 20mins), so only update it on demand. It gets de-serialized otherwise <14-12-23> 
if !(isdefined(@__MODULE__, :SKIP_GUASS_FIT) && SKIP_GUASS_FIT)
    @info "Finding exact bead centers using a Gaussian fit..."
    beads_fit_data = []
    bead_optim_fits = []
    bead_fits = []
    beads_not_converged = []
    @showprogress for (ind, c) in enumerate(bead_centers)
        inds = map([(-7:7) .+ round(Int, c_i) for c_i in c]) do xys
            xys_12 = max(first(xys), 1), min(last(xys), size(HR_img, 1))
            xys_12[1]:xys_12[2]
        end
        fit_μ = c .- first.(inds) .+ 1
        # NOTE: .-local_mean_wide should help the fit, because data should be background subtracted, i.e. reference value should be zero.
        fit_data = (HR_img.-local_mean_wide)[inds...]
        push!(beads_fit_data, (fit_data, fit_μ, inds,))
        gauss_fit = fit(fit_data, fit_μ, 3) # 3 === Δμ_max
        if !Optim.x_converged(gauss_fit)
            print("\n")
            @warn "Fit did not converge on bead $ind"
            push!(beads_not_converged, ind)
        end
        fit_minimizer = Optim.minimizer(gauss_fit)
        final_params = Dict(
            :I_0 => fit_minimizer[1],
            :I => fit_minimizer[2],
            :μ => c .+ fit_minimizer[3:4],
            :μ_rel => fit_μ .+ fit_minimizer[3:4],
            :Δμ => fit_minimizer[3:4],
            :σ² => fit_minimizer[5],
        )
        push!(bead_fits, final_params)
        push!(bead_optim_fits, gauss_fit)
    end

    beads_converged = fill(true, length(bead_fits))
    beads_converged[beads_not_converged] .= false

    gauss_fits = Dict(
        :data => beads_fit_data,
        :optim => bead_optim_fits,
        :fit => bead_fits,
        :converged => beads_converged,
    )
    serialize("data/gauss_fits_to_beads.ser", gauss_fits)
else
    @info "Loading previously computed fits..."
    gauss_fits = deserialize("data/gauss_fits_to_beads.ser")
    beads_fit_data = gauss_fits[:data]
    bead_optim_fits = gauss_fits[:optim]
    bead_fits = gauss_fits[:fit]
    beads_converged = gauss_fits[:converged]
end

function fig_beads_fit_data(ind)
    data = beads_fit_data[ind][1]
    fig, ax, _ = image(data)
    scatter!(beads_fit_data[ind][2]...)
    ax.xticks = (axes(data, 1), beads_fit_data[ind][3][1] .|> string)
    ax.yticks = (axes(data, 2), beads_fit_data[ind][3][2] .|> string)
    fig
end

bead_fits_df = map(bead_fits) do bf
    DataFrame(
        :I_0 => bf[:I_0],
        :I => bf[:I],
        :μ => Tuple(bf[:μ]),
        :μ_rel => Tuple(bf[:μ_rel]),
        :Δμ => Tuple(bf[:Δμ]),
        :σ² => bf[:σ²],
    )
end |> splat(vcat)
bead_fits_df[!, :converged] = beads_converged


function fig_beads_fits(; selected=1:nrow(bead_fits_df))
    bead_fits_df_s = bead_fits_df[selected, :]
    beads_fit_data_s = beads_fit_data[selected]
    bead_centers_s = bead_centers[selected]
    # beads_converged_s = beads_converged[selected]
    filtered = fill(false, length(beads_converged))
    filtered[selected] .= true

    fig = Figure()
    ax = [Makie.Axis(fig[1, i]) for i in 1:3]
    ax[1].title = "Convered"
    ax[2].title = "Filtered"
    ax[3].title = "Fit sum"
    linkaxes!(ax...)
    image!(ax[1], HR_img)
    scatter!(ax[1], getindex.(bead_fits_df[!, :μ], 1) .- 1 / 2, getindex.(bead_fits_df[!, :μ], 2) .- 1 / 2;
        markersize=7,
        # markerspace=:data,
        color=map(c -> c ? :green : :red, beads_converged),
        # marker=map(c -> c ? :circle : :cross, filtered),
        alpha=0.6
        # alpha=0.1
    )
    image!(ax[2], HR_img)
    scatter!(ax[2], getindex.(bead_fits_df[!, :μ], 1) .- 1 / 2, getindex.(bead_fits_df[!, :μ], 2) .- 1 / 2;
        markersize=7,
        # markerspace=:data,
        color=map(c -> c ? :green : :red, filtered),
        # marker=map(c -> c ? :circle : :cross, filtered),
        alpha=0.6
        # alpha=0.1
    )
    fit_buf = zeros(size(HR_img))
    for (inds, fit, c) in zip(map(x -> x[3], beads_fit_data_s), eachrow(bead_fits_df_s), bead_centers_s)
        gauss = gaussian_model(length.(inds), fit[:μ_rel])
        fit_buf[inds...] .+= gauss(fit[:I_0], fit[:I], (fit[:μ] .- c)..., fit[:σ²])
    end
    image!(ax[3], fit_buf; inspectable=false)
    scatter!(ax[3], getindex.(bead_fits_df_s[!, :μ], 1) .- 1 / 2, getindex.(bead_fits_df_s[!, :μ], 2) .- 1 / 2;
        alpha=0.01,
        markersize=7,
        markerspace=:data,
        inspector_label=(_, ind, _) -> "I₀: $(bead_fits_df_s[ind, :I_0])\nI: $(bead_fits_df_s[ind, :I])\nσ²: $(bead_fits_df_s[ind, :σ²])\nΔμ: $(bead_fits_df_s[ind, :Δμ])"
    )
    # filtered 
    bead_fits_df_f = bead_fits_df[setdiff(1:nrow(bead_fits_df), selected), :]
    bead_centers_f = bead_centers[setdiff(1:nrow(bead_fits_df), selected)]
    scatter!(ax[3],
        getindex.(bead_fits_df_f[!, :μ], 1) .- 1 / 2,
        getindex.(bead_fits_df_f[!, :μ], 2) .- 1 / 2;
        color=:red,
        alpha=0.4,
        markersize=7,
        # markerspace=:data,
        # inspectable=false,
        inspector_label=(_, ind, _) -> "I₀: $(bead_fits_df_f[ind, :I_0])\nI: $(bead_fits_df_f[ind, :I])\nσ²: $(bead_fits_df_f[ind, :σ²])\nΔμ: $(bead_fits_df_f[ind, :Δμ])"
    )
    DataInspector(fig)
    fig
end


@info "Filtering artefacts that were assumed beads..."
# Filtering the artefacts
const BEAD_SUROUNDING_SIZE = 10
const MIN_INTENSITY_RATIO = 0.7
const MIN_SIGMA_RATIO = 0.8
const ARTEFACTS_SHIFT_APPROX = [(-3, 5), (3, 5), (5, -1), (-6, 4), (1, -3)]
const ARTEFACT_SHIFT_ERROR = 2

filter_inds = []
ind_bead_fits = collect(enumerate(bead_fits))
for bead_fit in sort(bead_fits; by=bf -> bf[:I], rev=true)
    # NOTE: Taking the beads sorted by intensity to get the true beats before the artifacts during filtering
    surrounding_fits = filter(ind_bead_fits) do ind_bf
        ind, bf = ind_bf
        hypot((bf[:μ] .- bead_fit[:μ])...) < BEAD_SUROUNDING_SIZE
    end
    # deleteat!(surrounding_fits, findfirst(==(bead_fit), surrounding_fits))
    ref_I = bead_fit[:I]
    ref_μ = bead_fit[:μ]
    ref_σ² = bead_fit[:σ²]
    for (ind, fit) in surrounding_fits
        # if (fit[:I] / ref_I) < MIN_INTENSITY_RATIO || (fit[:σ²] / ref_σ²) < MIN_SIGMA_RATIO
        #     push!(filter_inds, ind)
        # end

        for arteract_shift in ARTEFACTS_SHIFT_APPROX
            if all(isapprox.(fit[:μ] .- ref_μ, arteract_shift; atol=ARTEFACT_SHIFT_ERROR)) && (fit[:I] / ref_I) < MIN_INTENSITY_RATIO
                push!(filter_inds, ind)
            end
        end
    end
end

@info "Generating HR image model of beads from estimated locations..."
bead_fits_selected = bead_fits[setdiff(1:nrow(bead_fits_df), filter_inds)]
HR_model = padarray(zeros(size(HR_img)), Fill(0, (7, 7)))
@showprogress desc = "Adding individual beads" for fit in bead_fits_selected
    round_center = floor.(Int, fit[:μ])
    subpixel_shift = fit[:μ] .- round_center
    b = bead(100u"nm", 1 / 400u"nm", 30.5u"nm"; pixel_grid_length=10, peak_intensity=fit[:I], subpixel_shift)
    data_axes = map(axes(HR_model), round_center) do ax, c
        ax .- c
    end |> Tuple
    OffsetArray(HR_model, (-1 .* round_center)...) .+= PaddedView(0, b, data_axes)
end
HR_model = HR_model[1:1024, 1:1024]

function fig_compare_model_and_data()
    fig = Figure()
    ax = [Makie.Axis(fig[1, i]) for i in 1:2]
    linkaxes!(ax...)
    ax[1].title = "Data"
    image!(ax[1], HR_img)
    ax[2].title = "Model"
    image!(ax[2], HR_model)
    fig
end

serialize("data/beads_model.ser", HR_model)

selected = setdiff(1:nrow(bead_fits_df), filter_inds)
gaussian_sum_model_dict = Dict()
gaussian_sum_model_dict[:selected] = selected
gaussian_sum_model_dict[:filtered] = fill(true, length(bead_centers))
gaussian_sum_model_dict[:filtered][selected] .= false
gaussian_sum_model_dict[:bead_fits_df] = bead_fits_df
gaussian_sum_model_dict[:bead_fits_df_s] = bead_fits_df[selected, :]
gaussian_sum_model_dict[:bead_fit_data_s] = beads_fit_data[selected]
gaussian_sum_model_dict[:bead_centers_s] = bead_centers[selected]
gaussian_sum_model_dict[:bead_fits_df_f] = bead_fits_df[setdiff(1:nrow(bead_fits_df), selected), :]

serialize("data/gaussian_sum_model.ser", gaussian_sum_model_dict)
