@info "Loading override themes..."

function format_ticks(ticks)
    if ticks isa Vector{<:Real}
        if all(isinteger, ticks)
            return latexstring.(Int64.(ticks))
        else
            return latexstring.(ticks)

        end
    else
        return ticks
    end
end

const FORMAT_TICKS = Theme(
    Axis=(;
        xtickformat=format_ticks,
        ytickformat=format_ticks
    )
)
const NO_SPINE = Theme(
    Axis=(;
        topspinevisible=false,
        rightspinevisible=false,
        leftspinevisible=false,
        bottomspinevisible=false
    )
)
const TINY_TICKLABELS = Theme(
    Axis=(;
        xticklabelsize=5,
        yticklabelsize=5,
        xticklabelpad=1,
        yticklabelpad=1
        # xticklabelalign=(:center, :top),
        # yticklabelalign=(:right, :center)
    )
)
const TINY_TICKS = Theme(
    Axis=(;
        xticksize=1,
        yticksize=1,
        xtickwidth=0.2,
        ytickwidth=0.2
    )
)

const ROTATE_LABELS = Theme(
    Axis=(
        xticklabelrotation=π / 4,
        yticklabelrotation=π / 4
    )
)

const NO_TICKS = Theme(
    Axis=(
        # xticksize=0,
        # yticksize=0,
        # xtickwidth=0,
        # ytickwidth=0,
        xticksvisible=false,
        yticksvisible=false,
    )
)

# TODO: These override themes should be defined for Axis3 also <28-12-23> 

const NO_TICKLABELS = Theme(
    Axis=(
        xticklabelsvisible=false,
        yticklabelsvisible=false,
        xticksvisible=false,
        yticksvisible=false,
    )
)

const DATA_ASPECT = Theme(
    Axis=(
        aspect=DataAspect(),
    )
)

const FIGURE_PAD = Theme(
    figure_padding=6
)
const MARGIN_PX_TICKS = merge(TINY_TICKLABELS, NO_TICKS)

const ORANGE_TITLE = Theme(
    Axis=(
        titlecolor=:orange,
    )
)
