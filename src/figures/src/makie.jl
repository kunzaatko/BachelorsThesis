using Makie, LaTeXStrings

include("theme.jl")
include("save-figure.jl")

function colorview_image_diff(base, new; red_constrast_multiplier=1.0, green_constrast_multiplier=1.0)
    local cv, chv = colorview, channelview
    @assert size(base) == size(new)
    cv(RGB, chv(red_constrast_multiplier .* base), chv(green_constrast_multiplier .* new), Zeros(size(new)))
end
