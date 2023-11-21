include("init.jl")
const FIG_NAME = getbase(@__FILE__)

# fig = Makie.Figure()
# axes = [Makie.Axis(
#     fig[i, j],
#     # title=latexstring("o^" * orientation_mark(j) * "_" * "$i"),
#     # titlevisible=false,
#     # yticksvisible=false,
#     # xticksvisible=false,
#     # yticklabelsvisible=false,
#     # xticklabelsvisible=false,
#     aspect=DataAspect(),
# ) for i in 1:3, j in 1:3]

# for (ax, im) in zip(axes, eachslice(LR_beads; dims=3))
#     hidedecorations!(ax)
#     image!(ax, im)
# end

npad = 10
nw, nh = size(LR_beads)[1:2]
mos = mosaic(collect(eachslice(LR_beads; dims=3))...; ncol=3, rowmajor=true, fillvalue=1, npad)

fig, ax, _ = image(mos)
ax.aspect = DataAspect()
ax.yticks = ([nw ÷ 2, 3nw ÷ 2 + npad, 5nw ÷ 2 + 2npad], [L"1", L"2", L"3"])
# ax.ylabel = "Orientation"
ax.xticks = ([nh ÷ 2, 3nh ÷ 2 + npad, 5nh ÷ 2 + 2npad], map(latexstring ∘ orientation_mark, 1:3))
# ax.xlabel = "Phase"
hidespines!(ax)
hidedecorations!(ax; ticks=false, ticklabels=false)
ax.yreversed = true

savefig(fig, FIG_NAME; hwratio=1, skip=[:vector])
