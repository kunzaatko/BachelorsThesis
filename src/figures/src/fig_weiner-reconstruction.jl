include("init.jl")
using TransferFunctions: Cosine, apodize

const FIG_NAME = getbase(@__FILE__)

######################
### Reconstruction ###
######################

# weiner_reconstruction(imgs, shifts, phase_offsets, modulations, otf_model)
s_out_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/spatial_weiner_reconstruction_model.ser"))
f_out_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/fourier_weiner_reconstruction_model.ser"))

function fig_weiner(orientation=:horiz)
    fig = Figure()
    if orientation == :vert
        s_ax, f_ax = Makie.Axis(fig[1, 1]), Makie.Axis(fig[2, 1])
        rowgap!(fig.layout, Relative(0.07))
    elseif orientation == :horiz
        s_ax, f_ax = Makie.Axis(fig[1, 1]), Makie.Axis(fig[1, 2])
        colgap!(fig.layout, Relative(0.07))
    end

    s_ax.xticksvisible = s_ax.yticksvisible = s_ax.yticklabelsvisible = s_ax.xticklabelsvisible = false
    f_center_x, f_center_y = size(f_out_model) ./ 2 .+ 0.5
    f_ax.xticks, f_ax.yticks = ([f_center_x], [L"0"]), ([f_center_y], [L"0"])

    image!(s_ax, match_hist(real(s_out_model)))
    image!(f_ax, log2.(abs.(fftshift(f_out_model)) .+ 1))

    if orientation == :vert
        linesegments!(f_ax, [size(f_out_model, 1), 0, f_center_x, f_center_x], [f_center_y, f_center_y, size(f_out_model, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot)
    elseif orientation == :horiz
        linesegments!(f_ax, [size(f_out_model, 1), 0, f_center_x, f_center_x], [f_center_y, f_center_y, size(f_out_model, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)
    end

    return fig
end
savefig(fig_weiner, FIG_NAME; hwratio=0.5, skip=[:vector], override_theme=merge(NO_SPINE, DATA_ASPECT), fig_function_args=(; orientation=:horiz))
savefig(fig_weiner, FIG_NAME * "-vert"; hwratio=2, skip=[:vector, :full], override_theme=merge(NO_SPINE, DATA_ASPECT), fig_function_args=(; orientation=:vert))

###################
### APODIZATION ###
###################

apo_width = 70
apo = Cosine(1)

function fig_apo_3D(func=wireframe!, step=16)
    ones_apo = apodize(apo, ones(size(s_out_model)), 240 + apo_width, apo_width) |> fftshift
    fig = Figure()
    rowgap!(fig.layout, 1)
    colgap!(fig.layout, 1)
    ax = Axis3(fig[1, 1])
    ax.xticksvisible = ax.yticksvisible = ax.xticklabelsvisible = ax.yticklabelsvisible = false
    ax.zticks = ([0, 0.5, 1], [L"0", L"1/2", L"1"])
    ax.xlabelvisible = ax.ylabelvisible = ax.zlabelvisible = false
    # ax.zlabel = L"A(\vec{r})"
    func(ax, -511.5:step:511.5, -511.5:step:511.5, ones_apo[begin:step:end, begin:step:end]; linewidth=3)
    fig
end

# FIX: There is a problem with the limits. The spines are offset from the data in the xy-plane <22-12-23> 
# FIX: Must be generated manually, the savefig function does not work for some reason <22-12-23> 
with_theme(merge(Theme(Axis3=(; protrusions=(14, 0, 0, 0))), MARGIN_THEME(HWRATIO), RASTER_THEME, CAIRO_THEME, BASE_THEME)) do
    @info "Building figure at weiner-reconstruction-surface-apo_margin.png"
    fig = fig_apo_3D(surface!, 1)
    save(joinpath(abspath(dirname(@__FILE__)), "../weiner-reconstruction-surface-apo_margin.png"), fig; backend=CairoMakie, pt_per_unit=1, px_per_unit=20)
end
# savefig(fig_apo_3D, FIG_NAME * "-surface-apo"; hwratio=1, fig_function_args=(surface!, 1), px_per_unit=1)


function fig_apo_2D(func=heatmap!)
    ones_apo = apodize(apo, ones(size(s_out_model)), 240 + apo_width, apo_width) |> fftshift
    fig = Figure()
    ax = Makie.Axis(fig[1, 1])
    ax.xticksvisible = ax.yticksvisible = ax.xticklabelsvisible = ax.yticklabelsvisible = false
    # ax.xlabelvisible = ax.ylabelvisible = ax.zlabelvisible = false
    # ax.zlabel = L"A(\vec{r})"
    func(ax, -511.5:1:511.5, -511.5:1:511.5, ones_apo) #; linewidth=3)
    fig
end

f_apo = apodize(apo, f_out_model, 240 + apo_width, apo_width)
s_apo = ifft(f_apo)

function fig_apo()
    fig = Figure()
    s_ax, f_ax = Makie.Axis(fig[1, 1]), Makie.Axis(fig[1, 2])
    colgap!(fig.layout, Relative(0.07))

    image!(s_ax, match_hist(real(s_apo)))
    image!(f_ax, log2.(abs.(fftshift(f_apo)) .+ 1))

    s_ax.xticksvisible = s_ax.yticksvisible = s_ax.yticklabelsvisible = s_ax.xticklabelsvisible = false

    f_apo_center_x, f_apo_center_y = size(f_apo) ./ 2 .+ 0.5
    f_ax.xticks, f_ax.yticks = ([f_apo_center_x], [L"0"]), ([f_apo_center_y], [L"0"])
    linesegments!(f_ax, [size(f_apo, 1), 0, f_apo_center_x, f_apo_center_x], [f_apo_center_y, f_apo_center_y, size(f_apo, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)

    return fig
end

savefig(fig_apo, FIG_NAME * "-apodization"; hwratio=0.5, skip=[:vector], override_theme=merge(NO_SPINE, DATA_ASPECT))

#################
### ARTIFACTS ###
#################

function fig_artifacts_apo_diff()
    fig = Figure()
    ax, ax_apo, ax_diff = Makie.Axis(fig[1, 1]), Makie.Axis(fig[2, 1]), Makie.Axis(fig[3, 1])
    linkaxes!(ax, ax_apo, ax_diff)

    xlims, ylims = HR_comparison_lims
    xinds_LR, yinds_LR = (first(xlims)÷2):(last(xlims)÷2), (first(ylims)÷2):(last(ylims)÷2)
    ax.title = L"\hat{s}"
    image!(ax, match_hist(real(s_out_model); match_img=LR_beads_sum[xinds_LR, yinds_LR]))

    ax_apo.title = L"\hat{s}_\text{apo}"
    image!(ax_apo, match_hist(real(s_apo); match_img=LR_beads_sum[xinds_LR, yinds_LR]))

    ax_diff.title = L"\hat{s} - \hat{s}_\text{apo}"
    image!(ax_diff, real(s_out_model) .- real(s_apo))

    xticks, yticks = tick_locations((xlims, ylims), 0.1)
    ax.xticks = ax_apo.xticks = ax_diff.xticks = xticks
    ax.yticks = ax_apo.yticks = ax_diff.yticks = yticks
    limits!(ax, xlims, ylims)

    rowgap!(fig.layout, Relative(0.04))
    return fig
end

savefig(fig_artifacts_apo_diff, FIG_NAME * "-artifacts"; hwratio=2.7, skip=[:full, :vector], override_theme=merge(FORMAT_TICKS, MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT))
