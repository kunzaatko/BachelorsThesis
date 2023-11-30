include("init.jl")
using PSFDistiller
using PSFDistiller: Median

"""
    estimate_PSF_averaging(img, patch; varargs...)

Estimates the point spread function (PSF) by averaging multiple measurements.

Arguments:
- img: The input image
- patch: The patch used for estimation
- varargs: Optional keyword arguments

Returns:
- psf: The estimated point spread function
- positions: The positions of the beads used for estimation
- rois: The regions of interest (ROIs) used for estimation
"""
function estimate_PSF_averaging(img, patch; varargs...)
    img = img[1] isa Colorant ? gray.(img) : img
    positions, _ = get_selected_beads(patch)
    psf, rois, positions, selected, params, fwd = distille_PSF(img; positions, force_align=true, bg_alg=Median(), varargs...)
    serialize("data/psf_averaging_$(patch).ser", Dict(
        :psf => psf,
        :rois => rois,
        :positions => positions,
        :selected => selected,
        :params => params,
        :fwd => fwd
    ))
    return psf, positions, rois
end
