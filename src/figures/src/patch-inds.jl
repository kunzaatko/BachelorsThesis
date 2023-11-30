"""
    patch_inds(patch::String; imsize=(1024, 1024), grid=5)

Generate the indices of a patch within an image grid.

# Arguments
- `patch::String`: identifier of the patch (patch ∈ {TL, TC, TR, CL, CC, CR, BL, BC, BR})
- `imsize::Tuple{Int, Int}`: The size of the image (width, height).
- `grid::Int`: The number of grid divisions along each dimension.

# Example
```julia
patch_inds("CC")
```
"""
function patch_inds(patch::String; imsize=(1024, 1024), grid=4.5)
    Δx, Δy = map(xy -> div(xy, grid), imsize)
    caller = ["BL" "BC" "BR"
        "CL" "CC" "CR"
        "TL" "TC" "TR"]
    inds = map([(i, j) for i in [Δx / 2, imsize[1] / 2 - 1, imsize[1] - Δx / 2 - 1], j in [Δy / 2, imsize[2] / 2 - 1, imsize[2] - Δy / 2 - 1]]) do (i, j)
        UnitRange{Int64}(ceil(i - Δx / 2 + 1), floor(i + Δx / 2 + 1)), UnitRange{Int64}(ceil(j - Δy / 2 + 1), floor(j + Δy / 2 + 1))
    end

    ij = findfirst(caller .== patch)
    ij = isnothing(ij) ? findfirst(caller .== reverse(patch)) : ij
    return inds[ij]
end
