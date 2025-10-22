include("init.jl")
const FIG_NAME = getbase(@__FILE__)

patch_reconstructions = Dict()
for patch in ["CC", "LT", "RT", "LB", "RB"]
    s_out = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/spatial_weiner_reconstruction_$(patch).ser"))
    f_out = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/fourier_weiner_reconstruction_$(patch).ser"))
    patch_reconstructions[patch] = (s_out, f_out)
end

function fig_selected_beads_CC()
    _, selection_point2f = get_selected_beads("CC")
    inds = patch_inds("CC"; imsize=size(LR_beads_sum))
    fig = Makie.Figure()

    ax = Makie.Axis(fig[1, 1])
    xlims, ylims = extrema.(inds)
    limits!(ax, xlims, ylims)
    ax.xticks, ax.yticks = tick_locations((xlims, ylims), 0.1)

    image!(ax, LR_beads_sum)

    scatter!(ax, map(point -> point .- (0.5, 0.5), selection_point2f); marker=:circle, markerspace=:data, markersize=3, color=COLORS[1])

    return fig
end

savefig(fig_selected_beads_CC, FIG_NAME * "-CC"; hwratio=4 / 7, skip=[:eps, :margin], override_theme=merge(FORMAT_TICKS, MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT))

function fig_centered_beads_cutouts()
    rois = get_psf_averaged_estimate("CC")[:rois]
    px_inds_centers_selected = map(c -> round.(Int, c), get_selected_beads("CC")[1])
    subpx_centers = get_psf_averaged_estimate("CC")[:positions]
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
        scatter!(ax, [c], marker=:circle, markersize=3, color=COLORS[1])
        xticks_pos, yticks_pos = tick_locations(((1, 15), (1, 15)), 0.1)
        xticks, yticks = tick_locations(lims, 0.1)
        ax.xticks, ax.yticks = (xticks_pos, latexstring.(xticks)), (yticks_pos, latexstring.(yticks))
    end
    # rowgap!(fig.layout, Makie.Fixed(2))
    # colgap!(fig.layout, Makie.Fixed(2))
    fig
end

savefig(fig_centered_beads_cutouts, FIG_NAME * "-patches-CC", skip=[:eps, :margin], hwratio=4 / 7, override_theme=merge(MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT))

psf_model = psf(IdealOTFwithCurvature(488u"nm", 1.4, 1.0, 0.9), 15, 61u"nm").parent |> real


function fig_model_vs_measured()
    fig = Figure()
    ax_model, ax_measured = Makie.Axis(fig[1, 1], title=L"h_\text{model}"), Makie.Axis(fig[1, 2], title=L"h_\text{avg}")
    linkaxes!(ax_model, ax_measured)

    psf_measured = get_psf_averaged_estimate("CC")[:psf]

    image!(ax_model, psf_model)
    image!(ax_measured, psf_measured)
    return fig
end

savefig(fig_model_vs_measured, FIG_NAME * "-CC-estimate"; hwratio=4 / 7, skip=[:eps, :margin], override_theme=merge(NO_SPINE, DATA_ASPECT, NO_TICKS, NO_TICKLABELS))


function fig_compare_fourier()
    fig = Figure()
    f_out_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/fourier_weiner_reconstruction_model.ser"))

    ax_m, ax_e = Makie.Axis(fig[1, 1], title=L"\hat{S}_\text{model}", titlecolor=:orange), Makie.Axis(fig[1, 2], title=L"\hat{S}_\text{avg}", titlecolor=:orange)
    image!(ax_e, fftshift(log2.(abs.(patch_reconstructions["CC"][2]) .+ 1)))
    image!(ax_m, fftshift(log2.(abs.(f_out_model) .+ 1)))

    center_x, center_y = size(f_out_model) ./ 2 .+ 0.5
    ax_e.xticks, ax_e.yticks = ax_m.xticks, ax_m.yticks = ([center_x], [L"0"]), ([center_y], [L"0"])
    ax_e.xticklabelsvisible = ax_e.yticklabelsvisible = ax_m.xticklabelsvisible = ax_m.yticklabelsvisible = true
    ax_e.xticksvisible = ax_e.yticksvisible = ax_m.xticksvisible = ax_m.yticksvisible = true
    linesegments!(ax_m, [size(f_out_model, 1), 0, center_x, center_x], [center_y, center_y, size(f_out_model, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)
    linesegments!(ax_e, [size(f_out_model, 1), 0, center_x, center_x], [center_y, center_y, size(f_out_model, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)

    fig
end
savefig(fig_compare_fourier, FIG_NAME * "-reconstruction-fourier"; hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT), update=true)

function fig_compare_spatial()
    fig = Figure()
    f_out_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/spatial_weiner_reconstruction_model.ser"))
    ax_m, ax_e = Makie.Axis(fig[1, 1], title=L"\hat{s}_\text{model}"), Makie.Axis(fig[1, 2], title=L"\hat{s}_\text{avg}")
    linkaxes!(ax_e, ax_m)

    image!(ax_e, real(patch_reconstructions["CC"][1]))
    image!(ax_m, real(f_out_model))

    fig
end
savefig(fig_compare_spatial, FIG_NAME * "-reconsruction-spatial"; hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(NO_TICKS, NO_SPINE, DATA_ASPECT, NO_TICKLABELS), update=true)

function fig_compare_spatial_cutout()
    fig = Figure()
    f_out_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/spatial_weiner_reconstruction_model.ser"))

    ax_m, ax_e = Makie.Axis(fig[1, 1], title=L"\hat{s}_\text{model}"), Makie.Axis(fig[1, 2], title=L"\hat{s}_\text{avg}")
    linkaxes!(ax_e, ax_m)

    image!(ax_e, real(patch_reconstructions["CC"][1]))
    image!(ax_m, real(f_out_model))

    lims = ((390, 480), (465, 555))
    limits!(ax_e, lims...)
    ax_e.xticks, ax_e.yticks = ax_m.xticks, ax_m.yticks = tick_locations(lims, 0.1)
    ax_e.xticklabelsvisible = ax_e.yticklabelsvisible = ax_m.xticklabelsvisible = ax_m.yticklabelsvisible = true

    return fig
end
savefig(fig_compare_spatial_cutout, FIG_NAME * "-reconstruction-spatial-cutout"; hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT), update=true)

s_sim_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/spatial_weiner_reconstruction_model_ccp3_apo.ser"))
f_sim_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/fourier_weiner_reconstruction_model_ccp3_apo.ser"))
s_sim_cc = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/spatial_weiner_reconstruction_CC_ccp3_apo.ser"))
f_sim_cc = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/fourier_weiner_reconstruction_CC_ccp3_apo.ser"))

function fig_compare_fourier_ccp()
    fig = Figure()

    ax_m, ax_e = Makie.Axis(fig[1, 1], title=L"\hat{S}_\text{model}", titlecolor=:orange), Makie.Axis(fig[1, 2], title=L"\hat{S}_\text{avg}", titlecolor=:orange)
    image!(ax_e, fftshift(log2.(abs.(f_sim_cc) .+ 1)))
    image!(ax_m, fftshift(log2.(abs.(f_sim_model) .+ 1)))

    center_x, center_y = size(f_sim_cc) ./ 2 .+ 0.5
    ax_e.xticks, ax_e.yticks = ax_m.xticks, ax_m.yticks = ([center_x], [L"0"]), ([center_y], [L"0"])
    ax_e.xticklabelsvisible = ax_e.yticklabelsvisible = ax_m.xticklabelsvisible = ax_m.yticklabelsvisible = true
    ax_e.xticksvisible = ax_e.yticksvisible = ax_m.xticksvisible = ax_m.yticksvisible = true
    linesegments!(ax_m, [size(f_sim_cc, 1), 0, center_x, center_x], [center_y, center_y, size(f_sim_cc, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)
    linesegments!(ax_e, [size(f_sim_cc, 1), 0, center_x, center_x], [center_y, center_y, size(f_sim_cc, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)

    fig
end
savefig(fig_compare_fourier_ccp, FIG_NAME * "-reconstruction-fourier-ccp"; hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT), update=true)

function fig_compare_spatial_ccp_cutout()
    fig = Figure()

    ax_m, ax_e = Makie.Axis(fig[1, 1], title=L"\hat{s}_\text{model}"), Makie.Axis(fig[1, 2], title=L"\hat{s}_\text{avg}")
    linkaxes!(ax_e, ax_m)

    image!(ax_e, real(s_sim_cc))
    image!(ax_m, real(s_sim_model))

    lims = ((290, 420), (690, 820))
    limits!(ax_e, lims...)
    ax_e.xticks, ax_e.yticks = ax_m.xticks, ax_m.yticks = tick_locations(lims, 0.1)
    ax_e.xticklabelsvisible = ax_e.yticklabelsvisible = ax_m.xticklabelsvisible = ax_m.yticklabelsvisible = true

    return fig
end
savefig(fig_compare_spatial_ccp_cutout, FIG_NAME * "-reconstruction-spatial-ccp-cutout"; hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT), update=true)
