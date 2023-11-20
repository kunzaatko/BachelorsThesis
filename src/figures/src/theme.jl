# TODO: Theme MAKIE <16-11-23> 
using ColorSchemes

const ALPHA = 1.0
const COLOR_SCHEME = ColorSchemes.seaborn_deep.colors
const COLORS = @. RGBAf(
    red(COLOR_SCHEME),
    green(COLOR_SCHEME),
    blue(COLOR_SCHEME),
    ALPHA)
const LINESTYLES = [
    nothing,  # solid line
    :dash,
    :dot,
    :dashdot,
    :dashdotdot
]
const MARKERS = [
    :circle,
    :rect,
    :dtriangle,
    :utriangle,
    :cross,
    :diamond,
    :ltriangle,
    :rtriangle,
    :pentagon,
    :xcross,
    :hexagon
]
const MARKERSIZE = 7
const CYCLE = Cycle([:color, :marker], covary=true)
const HWRATIO = 0.68

axis_theme = (
    xlabelsize=10,
    ylabelsize=10,
    spinewidth=1.1,
    xticklabelsize=8,
    yticklabelsize=8,
    # xgridstyle=:dash, ygridstyle=:dash,
    xgridvisible=false,
    ygridvisible=false,
    xtickalign=1,
    ytickalign=1,
    xticksize=5,
    yticksize=5,
    xtickwidth=0.8,
    ytickwidth=0.8,
    xminorticksvisible=true,
    yminorticksvisible=true,
    xminortickalign=1,
    yminortickalign=1,
    xminorticks=IntervalsBetween(5),
    yminorticks=IntervalsBetween(5),
    xminorticksize=3,
    yminorticksize=3,
    xminortickwidth=0.75,
    yminortickwidth=0.75,
    xlabelpadding=-2,
    ylabelpadding=2,
)

line_theme = (;
    cycle=CYCLE
    # linewidth=1.5,  # Makie default is 1.5
)

scatter_theme = (
    cycle=CYCLE,
    markersize=MARKERSIZE,
    strokewidth=0,
)

legend_theme = (
    nbanks=1,
    framecolor=(:grey, 0.5),
    framevisible=false,
    labelsize=7.5,
    padding=(2, 2, 2, 2),
    margin=(0, 0, 0, 0),
    # position=:rt, # l=left, r=right, c=center; b=bottom, t=top, c=center
    rowgap=-10,
    colgap=4,
)

function figsize(width_in_inch, height_width_ratio=HWRATIO)
    width_in_point = floor(Int, 72width_in_inch)
    height_in_point = floor(Int, width_in_point * height_width_ratio)
    return width_in_point, height_in_point
end

# TODO: Margin figures have too fat spine <20-11-23> 
theme = Theme(
    figure_padding=3,
    # TODO: Should be computed from the size of the figure in the paper (1 point in CairoMakie is equal to 1/72 inch)
    # resolution=( ), 
    Axis=axis_theme,
    Lines=line_theme,
    Scatter=scatter_theme,
    Legend=legend_theme,
    # NOTE: `rasterize=10` is a hack that enables to save with CairoMakie
    # https://github.com/MakieOrg/Makie.jl/issues/1909 <16-11-23> 
    # FIX: Here `rasterize=10` makes the figures much larger... Maybe the images should be saved using GLMakie <16-11-23> 
    Image=(; interpolate=false, rasterize=10)
)

gl_theme = Theme(
    figure_padding=0,
    # TODO: Should be computed from the size of the figure in the paper (1 point in CairoMakie is equal to 1/72 inch)
    # resolution=( ), 
    Axis=axis_theme,
    # Lines=line_theme,
    # Scatter=scatter_theme,
    Legend=legend_theme,
    # NOTE: `rasterize=10` is a hack that enables to save with CairoMakie
    # https://github.com/MakieOrg/Makie.jl/issues/1909 <16-11-23> 
    # FIX: Here `rasterize=10` makes the figures much larger... Maybe the images should be saved using GLMakie <16-11-23> 
    Image=(; interpolate=false, rasterize=10)
)
Makie.set_theme!(merge(theme, theme_latexfonts()))
