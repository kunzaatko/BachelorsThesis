include("init.jl")
using ImageBinarization, Interpolations

otsu_thresh = find_threshold(LR_beads_sum, Otsu())
otsu_thresh_a = fill(otsu_thresh, size(LR_beads_sum)...)
w_otsu_thresh_a = mapwindow(LR_beads_sum, (71, 71), indices=(1:2:512, 1:2:512)) do A
    find_threshold(A, Otsu())
end
w_otsu_thresh_a = imresize(w_otsu_thresh_a, size(LR_beads_sum), method=Constant())
# lower_by = 0.07
# l_otsu_thresh_a = otsu_thresh_a .- lower_by
# l_w_otsu_thresh_a = w_otsu_thresh_a .- lower_by

lower_by = 0.3
l_otsu_thresh_a = otsu_thresh_a .* lower_by
l_w_otsu_thresh_a = w_otsu_thresh_a .* lower_by

fg_otsu = binarize(LR_beads_sum, Otsu()) .|> gray .|> Bool
l_fg_otsu = LR_beads_sum .> l_otsu_thresh_a
w_fg_otsu = LR_beads_sum .> w_otsu_thresh_a
l_w_fg_otsu = LR_beads_sum .> l_w_otsu_thresh_a

otsu = Dict(
    :thresh => otsu_thresh_a,
    :w_thresh => w_otsu_thresh_a,
    :lower_by => lower_by,
    :l_thresh => l_otsu_thresh_a,
    :l_w_thresh => l_w_otsu_thresh_a,
    :fg => fg_otsu,
    :bg => fg_otsu .== 0,
    :l_fg => l_fg_otsu,
    :l_bg => l_fg_otsu .== 0,
    :w_fg => w_fg_otsu,
    :w_bg => w_fg_otsu .== 0,
    :l_w_fg => l_w_fg_otsu,
    :l_w_bg => l_w_fg_otsu .== 0
)

serialize("data/otsu.ser", otsu)
