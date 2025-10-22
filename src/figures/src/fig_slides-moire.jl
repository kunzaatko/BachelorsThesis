include("init.jl")
const FIG_NAME = getbase(@__FILE__)

function fig_moire_on_actin()
    fig = Figure()
    ax = Makie.Axis(fig[1, 1])
    image!(ax, LR_actin)
    fig
end

savefig(fig_moire_on_actin, FIG_NAME * "-on-actin", hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(DATA_ASPECT, NO_SPINE, NO_TICKLABELS, NO_TICKS))

function fig_moire_on_actin_cutout()
    fig = Figure()
    ax = Makie.Axis(fig[1, 1])
    image!(ax, LR_actin)
    lims = ((240, 360), (340, 460))
    ax.xticks, ax.yticks = tick_locations(lims, 0.1)
    limits!(ax, lims...)
    ax.xticklabelsvisible = ax.yticklabelsvisible = true
    fig
end

savefig(fig_moire_on_actin_cutout, FIG_NAME * "-on-actin-cutout", hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, DATA_ASPECT, NO_SPINE), update=true)
