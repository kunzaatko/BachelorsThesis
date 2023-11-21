using ImageBinarization

include("init.jl")

otsu_thresh = find_threshold(LR_beads_sum, Otsu())
fg_otsu = binarize(LR_beads_sum, Otsu())

lower_by = Observable(0.07)
fg_otsu_lowered = @lift LR_beads_sum .> (otsu_thresh - $lower_by)
