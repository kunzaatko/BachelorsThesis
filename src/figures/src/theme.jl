# FIX: The Legend Block defines a Box that is too big and the figure looks non-efficient in space. This is impossible to
# fix using `rowgap!` <28-12-23> 
# FIX: Margin theme line widths are too wide <22-12-23> 
if !(isdefined(@__MODULE__, :LOADED_THEMES) && LOADED_THEMES)
    @info "Loading Makie themes..."
    const LOADED_THEMES = true
    using ColorSchemes
    using Unitful

    # FIX: Adjust font sizes <21-11-23> 
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

    const BASE_THEME = merge(
        Theme(
            pt_per_unit=1,
            figure_padding=2,
            Axis=(
                xgridvisible=false,
                ygridvisible=false,
                # spinewidth=1.1,
                # xminorticks=IntervalsBetween(5),
                # yminorticks=IntervalsBetween(5),
                # xlabelpadding=-2,
                # ylabelpadding=2,
                # xminortickwidth=0.75,
                # yminortickwidth=0.75,

                ## DEFAULT ##
                # xminorticksvisible=true,
                # yminorticksvisible=true,
                # xminortickalign=1,
                # yminortickalign=1,
                # xminorticksize=3,
                # yminorticksize=3,
            ),
            Lines=(;
                cycle=CYCLE
            ),
            Scatter=(
                cycle=CYCLE,
                markersize=MARKERSIZE,
                strokewidth=0,
            ),
            Legend=(
                nbanks=1,
                framevisible=false,
                tellwidth=false,
                tellheight=false,
            ),
            Image=(; interpolate=false),
            Heatmap=(;
                colormap=:Spectral
            )
        ),
        theme_latexfonts()
    )

    const RASTER_THEME = Theme()

    # FIX: How come the fonts are not transferred to `pdf_tex`? Does the SVG contain fonts or bitmapped fonts? <kunzaatko> 
    const VECTOR_THEME = Theme(
        # NOTE: `rasterize=10` is a hack that enables to save with CairoMakie
        # https://github.com/MakieOrg/Makie.jl/issues/1909 (makes the figures significantly larger) <16-11-23> 
        Image=(; rasterize=10)
    )

    const MARGIN_SIZE = 47.7u"mm" |> u"inch" |> ustrip
    const FULL_SIZE = 107u"mm" |> u"inch" |> ustrip

    function figsize(width_in_inch, height_width_ratio=HWRATIO)
        width_in_point = floor(Int, 72width_in_inch)
        height_in_point = floor(Int, width_in_point * height_width_ratio)
        return width_in_point, height_in_point
    end

    FULL_THEME = hwratio -> Theme(
        size=figsize(FULL_SIZE, hwratio),
        Axis=(
            xticklabelsize=10, yticklabelsize=10,
            xtickwidth=0.7, ytickwidth=0.7,
            xticksize=4, yticksize=4,
        ),
        Legend=(
            labelsize=10,
        ),
        Colorbar=(
            labelsize=10,
            ticklabelsize=10,
            leftspinevisible=false, rightspinevisible=false, topspinevisible=false, bottomspinevisible=false,
            width=5,
            # labelpadding=1.5,
            tickwidth=0.7,
            ticksize=4,
        )
    )
    # TODO: Add Axis3 to BASE_THEME and only change what is not same <22-12-23> 
    # TODO: Margin figures have too fat spine <20-11-23> 
    MARGIN_THEME = hwratio -> Theme(
        figure_padding=3,
        size=figsize(MARGIN_SIZE, hwratio),
        Axis=(
            spinewidth=0.5,
            titlesize=10,
            xticklabelsize=8, yticklabelsize=8,
            xlabelpadding=-1.5, ylabelpadding=1.5,
            xtickwidth=0.5, ytickwidth=0.5,
            xticksize=2.5, yticksize=2.5,
        ),
        Axis3=(
            titlesize=10,
            viewmode=:stretch,
            xspinewidth=0.5, yspinewidth=0.5, zspinewidth=0.5,
            xticklabelsize=8, yticklabelsize=8, zticklabelsize=8,
            xticklabelpad=2, yticklabelpad=2, zticklabelpad=2,
            xlabelpadding=0, ylabelpadding=0, zlabelpadding=0,
            xtickwidth=0.5, ytickwidth=0.5, ztickwidth=0.5,
            xticksize=2.5, yticksize=2.5, zticksize=2.5,
            xautolimitmargin=(0, 0), yautolimitmargin=(0, 0), zautolimitmargin=(0, 0),
            xgridvisible=false, ygridvisible=false, zgridvisible=false,
        ),
        Legend=(
            colgap=2,
            labelsize=8,
            padding=(0, 0, 0, 0),
            nbanks=4,
            patchsize=(10, 10)
        ),
        Hist=(
            normalization=:density,
            strokewidth=0.5
        ),
        Colorbar=(
            labelsize=8,
            width=3,
            leftspinevisible=false, rightspinevisible=false, topspinevisible=false, bottomspinevisible=false,
            ticklabelsize=8,
            # tellheight=false,
            labelpadding=1.5,
            tickwidth=0.5,
            ticksize=2.5,
            # spinewidth=0.5,
        ))

    # TODO: https://docs.makie.org/stable/how-to/save-figure-with-transparency/#glmakie <20-11-23> 
    const GL_THEME = Theme(
        figure_padding=3,
    )

    const CAIRO_THEME = Theme(
        px_per_unit=20,
        backgroundcolor=:transparent
    )

    const INTERACTIVE_THEME = merge(GL_THEME, FULL_THEME(1920 / 1080), BASE_THEME)

    include("override_themes.jl")

else
    @info "Skipping loading Makie themes"
end
