include("init.jl")

const FIG_NAME = getbase(@__FILE__)

function fig_optimization_gr()
    s = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/gr_reconstruction_model.ser"))
    f = fft(s)
    fig = Figure()
    s_ax, f_ax = Makie.Axis(fig[1, 1], title=L"\hat{s}_\text{GR}(\vec{r})"), Makie.Axis(fig[1, 2], title=L"\hat{S}_\text{GR}(\vec{k})", titlecolor=:orange)
    colgap!(fig.layout, Relative(0.07))

    s_ax.xticksvisible = s_ax.yticksvisible = s_ax.yticklabelsvisible = s_ax.xticklabelsvisible = false
    f_ax.xticksvisible = f_ax.yticksvisible = true
    f_center_x, f_center_y = size(f) ./ 2 .+ 0.5
    f_ax.xticks, f_ax.yticks = ([f_center_x], [L"0"]), ([f_center_y], [L"0"])

    image!(s_ax, s)
    image!(f_ax, log2.(abs.(fftshift(f)) .+ 1))

    linesegments!(f_ax, [size(f, 1), 0, f_center_x, f_center_x], [f_center_y, f_center_y, size(f, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)

    return fig
end

savefig(fig_optimization_gr, FIG_NAME * "-gr"; hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT))

function fig_optimization_gr_cutout()
    s = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/gr_reconstruction_model.ser"))
    f = fft(s)
    fig = Figure()
    s_ax, f_ax = Makie.Axis(fig[1, 1], title=L"\hat{s}_\text{GR}(\vec{r})"), Makie.Axis(fig[1, 2], title=L"\hat{S}_\text{GR}(\vec{k})", titlecolor=:orange)
    colgap!(fig.layout, Relative(0.07))

    s_ax.xticksvisible = s_ax.yticksvisible = false
    s_ax.yticklabelsvisible = s_ax.xticklabelsvisible = true
    f_center_x, f_center_y = size(f) ./ 2 .+ 0.5
    f_ax.xticks, f_ax.yticks = ([f_center_x], [L"0"]), ([f_center_y], [L"0"])

    image!(s_ax, s)
    image!(f_ax, log2.(abs.(fftshift(f)) .+ 1))

    linesegments!(f_ax, [size(f, 1), 0, f_center_x, f_center_x], [f_center_y, f_center_y, size(f, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)

    lims = ((400, 540), (310, 450))
    limits!(s_ax, lims...)
    s_ax.xticks, s_ax.yticks = tick_locations(lims, 0.1)
    f_ax.xticksvisible = f_ax.yticksvisible = true

    return fig
end

savefig(fig_optimization_gr_cutout, FIG_NAME * "-gr-cutout"; hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT))

function fig_optimization_gr_vs_tv()
    s_gr = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/gr_reconstruction_model.ser"))
    s_tv = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/tv_reconstruction_model.ser"))

    fig = Figure()
    ax_gr, ax_tv = Makie.Axis(fig[1, 1], title=L"\hat{s}_\text{GR}(\vec{r})"), Makie.Axis(fig[1, 2], title=L"\hat{s}_\text{TV}(\vec{r})")
    colgap!(fig.layout, Relative(0.07))
    linkaxes!(ax_gr, ax_tv)

    # ax_gr.xticksvisible = ax_gr.yticksvisible = 
    #     ax_gr.yticklabelsvisible = ax_gr.xticklabelsvisible = false

    image!(ax_gr, s_gr)
    image!(ax_tv, s_tv)

    # linesegments!(ax_tv, [size(f, 1), 0, f_center_x, f_center_x], [f_center_y, f_center_y, size(f, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)
    lims = ((400, 540), (310, 450))
    limits!(ax_tv, lims...)
    ax_tv.xticks, ax_tv.yticks = ax_gr.xticks, ax_gr.yticks = tick_locations(lims, 0.1)

    return fig
end

savefig(fig_optimization_gr_vs_tv, FIG_NAME * "-gr-vs-tv"; hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT))

function fig_3LR_vs_9LR()
    s_3 = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/gr_reconstruction_model_3.ser"))
    s_3 = scaleminmax(extrema(s_3)...).(s_3)
    s_9 = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/gr_reconstruction_model.ser"))
    s_9 = scaleminmax(extrema(s_9)...).(s_9)

    fig = Figure()
    ax_3, ax_9 = Makie.Axis(fig[1, 1], title=L"\hat{s}_\text{3LR}(\vec{r})"), Makie.Axis(fig[1, 2], title=L"\hat{s}_\text{9LR}(\vec{r})")
    linkaxes!(ax_3, ax_9)

    image!(ax_3, s_3)
    image!(ax_9, s_9)

    lims = ((400, 540), (310, 450))
    limits!(ax_9, lims...)
    ax_3.xticks, ax_3.yticks = ax_9.xticks, ax_9.yticks = tick_locations(lims, 0.1)

    # rowgap!(fig.layout, Relative(0.04))
    return fig
end

savefig(fig_3LR_vs_9LR, FIG_NAME * "-3LR-vs-9LR"; hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(FORMAT_TICKS, MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT), update=true)

