include("init.jl")
const FIG_NAME = getbase(@__FILE__)
img = LR_beads_sum

psf_model = psf(IdealOTFwithCurvature(488u"nm", 1.4, 1.0, 0.9), 15, 61u"nm").parent |> real

function fig_model_vs_measured(patch="CC", orientation=:vert)
    fig = Figure()

    ax_model, ax_measured = Makie.Axis(fig[1, 1]), Makie.Axis(fig[orientation == :vert ? 2 : 1, orientation == :vert ? 1 : 2])
    linkaxes!(ax_model, ax_measured)

    ax_model.title = L"h_\text{model}"
    ax_measured.title = L"h_\text{avg}"

    psf_measured = get_psf_averaged_estimate(patch)[:psf]

    image!(ax_model, psf_model)
    image!(ax_measured, psf_measured)
    return fig
end

savefig(fig_model_vs_measured, FIG_NAME; hwratio=0.6, skip=[:vector, :margin], override_theme=merge(NO_SPINE, DATA_ASPECT, NO_TICKS, NO_TICKLABELS), fig_function_args=(patch="CC", orientation=:horiz))
savefig(fig_model_vs_measured, FIG_NAME; hwratio=1.9, skip=[:vector, :full], override_theme=merge(NO_SPINE, DATA_ASPECT, NO_TICKS, NO_TICKLABELS))

deconv_model, _ = deconvolution(gray.(img), ifftshift(psf_model); iterations=100)

function fig_model_vs_measured_decon(patch="CC", orientation=:vert)
    fig = Figure()

    psf_measured = get_psf_averaged_estimate(patch)[:psf]
    deconv_measured, _ = deconvolution(gray.(img), ifftshift(psf_measured); iterations=100)
    inds = patch_inds(patch; imsize=size(LR_beads_sum))

    ax_model = Makie.Axis(fig[1, 1], title=L"\hat{s}_\text{model}")
    ax_measured = Makie.Axis(fig[orientation == :vert ? 2 : 1, orientation == :vert ? 1 : 2], title=L"\hat{s}_\text{avg}")
    linkaxes!(ax_model, ax_measured)

    rowgap!(fig.layout, Relative(0.04))
    colgap!(fig.layout, Relative(0.04))

    image!(ax_model, match_hist(deconv_model))
    image!(ax_measured, match_hist(deconv_measured))

    xlims, ylims = extrema.(inds)
    limits!(ax_model, xlims, ylims)
    xticks, yticks = tick_locations((xlims, ylims), 0.1)
    ax_model.xticks = ax_measured.xticks = xticks
    ax_model.yticks = ax_measured.yticks = yticks

    return fig
end

savefig(fig_model_vs_measured_decon, FIG_NAME * "-deconv-CC"; hwratio=1.9, skip=[:vector, :full], override_theme=merge(FORMAT_TICKS, NO_SPINE, DATA_ASPECT, MARGIN_PX_TICKS))
savefig(fig_model_vs_measured_decon, FIG_NAME * "-deconv-CC"; hwratio=0.5, skip=[:vector, :margin], override_theme=merge(FORMAT_TICKS, NO_SPINE, DATA_ASPECT, MARGIN_PX_TICKS), fig_function_args=(patch="CC", orientation=:horiz))


# TODO: Should define a generic method that generates the tick locations that gives some space at the edges of the
# limits and defines ticks over the whole image. This figure function has a basic implementation of how this might 
# work <31-12-23> 

# FIX: The ticks are not working!!! This must be a weird theming problem, because in other figures that are generated
# exactly the same way, they are showing up.. <31-12-23> 

function fig_model_vs_measured_decon_vs_sensed(patch="CC")
    fig = Figure()

    psf_measured = get_psf_averaged_estimate(patch)[:psf]
    deconv_measured, _ = deconvolution(gray.(img), ifftshift(psf_measured); iterations=100)

    # inds = patch_inds(patch; imsize=size(LR_beads_sum))
    inds = (232:265, 242:276) # Closer cut-out that makes the individual beads visible

    ax_model = Makie.Axis(fig[1, 1], title=L"\hat{s}_\text{model}")
    ax_sensed = Makie.Axis(fig[1, 2], title=L"f")
    ax_measured = Makie.Axis(fig[1, 3], title=L"\hat{s}_\text{avg}")
    linkaxes!(ax_model, ax_measured, ax_sensed)

    image!(ax_model, match_hist(deconv_model))
    image!(ax_sensed, match_hist(LR_beads_sum))
    image!(ax_measured, match_hist(deconv_measured))

    xlims, ylims = extrema.(inds)
    xticks, yticks = tick_locations((xlims, ylims), 0.1)
    ax_model.xticks = ax_sensed.xticks = ax_measured.xticks = xticks
    ax_model.yticks = ax_measured.yticks = ax_sensed.yticks = yticks
    limits!(ax_model, xlims, ylims)

    colgap!(fig.layout, Relative(0.04))
    rowgap!(fig.layout, Relative(0.04))

    # DataInspector(fig)
    return fig
end
savefig(fig_model_vs_measured_decon_vs_sensed, FIG_NAME * "-deconv-CC-vs-sensed"; hwratio=0.35, skip=[:vector, :margin], override_theme=merge(MARGIN_PX_TICKS, FORMAT_TICKS, NO_SPINE, DATA_ASPECT), fig_function_args=(patch="CC",))


function fig_model_vs_measured_decon_diff(patch="CC")
    psf_measured = get_psf_averaged_estimate(patch)[:psf]
    deconv_measured, _ = deconvolution(gray.(img), ifftshift(psf_measured); iterations=100)
    inds = patch_inds(patch; imsize=size(LR_beads_sum))

    fig = Figure()
    ax = Makie.Axis(fig[1, 1], title=L"\hat{s}_\text{model} - \hat{s}_\text{avg}")
    plt = heatmap!(ax, deconv_model - deconv_measured, colormap=:Spectral)
    # fig, _, plt = contourf(deconv_model - deconv_measured, colormap=:Spectral)
    cb = Colorbar(fig[1, 2], plt)
    cb.leftspinevisible = cb.rightspinevisible = false
    colgap!(fig.layout, Relative(0.04))

    xlims, ylims = extrema.(inds)
    limits!(ax, xlims, ylims)
    xticks, yticks = tick_locations((xlims, ylims), 0.1)
    ax.xticks, ax.yticks = xticks, yticks
    # ax.xticks = (xticks, latexstring.(xticks))
    # ax.yticks = (yticks, latexstring.(yticks))
    # DataInspector(fig)
    return fig
end
savefig(fig_model_vs_measured_decon_diff, FIG_NAME * "-deconv-diff-CC"; hwratio=0.6, skip=[:vector, :full], override_theme=merge(MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT))

function fig_model_vs_measured_decon_and_diff(patch="CC")
    psf_measured = get_psf_averaged_estimate(patch)[:psf]
    deconv_measured, _ = deconvolution(gray.(img), ifftshift(psf_measured); iterations=100)
    inds = patch_inds(patch; imsize=size(LR_beads_sum))

    fig = Figure()

    ax_model = Makie.Axis(fig[1, 1], title=L"\hat{s}_\text{model}")

    ax_measured = Makie.Axis(fig[1, 2], title=L"\hat{s}_\text{avg}")
    linkaxes!(ax_model, ax_measured)

    ax_diff = Makie.Axis(fig[2, 1:2], title=L"\hat{s}_\text{model} - \hat{s}_\text{avg}")

    image!(ax_model, deconv_model)
    image!(ax_measured, deconv_measured)
    image!(ax_diff, deconv_model .- deconv_measured)
    limits!(ax_model, extrema.(inds)...)

    double_horiz_center_inds = patch_inds("CC"; imsize=size(LR_beads_sum), grid=2.5)[1], inds[2]
    limits!(ax_diff, extrema.(double_horiz_center_inds)...)

    colgap!(fig.layout, Relative(0.04))
    rowgap!(fig.layout, Relative(0.04))
    return fig
end

savefig(fig_model_vs_measured_decon_and_diff, FIG_NAME * "-deconv-and-diff"; skip=[:vector], override_theme=merge(MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT))
