include("background-foreground-otsu.jl")

# TODO: Finish figure with GridLayout <21-11-23> 
# TODO: Consider using mosaic views instead separate plots... It would be easier layouting... (disadvantage is the
# absence of ticks) <21-11-23> 

const FIG_NAME = getbase(@__FILE__)

contrast_coef = 2

bg_beads_otsu = LR_beads_sum .* (fg_otsu .== 0)
fg_beads_otsu = LR_beads_sum .* fg_otsu

fig = Figure()

green_red_fg_bg = colorview(RGB, channelview(contrast_coef .* bg_beads_otsu), channelview(fg_beads_otsu), Zeros(size(fg_beads_otsu)))
ax_l_1 = Makie.Axis(fig[2, 1], aspect=DataAspect())
image!(ax_l_1, green_red_fg_bg)

bg_beads_lowered = @lift LR_beads_sum .* ($fg_otsu_lowered .== 0)
fg_beads_lowered = @lift LR_beads_sum .* $fg_otsu_lowered

green_red_fg_bg_lowered = @lift colorview(RGB, channelview(contrast_coef .* $bg_beads_lowered), channelview($fg_beads_lowered), Zeros(size($fg_beads_lowered)))
ax_l_2 = Makie.Axis(fig[2, 2], aspect=DataAspect())
image!(ax_l_2, green_red_fg_bg_lowered)
linkaxes!(ax_l_1, ax_l_2)

limits!(ax_l_1, (236, 245), (244, 253))
ax_l_1.xticks = ([236, 240, 245], map(latexstring, [236, 240, 245]))
ax_l_1.yticks = ([244, 248, 253], map(latexstring, [244, 248, 253]))
ax_l_2.xticks = ([236, 240, 245], map(latexstring, [236, 240, 245]))
ax_l_2.yticks = ([244, 248, 253], map(latexstring, [244, 248, 253]))

ax_diff = Makie.Axis(fig[1, 1:2], aspect=DataAspect())

plain_diffview = @lift $bg_beads_lowered - bg_beads_otsu
RGB_diffview = @lift colorview(RGB, channelview(contrast_coef .* bg_beads_otsu), channelview(contrast_coef .* $bg_beads_lowered), Zeros(size(LR_beads_sum)))

image!(ax_diff, RGB_diffview)
limits!(ax_diff, (147, 320), (75, 180))
ax_diff.xticks = ([148, 234, 320], map(latexstring, [148, 234, 320]))
ax_diff.yticks = ([76, 128, 180], map(latexstring, [76, 128, 180]))

savefig(fig, FIG_NAME; skip=[:vector])
