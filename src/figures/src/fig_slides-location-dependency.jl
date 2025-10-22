include("init.jl")
using Interpolations

const FIG_NAME = getbase(@__FILE__)

patch_reconstructions = Dict()
for patch in ["CC", "LT", "RT", "LB", "RB"]
    s_out = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/spatial_weiner_reconstruction_$(patch).ser"))
    f_out = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/fourier_weiner_reconstruction_$(patch).ser"))
    patch_reconstructions[patch] = (s_out, f_out)
end

function fig_all_selected_beads()
    line_vargs = (; linewidth=1, color=:yellow, linestyle=:dash, alpha=0.5)
    function beads_box(ax, patch)
        (xmin, xmax), (ymin, ymax) = extrema.(patch_inds(patch))
        lines!(ax, [xmin, xmin, xmax, xmax, xmin], [ymin, ymax, ymax, ymin, ymin]; line_vargs...)
    end
    points = []
    for p in ["CC", "LT", "RT", "LB", "RB"]
        _, selection_point2f = get_selected_beads(p)
        append!(points, selection_point2f)
    end

    fig = Makie.Figure()
    ax = Makie.Axis(fig[1, 1])


    image!(ax, imresize(LR_beads_sum, (1024, 1024), method=Constant()))
    for p in ["CC", "LT", "RT", "LB", "RB"]
        beads_box(ax, p)
    end
    scatter!(ax, map(point -> 2 .* point .- (1.0, 1.0), points); marker=:circle, markerspace=:data, markersize=15, color=COLORS[1])

    fig
end

savefig(fig_all_selected_beads, FIG_NAME * "-all-beads"; hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(NO_TICKS, NO_TICKLABELS, DATA_ASPECT, NO_SPINE))

function fig_CC_vs_LB()
    fig = Figure()
    ax_lb, ax_cc = Makie.Axis(fig[1, 1], title=L"h_\text{LB}"), Makie.Axis(fig[1, 2], title=L"h_\text{CC}")
    linkaxes!(ax_lb, ax_cc)

    psf_cc = get_psf_averaged_estimate("CC")[:psf]
    psf_lb = get_psf_averaged_estimate("LB")[:psf]

    image!(ax_lb, psf_lb)
    image!(ax_cc, psf_cc)
    return fig
end

savefig(fig_CC_vs_LB, FIG_NAME * "-cc-vs-lb"; hwratio=4 / 7, skip=[:eps, :margin], override_theme=merge(NO_SPINE, DATA_ASPECT, NO_TICKS, NO_TICKLABELS))

function fig_compare_spatial()
    fig = Figure()
    s_cc = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/spatial_weiner_reconstruction_CC.ser"))
    s_lb = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/spatial_weiner_reconstruction_LB.ser"))

    line_vargs = (; linewidth=1, color=:yellow, linestyle=:dash, alpha=0.5)
    function beads_box(ax, patch)
        (xmin, xmax), (ymin, ymax) = extrema.(patch_inds(patch))
        lines!(ax, [xmin, xmin, xmax, xmax, xmin], [ymin, ymax, ymax, ymin, ymin]; line_vargs...)
    end
    ax_lb, ax_cc = Makie.Axis(fig[1, 1], title=L"\hat{s}_\text{LB}"), Makie.Axis(fig[1, 2], title=L"\hat{s}_\text{CC}")
    linkaxes!(ax_cc, ax_lb)

    image!(ax_cc, real(s_cc))
    image!(ax_lb, real(s_lb))
    # beads_box(ax_lb, "LB")

    lims = ((160, 225), (160, 225))
    limits!(ax_cc, lims...)
    ax_cc.xticks, ax_cc.yticks = ax_lb.xticks, ax_lb.yticks = tick_locations(lims, 0.1)

    ax_cc.xticklabelsvisible = ax_cc.yticklabelsvisible = ax_lb.xticklabelsvisible = ax_lb.yticklabelsvisible = true

    fig
end
savefig(fig_compare_spatial, FIG_NAME * "-reconsruction-spatial"; hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT), update=true)

