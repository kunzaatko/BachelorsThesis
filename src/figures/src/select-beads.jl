include("init.jl")

"""
    select_beads(img)

Show GUI to select beads from `img` and return their centers as an `Observable{Vector{Point2f}`.

# Arguments
- `img::Array`: Input image from which beads are to be selected.

# Returns
- `centers::Observable{Vector{Point2f}}`: Observable vector containing the centers of the selected beads.

"""
function select_beads(img)
    centers = Observable(Vector{Point2f}())
    fig = Makie.Figure()
    ax_im = Makie.Axis(fig[1, 1], aspect=DataAspect(), title=@lift string("Selected ", length($centers), " beads"))
    image!(ax_im, img; interpolate=false)
    scatter!(ax_im, centers; marker=:cross)

    new_center = Makie.select_point(ax_im.scene; marker=:cross)
    on(new_center) do c
        push!(centers[], c)
        notify(centers)
    end
    display(fig)

    return centers
end

