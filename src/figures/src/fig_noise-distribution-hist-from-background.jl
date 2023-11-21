include("background-foreground-otsu.jl")

const FIG_NAME = getbase(@__FILE__)

background_data = filter(gray.((fg_otsu_lowered[] .== 0) .* LR_beads_sum)[:]) do px
    px > 0
end

# TODO: Consider changing colours <21-11-23> 
fig, ax, _ = hist(background_data; bins=50, normalization=:density, color=:values)
ax.yticksvisible = false
ax.yticklabelsvisible = false
ax.xticks = (0.0:0.02:0.06, map(latexstring, 0.0:0.02:0.06))
xlims!(ax, (0, 0.07))
ylims!(ax, (0, 6_300_000))

savefig(fig, FIG_NAME; skip=[:eps], backend=GLMakie)
