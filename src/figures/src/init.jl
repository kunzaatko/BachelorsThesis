# TODO: Move the preparation scripts into a separate directory <kunzaatko> 
include("prepare-data.jl")
include("makie.jl")

using MosaicViews
using FillArrays
using SIMIlluminationPatterns

function orientation_mark(ind)
    ind == 2 && return raw"0"
    ind == 3 ? "+" : "-"
end

function getbase(filename)
    return split(basename(filename)[5:end], ".")[1]
end

include("patch-inds.jl")
