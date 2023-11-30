include("select-beads.jl")

"""
    select_beads_patch(img, patch)

Show GUI to select beads within a specified patch of an image.

# Arguments
- `img::Array`: Input image.
- `patch::String`: The patch from which beads need to be selected.

# Returns
A function that when called as `func()` saves the serialized selected beads with the patch identifier in the filename.
"""
function select_beads_patch(img, patch)
    global inds = patch_inds(patch; imsize=size(img))

    img_patch = img[inds...]
    global centers = select_beads(img_patch)

    @info "Saving the selection is done by calling the function that is returned..."
    function save_selection(; adjust::Union{Bool,AbstractVector{Int64}}=true)
        global centers
        global inds
        centers_save = centers[]
        centers_save = map(c -> c .+ [0.5, 0.5] .+ [(first.(inds) .- 1)...], centers_save)
        @info "Saving the selection..."
        serialize("data/selected_beads_$(patch).ser", centers_save)
        serialize("data/selected_beads_$(patch)_Point2f.ser", Point2f.(centers_save))
    end
    return save_selection
end
