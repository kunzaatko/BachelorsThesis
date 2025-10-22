include("init.jl")

const FIG_NAME = getbase(@__FILE__)

function fig_compare_model_ccp_and_beads_fft()
    fig = Figure()
    f_out_ccp = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/fourier_weiner_reconstruction_model_ccp.ser"))
    f_out_beads = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/fourier_weiner_reconstruction_model.ser"))
    ax_ccp, ax_beads = Makie.Axis(fig[1, 2], title=L"\hat{S}_\text{ccp}", titlecolor=:orange), Makie.Axis(fig[1, 1], title=L"\hat{S}_\text{beads}", titlecolor=:orange)
    image!(ax_ccp, fftshift(log2.(abs.(f_out_ccp) .+ 1)))
    image!(ax_beads, fftshift(log2.(abs.(f_out_beads) .+ 1)))

    center_x, center_y = size(f_out_ccp) ./ 2 .+ 0.5
    ax_ccp.xticks, ax_ccp.yticks = ([center_x], [L"0"]), ([center_y], [L"0"])
    ax_beads.xticks, ax_beads.yticks = ([center_x], [L"0"]), ([center_y], [L"0"])
    ax_beads.xticklabelsvisible = ax_beads.yticklabelsvisible = ax_ccp.xticklabelsvisible = ax_ccp.yticklabelsvisible = true
    ax_beads.xticksvisible = ax_beads.yticksvisible = ax_ccp.xticksvisible = ax_ccp.yticksvisible = true
    linesegments!(ax_ccp, [size(f_out_ccp, 1), 0, center_x, center_x], [center_y, center_y, size(f_out_ccp, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)
    linesegments!(ax_beads, [size(f_out_ccp, 1), 0, center_x, center_x], [center_y, center_y, size(f_out_ccp, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)

    linkaxes!(ax_ccp, ax_beads)
    fig
end

savefig(fig_compare_model_ccp_and_beads_fft, FIG_NAME * "-model-ccp-and-beads-fft"; hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT), update=true)
