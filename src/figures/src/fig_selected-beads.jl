# TODO: Finish figure <28-11-23> 
# FIX: Figure should be made only of the center patch and not of the full images <29-11-23> 
include("init.jl")
const FIG_NAME = getbase(@__FILE__)


function fig_selected_beads_patch(patch="CC")
    _, selection_point2f = get_selected_beads(patch)
    inds = patch_inds(patch; imsize=size(LR_beads_sum))
    fig = Makie.Figure()

    # FIX: axis pixel indices and the font <29-11-23> 
    ax = Makie.Axis(fig[1, 1])
    xlims, ylims = extrema.(inds)
    limits!(ax, xlims, ylims)
    xticks, yticks = tick_locations((xlims, ylims), 0.1)
    ax.xticks, ax.yticks = xticks, yticks

    image!(ax, LR_beads_sum)

    # TODO: Add numbers instead of centre marks <28-11-23> 
    # FIX: marks are too large <29-11-23> 
    # TODO: Add numbers to centre <28-11-23> 
    scatter!(ax, map(point -> point .- (0.5, 0.5), selection_point2f); marker=:circle, markerspace=:data, markersize=3, color=COLORS[1])

    return fig
end

savefig(fig_selected_beads_patch, FIG_NAME * "-CC"; hwratio=1, skip=[:vector], override_theme=merge(FORMAT_TICKS, MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT), fig_function_args=("CC",))

# FIX: Seems that the cutouts are already centered... This should be checked and the non-centered cutouts should be
# shown <31-12-23> 
function fig_centered_beads_cutouts(patch="CC", labels=true, centers=true)
    rois = get_psf_averaged_estimate(patch)[:rois]
    px_inds_centers_selected = map(c -> round.(Int, c), get_selected_beads(patch)[1])
    subpx_centers = get_psf_averaged_estimate(patch)[:positions]
    patch_center_offsets = map(px_inds_centers_selected, subpx_centers) do c, p
        p - c
    end
    px_inds_lims = map(c -> (c[1] .+ (-7, 7), c[2] .+ (-7, 7)), px_inds_centers_selected)
    patch_beads_center_locations = map(patch_center_offsets) do o
        o .+ (8, 8) .- (0.5, 0.5)
    end

    fig = Figure()
    axes = [Makie.Axis(fig[i, j]) for i in 1:3, j in 1:4]
    for (ax, b, c, lims) in zip(axes, rois, patch_beads_center_locations, px_inds_lims)
        image!(ax, b)
        if centers
            scatter!(ax, [c], marker=:circle, markersize=3, color=COLORS[1])
        end
        if labels
            xticks_pos, yticks_pos = tick_locations(((1, 15), (1, 15)), 0.1)
            xticks, yticks = tick_locations(lims, 0.1)
            ax.xticks, ax.yticks = (xticks_pos, latexstring.(xticks)), (yticks_pos, latexstring.(yticks))
        end
    end
    DataInspector(fig)
    rowgap!(fig.layout, Makie.Fixed(2))
    colgap!(fig.layout, Makie.Fixed(2))
    fig
end

savefig(fig_centered_beads_cutouts, FIG_NAME * "-patches-CC-noticks", skip=[:vector], override_theme=merge(NO_TICKS, NO_TICKLABELS, NO_SPINE, DATA_ASPECT), fig_function_args=(patch="CC", labels=false))
savefig(fig_centered_beads_cutouts, FIG_NAME * "-patches-CC", skip=[:vector], override_theme=merge(MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT), fig_function_args=(patch="CC", labels=true))
