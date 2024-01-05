SKIP_PREPARE_IMAGES = true
include("init.jl")
const FIG_NAME = getbase(@__FILE__)

otf_model = IdealOTFwithCurvature(488u"nm", 1.4, 1.0, 0.9)

function fig_otf_model()
    fig = Figure()
    ax = Makie.Axis(fig[1, 1])
    A = otf(otf_model, 512, LR_beads_Δxy)
    image!(ax, fftshift(A))
    fig
end

savefig(fig_otf_model, FIG_NAME, hwratio=1, skip=[:vector, :full, :eps], override_theme=merge(DATA_ASPECT, NO_TICKS, NO_SPINE, NO_TICKLABELS))

function fig_otf_model_3D(func=surface!, step=3)
    A = otf(otf_model, 512, LR_beads_Δxy)
    A = fftshift(A)[begin:step:end, begin:step:end]
    fig = Figure()
    ax = Makie.Axis3(fig[1, 1])
    ax.xticksvisible = ax.yticksvisible = ax.xticklabelsvisible = ax.yticklabelsvisible = false
    ax.zticks = ([0, 0.5, 1], [L"0", L"1/2", L"1"])
    ax.xlabelvisible = ax.ylabelvisible = ax.zlabelvisible = false

    func(ax, Base.OneTo(size(A, 1)), Base.OneTo(size(A, 2)), A)
    fig
end

with_theme(merge(Theme(Axis3=(; protrusions=(14, 0, 0, 0))), MARGIN_THEME(HWRATIO), RASTER_THEME, CAIRO_THEME, BASE_THEME)) do
    @info "Building figure at otf-model-surf_margin.png"
    fig = fig_otf_model_3D(surface!, 1)
    save(joinpath(abspath(dirname(@__FILE__)), "../otf-model-surf_margin.png"), fig; backend=CairoMakie, pt_per_unit=1, px_per_unit=20)
end
