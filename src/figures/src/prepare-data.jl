using Images, Serialization
using Unitful

if !isdefined(@__MODULE__, :SKIP_PREPARE_IMAGES)
    LR_beads = load(joinpath(abspath(dirname(@__FILE__)), "data/SIM_beads_LR.tiff"); verbose=false)
    LR_beads_sum = dropdims(sum(LR_beads, dims=3); dims=3)
    LR_beads_sum = scaleminmax(extrema(LR_beads_sum)...).(LR_beads_sum)
    LR_beads = scaleminmax(extrema(LR_beads)...).(LR_beads)
    HR_beads = load(joinpath(abspath(dirname(@__FILE__)), "data/SIM_beads_HR.tiff"); verbose=false)
end
const LR_beads_Δxy = 30.5u"nm" * 2
const HR_beads_Δxy = 30.5u"nm"

const IP_params = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/IP_params.ser"))
