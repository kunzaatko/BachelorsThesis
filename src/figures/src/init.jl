# TODO: Move the preparation scripts into a separate directory <kunzaatko> 
include("prepare-data.jl")
include("makie.jl")

using MosaicViews
using FillArrays
using SIMIlluminationPatterns
using TransferFunctions
using DeconvOptim
using FFTW
using FourierTools
using Unitful: Length

function orientation_mark(ind)
    ind == 2 && return raw"0"
    ind == 3 ? "+" : "-"
end

function getbase(filename)
    return split(basename(filename)[5:end], ".")[1]
end

function match_hist(img; nbins=256 * 8, match_img=LR_beads_sum)
    return adjust_histogram(img, Matching(targetimg=match_img; nbins))
end

smooth_poiss(x; λ) = exp(-λ) * λ^x / gamma(x + 1)

include("patch-inds.jl")

# TODO: This should be set in a manner that it should allow multiple dimensions and the dimensions should be possible to
# set independently <kunzaatko> 
# TODO: Implement `full_lims` <31-12-23> 
function tick_locations(patch_lims, pad_ρ; patch_nticks=3, full_lims=patch_lims)
    xlims, ylims = patch_lims
    xticks = round.(Int, range((xlims .+ Base.:-(xlims...) .* (-pad_ρ, pad_ρ))..., length=patch_nticks))
    yticks = round.(Int, range((ylims .+ Base.:-(ylims...) .* (-pad_ρ, pad_ρ))..., length=patch_nticks))

    return xticks, yticks
end
