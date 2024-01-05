SKIP_PREPARE_IMAGES = NONIMAGE_DATA_LOADED = true
include("init.jl")
using Distributions, SpecialFunctions

const FIG_NAME = getbase(@__FILE__)

function fig_poisson_noise_dist()
    fig = Figure()
    ax = Makie.Axis(fig[2, 1])
    lines!(ax, 0 .. 10.5, x -> smooth_poiss.(x; λ=4), label=L"\tilde{\mathcal{P}}_{\lambda}(x)", color=COLORS[2])
    scatter!(ax, 0:10, smooth_poiss.(0:10; λ=4); label=L"\mathcal{P}_{\lambda}[N = k]")
    Legend(fig[1, 1], ax)
    rowgap!(fig.layout, Relative(0.04)) # TODO: Set in theme <20-11-23> 
    ax.yticksvisible = ax.yticklabelsvisible = false
    limits!(ax, (-0.3, 10.5), (0, 0.22))
    fig
end

savefig(fig_poisson_noise_dist, FIG_NAME; hwratio=1, skip=[:raster, :full, :eps], override_theme=merge(FORMAT_TICKS))
