const SKIP_PREPARE_IMAGES = true
include("init.jl")
using StatsBase
const FIG_NAME = getbase(@__FILE__)

# FIX: Using the alternative noisy image modulations instead of the estimates <19-11-23> 
phase_offset = IP_params[:phase_offsets][1]
shift = IP_params[:shifts][1]
modulation = IP_params[:modulations_alt][1]

modulations = repeat([modulation .* 2], 3)
orienations = zeros(3)
phases = map(x -> mod(x, 2π), map(i -> phase_offset + i * 2π / 3, 0:2))
frequencies = repeat([hypot(shift...) / (512 * LR_beads_Δxy)], 3)

harmonics = [(Harmonic(m, o, f, p))(; Δxy=LR_beads_Δxy) for (m, o, f, p) in zip(modulations, orienations, frequencies, phases)]


function fig_sum_of_patterns()
    fig = Makie.Figure()
    # TODO: Make some convention to determine pixels typographically ... (siunitx?) <20-11-23> 
    # ga = fig[1:2, 1] = GridLayout()
    ax = Makie.Axis(fig[2:7, 1])
    # colgap!(ga, 2) # TODO: Set in theme <20-11-23> 

    for (i, h) in zip(map(orientation_mark, 1:3), harmonics)
        lines!(ax, 0 .. 3, x -> h(x, 0), label=latexstring("i_" * "$i"))
    end

    lines!(ax, 0 .. 3, x -> sum(h(x, 0) for h in harmonics), label=L"i_\Sigma")
    xlims!(ax, 0, 3)
    ylims!(ax, 0, 3.3)
    Legend(fig[1, 1], ax)
    rowgap!(fig.layout, Relative(0.04)) # TODO: Set in theme <20-11-23> 

    ax.xticks = 0:3
    ax.yticks = 1:3
    return fig
end
savefig(fig_sum_of_patterns, FIG_NAME; hwratio=0.8, skip=[:raster, :full, :pdf, :eps], override_theme=merge(FORMAT_TICKS))
