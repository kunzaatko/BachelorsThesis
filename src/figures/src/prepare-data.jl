using Images, Serialization
using Unitful

if !(isdefined(@__MODULE__, :SKIP_PREPARE_IMAGES) && SKIP_PREPARE_IMAGES)
    @info "Loading images..."
    const SKIP_PREPARE_IMAGES = true
    LR_beads = load(joinpath(abspath(dirname(@__FILE__)), "data/SIM_beads_LR.tiff"); verbose=false)
    LR_beads_sum = dropdims(sum(LR_beads, dims=3); dims=3)
    LR_beads_sum_noscale = LR_beads_sum
    LR_beads_sum = scaleminmax(extrema(LR_beads_sum)...).(LR_beads_sum)
    LR_beads = scaleminmax(extrema(LR_beads)...).(LR_beads)
    LR_beads = map(collect, eachslice(LR_beads; dims=3))
    HR_beads = load(joinpath(abspath(dirname(@__FILE__)), "data/SIM_beads_HR.tiff"); verbose=false)
    HR_beads = scaleminmax(extrema(HR_beads)...).(HR_beads)
else
    @info "Skipping loading images..."
end
if !(isdefined(@__MODULE__, :NONIMAGE_DATA_LOADED) && NONIMAGE_DATA_LOADED)
    @info "Loading serialized data..."
    const NONIMAGE_DATA_LOADED = true
    const LR_beads_Δxy = 30.5u"nm" * 2
    const HR_beads_Δxy = 30.5u"nm"

    const IP_params = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/IP_params.ser"))

    function get_selected_beads(patch)
        point2f = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/selected_beads_$(patch)_Point2f.ser"))
        vec = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/selected_beads_$(patch).ser"))
        return vec, point2f
    end

    function get_psf_averaged_estimate(patch)
        return deserialize(joinpath(abspath(dirname(@__FILE__)), "data/psf_averaging_$(patch).ser"))
    end

    const HR_comparison_lims = ((242, 320), (342, 418))
else
    @info "Skipping loading serialized data"
end

