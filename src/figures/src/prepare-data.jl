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

    LR_ccp = load(joinpath(abspath(dirname(@__FILE__)), "data/SIM_ccp_LR.tiff"); verbose=false)
    LR_ccp_sum = dropdims(sum(LR_ccp, dims=3); dims=3)
    LR_ccp_sum_noscale = LR_ccp_sum
    LR_ccp_sum = scaleminmax(extrema(LR_ccp_sum)...).(LR_ccp_sum)
    LR_ccp = scaleminmax(extrema(LR_ccp)...).(LR_ccp)
    LR_ccp = map(collect, eachslice(LR_ccp; dims=3))

    LR_ccp2 = load(joinpath(abspath(dirname(@__FILE__)), "data/Cell_02.tif"); verbose=false)
    LR_ccp2_sum = dropdims(sum(LR_ccp2, dims=3); dims=3)
    LR_ccp2_sum_noscale = LR_ccp2_sum
    LR_ccp2_sum = scaleminmax(extrema(LR_ccp2_sum)...).(LR_ccp2_sum)
    LR_ccp2 = scaleminmax(extrema(LR_ccp2)...).(LR_ccp2)
    LR_ccp2 = map(collect, eachslice(LR_ccp2; dims=3))

    LR_ccp3 = load(joinpath(abspath(dirname(@__FILE__)), "data/Cell_03.tif"); verbose=false)[:, :, 1:9]
    LR_ccp3_sum = dropdims(sum(LR_ccp3, dims=3); dims=3)
    LR_ccp3_sum_noscale = LR_ccp3_sum
    LR_ccp3_sum = scaleminmax(extrema(LR_ccp3_sum)...).(LR_ccp3_sum)
    LR_ccp3 = scaleminmax(extrema(LR_ccp3)...).(LR_ccp3)
    LR_ccp3 = map(collect, eachslice(LR_ccp3; dims=3))

    LR_actin = load(joinpath(abspath(dirname(@__FILE__)), "data/Zeiss_Actin_525nm_crop.tif"); verbose=false)[:, :, 1] .|> gray
else
    @info "Skipping loading images..."
end
if !(isdefined(@__MODULE__, :NONIMAGE_DATA_LOADED) && NONIMAGE_DATA_LOADED)
    @info "Loading serialized data..."
    const NONIMAGE_DATA_LOADED = true
    const LR_beads_Δxy = 30.5u"nm" * 2
    const HR_beads_Δxy = 30.5u"nm"

    const IP_params = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/IP_params.ser"))
    const IP_params_ccp = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/IP_params_ccp.ser"))
    const IP_params_ccp2 = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/IP_params_ccp2.ser"))
    const IP_params_ccp3 = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/IP_params_ccp3.ser"))

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

