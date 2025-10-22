include("init.jl")

const FIG_NAME = getbase(@__FILE__)

using TransferFunctions: Cosine, apodize
using Interpolations

s_out_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/spatial_weiner_reconstruction_model.ser"))
f_out_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/fourier_weiner_reconstruction_model.ser"))

function fig_weiner()
    fig = Figure()
    s_ax, f_ax = Makie.Axis(fig[1, 1], title=L"\hat{s}(\vec{r})"), Makie.Axis(fig[1, 2], title=L"\hat{S}(\vec{k})", titlecolor=:orange)
    colgap!(fig.layout, Relative(0.07))

    s_ax.xticksvisible = s_ax.yticksvisible = s_ax.yticklabelsvisible = s_ax.xticklabelsvisible = false
    f_center_x, f_center_y = size(f_out_model) ./ 2 .+ 0.5
    f_ax.xticks, f_ax.yticks = ([f_center_x], [L"0"]), ([f_center_y], [L"0"])
    f_ax.xticksvisible = f_ax.yticksvisible = true

    image!(s_ax, real(s_out_model))
    image!(f_ax, log2.(abs.(fftshift(f_out_model)) .+ 1))

    linesegments!(f_ax, [size(f_out_model, 1), 0, f_center_x, f_center_x], [f_center_y, f_center_y, size(f_out_model, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)

    return fig
end
savefig(fig_weiner, FIG_NAME; hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT))

function fig_weiner_cutout()
    fig = Figure()
    s_ax, f_ax = Makie.Axis(fig[1, 1], title=L"\hat{s}(\vec{r})"), Makie.Axis(fig[1, 2], title=L"\hat{S}(\vec{k})", titlecolor=:orange)
    colgap!(fig.layout, Relative(0.07))

    s_ax.xticksvisible = s_ax.yticksvisible = false
    s_ax.yticklabelsvisible = s_ax.xticklabelsvisible = true
    f_center_x, f_center_y = size(f_out_model) ./ 2 .+ 0.5
    f_ax.xticks, f_ax.yticks = ([f_center_x], [L"0"]), ([f_center_y], [L"0"])
    f_ax.xticksvisible = f_ax.yticksvisible = true

    image!(s_ax, real(s_out_model))
    image!(f_ax, log2.(abs.(fftshift(f_out_model)) .+ 1))

    linesegments!(f_ax, [size(f_out_model, 1), 0, f_center_x, f_center_x], [f_center_y, f_center_y, size(f_out_model, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)

    lims = ((400, 540), (310, 450))
    limits!(s_ax, lims...)
    s_ax.xticks, s_ax.yticks = tick_locations(lims, 0.1)

    return fig
end

savefig(fig_weiner_cutout, FIG_NAME * "-cutout"; hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT))

apo_width = 70
apo = Cosine(1)

f_apo = apodize(apo, f_out_model, 240 + apo_width, apo_width)
s_apo = ifft(f_apo)

function fig_apo_cutout()
    fig = Figure()
    s_ax, f_ax = Makie.Axis(fig[1, 1], title=L"\hat{s}_\text{apo}(\vec{r})"), Makie.Axis(fig[1, 2], title=L"\hat{S}_\text{apo}(\vec{k})", titlecolor=:orange)
    colgap!(fig.layout, Relative(0.07))

    image!(s_ax, real(s_apo))
    image!(f_ax, log2.(abs.(fftshift(f_apo)) .+ 1))

    s_ax.xticksvisible = s_ax.yticksvisible = false
    s_ax.yticklabelsvisible = s_ax.xticklabelsvisible = true

    f_apo_center_x, f_apo_center_y = size(f_apo) ./ 2 .+ 0.5
    f_ax.xticks, f_ax.yticks = ([f_apo_center_x], [L"0"]), ([f_apo_center_y], [L"0"])
    linesegments!(f_ax, [size(f_apo, 1), 0, f_apo_center_x, f_apo_center_x], [f_apo_center_y, f_apo_center_y, size(f_apo, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)
    f_ax.xticksvisible = f_ax.yticksvisible = true

    lims = ((400, 540), (310, 450))
    limits!(s_ax, lims...)
    s_ax.xticks, s_ax.yticks = tick_locations(lims, 0.1)

    return fig
end

savefig(fig_apo_cutout, FIG_NAME * "-apo-cutout"; hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT))

function fig_apo_comp()
    fig = Figure()
    ax_apo, ax = Makie.Axis(fig[1, 1], title=L"\hat{s}_\text{apo}(\vec{r})"), Makie.Axis(fig[1, 2], title=L"\hat{s}(\vec{r})")
    linkaxes!(ax_apo, ax)

    image!(ax_apo, real(s_apo))
    image!(ax, real(s_out_model))

    lims = ((400, 540), (310, 450))
    limits!(ax_apo, lims...)
    ax_apo.xticks, ax_apo.yticks = ax.xticks, ax.yticks = tick_locations(lims, 0.1)

    return fig
end

savefig(fig_apo_comp, FIG_NAME * "-apo-comp"; hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT))

function fig_apo_diff()
    fig = Figure()
    ax_apo = Makie.Axis(fig[1, 1], title=L"(\hat{s} - \hat{s}_\text{apo})(\vec{r})")

    image!(ax_apo, real(s_out_model) - real(s_apo))

    lims = ((400, 540), (310, 450))
    limits!(ax_apo, lims...)
    ax_apo.xticks, ax_apo.yticks = tick_locations(lims, 0.1)

    return fig
end

savefig(fig_apo_diff, FIG_NAME * "-apo-diff"; hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT))
