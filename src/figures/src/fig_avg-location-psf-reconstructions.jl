include("init.jl")
using TransferFunctions: Cosine, apodize

const FIG_NAME = getbase(@__FILE__)

patch_reconstructions = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/weiner_patch_reconstructions_dict.ser"))

patch_reconstructions = Dict()
for patch in ["CC", "LT", "RT", "LB", "RB"]
    s_out = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/spatial_weiner_reconstruction_$(patch).ser"))
    f_out = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/fourier_weiner_reconstruction_$(patch).ser"))
    patch_reconstructions[patch] = (s_out, f_out)
end

function fig_compare()
    fig = Figure()
    ax = [Makie.Axis(fig[ceil(Int64, i / 3), (i-1)%3+1], title="$i") for i in 1:9]
    linkaxes!(ax...)
    line_vargs = (; color=:yellow, linestyle=:dash, alpha=0.5)
    function beads_box(ax, patch)
        (xmin, xmax), (ymin, ymax) = extrema.(patch_inds(patch))
        lines!(ax, [xmin, xmin, xmax, xmax, xmin], [ymin, ymax, ymax, ymin, ymin]; line_vargs...)
    end
    image!(ax[1], real(patch_reconstructions["RB"][1]))
    beads_box(ax[1], "RB")
    image!(ax[3], real(patch_reconstructions["RT"][1]))
    beads_box(ax[3], "RT")
    image!(ax[5], real(patch_reconstructions["CC"][1]))
    beads_box(ax[5], "CC")
    image!(ax[7], real(patch_reconstructions["LB"][1]))
    beads_box(ax[7], "LB")
    image!(ax[9], real(patch_reconstructions["LT"][1]))
    beads_box(ax[9], "LT")
    fig
end

function fig_compare_at_locs()
    fig = Figure()
    ax = [Makie.Axis(fig[ceil(Int64, i / 3), (i-1)%3+1], title=latexstring("\\text{$tit}")) for (i, tit) in zip(
        [1, 3, 5, 7, 9],
        ["Left-Top", "Right-Top", "Center-Center", "Left-Bottom", "Right-Bottom"])]
    # linkaxes!(ax...)
    line_vargs = (; color=:yellow, linestyle=:dash, alpha=0.5)
    function beads_box(ax, patch)
        (xmin, xmax), (ymin, ymax) = extrema.(patch_inds(patch))
        lines!(ax, [xmin, xmin, xmax, xmax, xmin], [ymin, ymax, ymax, ymin, ymin]; line_vargs...)
    end
    s_glob = 50
    for (a, p, s) in zip(ax, ["RB", "RT", "CC", "LB", "LT"],
        [((0, 1), (-1, 0)), ((-1, 0), (-1, 0)), ((-0.5, 0.5), (-0.5, 0.5)), ((0, 1), (0, 1)), ((-1, 0), (0, 1))])
        image!(a, real(patch_reconstructions[p][1]))
        xlims, ylims = extrema.(patch_inds(p))
        limits!(a, xlims .+ s_glob .* s[1], ylims .+ s_glob .* s[2])
        beads_box(a, p)
    end
    colgap!(fig.layout, 0.04)
    rowgap!(fig.layout, 0.04)
    fig
end

savefig(fig_compare_at_locs, FIG_NAME * "-spatial-comp"; hwratio=1, skip=[:raster, :eps], override_theme=merge(MARGIN_PX_TICKS, FORMAT_TICKS, DATA_ASPECT, NO_SPINE), update=true)

function fig_compare_center()
    fig = Figure()
    ax = [Makie.Axis(fig[ceil(Int64, i / 3), (i-1)%3+1], title=latexstring("\\text{$tit}")) for (i, tit) in zip(
        [1, 3, 5, 7, 9],
        ["Left-Top", "Right-Top", "Center-Center", "Left-Bottom", "Right-Bottom"])]
    linkaxes!(ax...)
    line_vargs = (; color=:yellow, linestyle=:dash, alpha=0.5)
    function beads_box(ax, patch)
        (xmin, xmax), (ymin, ymax) = extrema.(patch_inds(patch))
        lines!(ax, [xmin, xmin, xmax, xmax, xmin], [ymin, ymax, ymax, ymin, ymin]; line_vargs...)
    end
    s_glob = 50
    for (a, p) in zip(ax, ["RB", "RT", "CC", "LB", "LT"])
        image!(a, real(patch_reconstructions[p][1]))
        beads_box(a, p)
        xlims, ylims = extrema.(patch_inds("LB"))
        a.limits = xlims .+ s_glob .* (0, 1), ylims .+ s_glob .* (0, 1)
    end
    colgap!(fig.layout, 0.04)
    rowgap!(fig.layout, 0.04)
    fig
end
savefig(fig_compare_center, FIG_NAME * "-spatial-comp-rt"; hwratio=1, skip=[:raster, :eps], override_theme=merge(MARGIN_PX_TICKS, FORMAT_TICKS, DATA_ASPECT, NO_SPINE), update=true)

function fig_compare_both()
    fig = Figure()
    f_out_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/fourier_weiner_reconstruction_model.ser"))
    ax_m, ax_e = Makie.Axis(fig[1, 1], title=L"\hat{S}_\text{model}"), Makie.Axis(fig[1, 2], title=L"\hat{S}_\text{avg}")
    image!(ax_e, fftshift(log2.(abs.(patch_reconstructions["CC"][2]) .+ 1)))
    image!(ax_m, fftshift(log2.(abs.(f_out_model) .+ 1)))

    s_out_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/spatial_weiner_reconstruction_model.ser"))
    ax_m, ax_e = Makie.Axis(fig[2, 1], title=L"\hat{s}_\text{model}"), Makie.Axis(fig[2, 2], title=L"\hat{s}_\text{avg}")
    image!(ax_e, real(patch_reconstructions["CC"][1]))
    image!(ax_m, real(s_out_model))
    fig
end

savefig(fig_compare_both, FIG_NAME * "-b-comp-cc"; hwratio=1, skip=[:eps], override_theme=merge(NO_TICKS, NO_SPINE, DATA_ASPECT, NO_TICKLABELS), update=true)

patch_reconstructions_ccp = Dict()
for patch in ["CC", "LT", "RT", "LB", "RB"]
    s_out = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/spatial_weiner_reconstruction_$(patch)_ccp.ser"))
    f_out = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/fourier_weiner_reconstruction_$(patch)_ccp.ser"))
    patch_reconstructions_ccp[patch] = (s_out, f_out)
end

function fig_compare_fourier_ccp()
    fig = Figure()
    f_out_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/fourier_weiner_reconstruction_model_ccp.ser"))
    ax_m, ax_e = Makie.Axis(fig[1, 1], title=L"\hat{S}_\text{model}"), Makie.Axis(fig[1, 2], title=L"\hat{S}_\text{avg}")
    linkaxes!(ax_e, ax_m)
    image!(ax_e, fftshift(log2.(abs.(patch_reconstructions_ccp["CC"][2]) .+ 1)))
    image!(ax_m, fftshift(log2.(abs.(f_out_model) .+ 1)))
    fig
end
savefig(fig_compare_fourier_ccp, FIG_NAME * "-f-comp-cc-ccp"; hwratio=4 / 7, skip=[:eps], override_theme=merge(NO_TICKS, NO_SPINE, DATA_ASPECT, NO_TICKLABELS), update=true)

function fig_compare_spatial_ccp()
    fig = Figure()
    f_out_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/spatial_weiner_reconstruction_model_ccp.ser"))
    ax_m, ax_e = Makie.Axis(fig[1, 1], title=L"\hat{s}_\text{model}"), Makie.Axis(fig[1, 2], title=L"\hat{s}_\text{avg}")
    linkaxes!(ax_e, ax_m)
    image!(ax_e, real(patch_reconstructions_ccp["CC"][1]))
    image!(ax_m, real(f_out_model))
    fig
end
savefig(fig_compare_spatial_ccp, FIG_NAME * "-s-comp-cc-ccp"; hwratio=4 / 7, skip=[:eps], override_theme=merge(NO_TICKS, NO_SPINE, DATA_ASPECT, NO_TICKLABELS), update=true)

function fig_compare_both_ccp()
    fig = Figure()
    f_out_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/fourier_weiner_reconstruction_model_ccp.ser"))
    ax_m, ax_e = Makie.Axis(fig[1, 1], title=L"\hat{S}_\text{model}"), Makie.Axis(fig[1, 2], title=L"\hat{S}_\text{avg}")
    image!(ax_e, fftshift(log2.(abs.(patch_reconstructions_ccp["CC"][2]) .+ 1)))
    image!(ax_m, fftshift(log2.(abs.(f_out_model) .+ 1)))
    linkaxes!(ax_e, ax_m)

    s_out_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/spatial_weiner_reconstruction_model_ccp.ser"))
    ax_m_f, ax_e_f = Makie.Axis(fig[2, 1], title=L"\hat{s}_\text{model}"), Makie.Axis(fig[2, 2], title=L"\hat{s}_\text{avg}")
    image!(ax_e_f, real(patch_reconstructions_ccp["CC"][1]))
    image!(ax_m_f, real(s_out_model))
    linkaxes!(ax_e_f, ax_m_f)
    fig
end

savefig(fig_compare_both_ccp, FIG_NAME * "-b-comp-cc-ccp"; hwratio=1, skip=[:eps], override_theme=merge(NO_TICKS, NO_SPINE, DATA_ASPECT, NO_TICKLABELS), update=true)

function fig_compare_model_ccp_and_beads_fft()
    fig = Figure()
    f_out_ccp = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/fourier_weiner_reconstruction_model_ccp.ser"))
    f_out_beads = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/fourier_weiner_reconstruction_model.ser"))
    ax_ccp, ax_beads = Makie.Axis(fig[1, 2], title=L"\hat{S}_\text{ccp}"), Makie.Axis(fig[1, 1], title=L"\hat{S}_\text{beads}")
    image!(ax_ccp, fftshift(log2.(abs.(f_out_ccp) .+ 1)))
    image!(ax_beads, fftshift(log2.(abs.(f_out_beads) .+ 1)))
    linkaxes!(ax_ccp, ax_beads)
    fig
end

savefig(fig_compare_model_ccp_and_beads_fft, FIG_NAME * "-model-ccp-and-beads-fft"; hwratio=4 / 7, skip=[:eps], override_theme=merge(NO_TICKS, NO_SPINE, DATA_ASPECT, NO_TICKLABELS), update=true)

function fig_compare_model_ccp_and_beads_spatial()
    fig = Figure()
    s_out_ccp = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/spatial_weiner_reconstruction_model_ccp.ser"))
    s_out_beads = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/spatial_weiner_reconstruction_model.ser"))
    ax_ccp, ax_beads = Makie.Axis(fig[1, 2], title=L"\hat{s}_\text{ccp}"), Makie.Axis(fig[1, 1], title=L"\hat{s}_\text{beads}")
    image!(ax_ccp, real(s_out_ccp))
    image!(ax_beads, real(s_out_beads))
    linkaxes!(ax_ccp, ax_beads)
    fig
end

savefig(fig_compare_model_ccp_and_beads_spatial, FIG_NAME * "-model-ccp-and-beads-spatial"; hwratio=4 / 7, skip=[:eps], override_theme=merge(NO_TICKS, NO_SPINE, DATA_ASPECT, NO_TICKLABELS), update=true)

function fig_compare_ccp_s_donut()
    fig = Figure()
    s_out_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/spatial_weiner_reconstruction_model_ccp.ser"))
    ax_m_f, ax_e_f = Makie.Axis(fig[1, 1], title=L"\hat{s}_\text{model}"), Makie.Axis(fig[1, 2], title=L"\hat{s}_\text{avg}")
    image!(ax_e_f, real(patch_reconstructions_ccp["CC"][1]))
    image!(ax_m_f, real(s_out_model))
    # linkaxes!(ax_e_f, ax_m_f)
    ax_m_f.limits = ((770, 830), (440, 500))
    ax_e_f.limits = ((770, 830), (440, 500))
    ax_m_f.xticks, ax_m_f.yticks = tick_locations(((770, 830), (440, 500)), 0.1)
    ax_e_f.xticks, ax_e_f.yticks = tick_locations(((770, 830), (440, 500)), 0.1)
    fig
end

savefig(fig_compare_ccp_s_donut, FIG_NAME * "-b-comp-cc-ccp-donut"; hwratio=0.5, skip=[:eps], override_theme=merge(MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT), update=true)
