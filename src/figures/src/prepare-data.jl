using Images

LR_beads = load(joinpath(abspath(dirname(@__FILE__)), "data/SIM_beads_LR.tiff"))
LR_beads_sum = dropdims(sum(LR_beads, dims=3); dims=3)
LR_beads_sum = scaleminmax(extrema(LR_beads_sum)...).(LR_beads_sum)
LR_beads = scaleminmax(extrema(LR_beads)...).(LR_beads)
HR_beads = load(joinpath(abspath(dirname(@__FILE__)), "data/SIM_beads_HR.tiff"))
