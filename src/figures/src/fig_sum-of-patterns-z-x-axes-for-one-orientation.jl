const SKIP_PREPARE_IMAGES = true
include("init.jl")
using StatsBase
FIG_NAME = getbase(@__FILE__)

fig = Makie.Figure()
# TODO: Make some convention to determine pixels typographically ... (siunitx?) <20-11-23> 
ga = fig[1:2, 1] = GridLayout()
ax = Makie.Axis(ga[2, 1]; xlabel=L"px")
rowgap!(ga, 0) # TODO: Set in theme <20-11-23> 
colgap!(ga, 2) # TODO: Set in theme <20-11-23> 

# FIX: Using the alternative noisy image modulations instead of the estimates <19-11-23> 
phase_offset = IP_params[:phase_offsets][1]
shift = IP_params[:shifts][1]
modulation = IP_params[:modulations_alt][1]

modulations = repeat([modulation .* 2], 3)
orienations = zeros(3)
phases = map(x -> mod(x, 2π), map(i -> phase_offset + i * 2π / 3, 0:2))
frequencies = repeat([hypot(shift...) / (512 * LR_beads_Δxy)], 3)

harmonics = [(Harmonic(m, o, f, p))(; Δxy=LR_beads_Δxy) for (m, o, f, p) in zip(modulations, orienations, frequencies, phases)]

for (i, h) in zip(map(orientation_mark, 1:3), harmonics)
    lines!(ax, 0 .. 3, x -> h(x, 0), label=latexstring("I_" * "$i"))
end

lines!(ax, 0 .. 3, x -> sum(h(x, 0) for h in harmonics), label=L"I_\Sigma")
xlims!(ax, 0, 3)
ylims!(ax, 0, 3.3)
hidedecorations!(ax; ticks=false, label=false, ticklabels=false)
ga[1, 1] = Legend(fig, ax, framevisible=false, tellwidth=false, nbanks=4, patchsize=(10, 10)) # TODO: Set in theme <20-11-23>

ax.xticks = (1:3, map(latexstring, 1:3))
ax.yticks = (1:3, map(latexstring, 1:3))

savefig(fig, FIG_NAME; hwratio=0.8, skip=[:raster, :full, :pdf, :eps], override_theme=OVERRIDE_THEMES[:latex_format_ticklabels])
