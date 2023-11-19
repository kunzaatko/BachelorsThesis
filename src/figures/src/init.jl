include("prepare-data.jl")
include("makie.jl")

using MosaicViews

function getbase(filename)
    return split(basename(filename)[5:end], ".")[1]
end
