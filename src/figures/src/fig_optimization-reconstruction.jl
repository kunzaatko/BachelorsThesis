include("init.jl")
const FIG_NAME = getbase(@__FILE__)

######################
### Reconstruction ###
######################

# reg = :tv, :gr
function fig_optimization(reg=:gr, tf=:model)
    s = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/$(reg)_reconstruction_$(tf).ser"))
    # s_out_model .*= 3
    f = fft(s)

    fig = Figure()
    s_ax, f_ax = Makie.Axis(fig[1, 1]), Makie.Axis(fig[1, 2])
    colgap!(fig.layout, Relative(0.07))

    s_ax.xticksvisible = s_ax.yticksvisible = s_ax.yticklabelsvisible = s_ax.xticklabelsvisible = false
    f_center_x, f_center_y = size(f) ./ 2 .+ 0.5
    f_ax.xticks, f_ax.yticks = ([f_center_x], [L"0"]), ([f_center_y], [L"0"])

    image!(s_ax, match_hist(s))
    image!(f_ax, log2.(abs.(fftshift(f)) .+ 1))

    linesegments!(f_ax, [size(f, 1), 0, f_center_x, f_center_x], [f_center_y, f_center_y, size(f, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)

    return fig
end

savefig(fig_optimization, FIG_NAME * "-GR_0_05"; hwratio=0.5, skip=[:vector], override_theme=merge(NO_SPINE, DATA_ASPECT), fig_function_args=(:gr,))
savefig(fig_optimization, FIG_NAME * "-TV_0_05"; hwratio=0.5, skip=[:vector], override_theme=merge(NO_SPINE, DATA_ASPECT), fig_function_args=(:tv,))

function fig_optimization_both()
    s_gr = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/gr_reconstruction_model.ser"))
    s_tv = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/tv_reconstruction_model.ser"))
    s_gr .*= 3
    s_tv .*= 3
    f_gr, f_tv = fft(s_gr), fft(s_tv)

    fig = Figure()
    s_ax_tv, f_ax_tv = Makie.Axis(fig[1, 1]), Makie.Axis(fig[1, 2])
    s_ax_gr, f_ax_gr = Makie.Axis(fig[2, 1]), Makie.Axis(fig[2, 2])
    colgap!(fig.layout, Relative(0.02))
    rowgap!(fig.layout, Relative(0.02))

    linkaxes!(s_ax_tv, s_ax_gr)
    linkaxes!(f_ax_tv, f_ax_gr)

    s_ax_tv.xticksvisible = s_ax_tv.xticklabelsvisible = false
    s_ax_gr.xticksvisible = s_ax_gr.xticklabelsvisible = false
    # s_ax_tv.yticksvisible = s_ax_tv.yticklabelsvisible = false
    # s_ax_gr.yticksvisible = s_ax_gr.yticklabelsvisible = false
    f_center_x_tv, f_center_y_tv = size(f_tv) ./ 2 .+ 0.5
    f_center_x_gr, f_center_y_gr = size(f_gr) ./ 2 .+ 0.5
    s_center_y_tv, s_center_y_gr = (size(s_tv) ./ 2 .+ 0.5)[2],(size(s_gr) ./ 2 .+ 0.5)[2]
    f_ax_tv.xticks, f_ax_tv.yticks = ([f_center_x_tv], [L"0"]), ([f_center_y_tv], [L"0"])
    f_ax_gr.xticks, f_ax_gr.yticks = ([f_center_x_gr], [L"0"]), ([f_center_y_gr], [L"0"])
    s_ax_tv.yticks, s_ax_gr.yticks = ([s_center_y_tv], [L"\text{TV}"]), ([s_center_y_gr], [L"\text{GR}"])

    image!(s_ax_tv, match_hist(s_tv))
    image!(f_ax_tv, log2.(abs.(fftshift(f_tv)) .+ 1))
    image!(s_ax_gr, match_hist(s_gr))
    image!(f_ax_gr, log2.(abs.(fftshift(f_gr)) .+ 1))

    linesegments!(f_ax_tv, [size(f_tv, 1), 0, f_center_x_tv, f_center_x_tv], [f_center_y_tv, f_center_y_tv, size(f_tv, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)
    linesegments!(f_ax_gr, [size(f_gr, 1), 0, f_center_x_gr, f_center_x_gr], [f_center_y_gr, f_center_y_gr, size(f_gr, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)

    return fig
end

savefig(fig_optimization_both, FIG_NAME * "-both"; hwratio=0.9, skip=[:vector], override_theme=merge(NO_SPINE, DATA_ASPECT))

function fig_compare_regularization()
    fig = Figure()
    ax_tv, ax_gr = Makie.Axis(fig[1, 1]), Makie.Axis(fig[2, 1]); linkaxes!(ax_tv, ax_gr)

    s_gr = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/gr_reconstruction_model.ser")); s_gr = scaleminmax(extrema(s_gr)...).(s_gr)
    s_tv = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/tv_reconstruction_model.ser")); s_tv = scaleminmax(extrema(s_tv)...).(s_tv)

    xlims, ylims = HR_comparison_lims
    xinds_LR, yinds_LR = (first(xlims)÷2):(last(xlims)÷2), (first(ylims)÷2):(last(ylims)÷2)
    ax_tv.title = L"\hat{s}_\text{TV}"
    image!(ax_tv, match_hist(s_tv; match_img=LR_beads_sum[yinds_LR, xinds_LR]))

    ax_gr.title = L"\hat{s}_\text{GR}"
    image!(ax_gr, match_hist(s_gr; match_img=LR_beads_sum[yinds_LR, xinds_LR]))

    xticks, yticks = tick_locations((xlims, ylims), 0.1)
    ax_tv.xticks = ax_gr.xticks = xticks
    ax_tv.yticks = ax_gr.yticks = yticks
    limits!(ax_tv, xlims, ylims)

    rowgap!(fig.layout, Relative(0.04))
    return fig
end

savefig(fig_compare_regularization, FIG_NAME * "-compare-regularization"; hwratio=1.9, skip=[:full, :vector], override_theme=merge(FORMAT_TICKS, MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT))

# TODO: Figure compare the optimization reconstructions under different λ settings <22-12-23> 
# TODO: Comparison of different of 3 image reconstruction and 9 image reconstruction <22-12-23> 
# tf = :measured, :model
# regularizer = :tv, :gr
function fig_compare_regularization(regularizer, tf, λs; ncols=3, nrows=1)
    s_λs_dict = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/$(regularizer)_reconstructions_$(tf)_lambda.ser"))
    s_λs = [s_λs_dict[λ] for λ in λs]

    fig = Figure()
    axes = [Makie.Axis(fig[i, j]) for i in 1:nrows, j in 1:ncols]
    linkaxes!(axes...)

    for (s, ax, λ) in zip(s_λs, permutedims(axes, (2, 1)), λs)
        image!(ax, match_hist(s))
        ax.title = latexstring(raw"\lambda = " * "$λ")
    end
    fig
end


function fig_3LR_vs_9LR(reg=:gr, tf=:model)
    fig = Figure()
    ax_3, ax_9 = Makie.Axis(fig[1, 1]), Makie.Axis(fig[2, 1]); linkaxes!(ax_3, ax_9)

    s_3 = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/$(reg)_reconstruction_$(tf)_3.ser")); s_3 = scaleminmax(extrema(s_3)...).(s_3)
    s_9 = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/$(reg)_reconstruction_$(tf).ser")); s_9 = scaleminmax(extrema(s_9)...).(s_9)

    xlims, ylims = HR_comparison_lims
    xinds_LR, yinds_LR = (first(xlims)÷2):(last(xlims)÷2), (first(ylims)÷2):(last(ylims)÷2)
    ax_3.title = L"\hat{s}_\text{3LR}"
    image!(ax_3, match_hist(s_3; match_img=LR_beads_sum[xinds_LR, yinds_LR]))

    ax_9.title = L"\hat{s}_\text{9LR}"
    image!(ax_9, match_hist(s_9; match_img=LR_beads_sum[xinds_LR, yinds_LR]))

    xticks, yticks = tick_locations((xlims, ylims), 0.1)
    ax_3.xticks = ax_9.xticks = xticks
    ax_3.yticks = ax_9.yticks = yticks
    limits!(ax_3, xlims, ylims)

    rowgap!(fig.layout, Relative(0.04))
    fig
end

savefig(fig_3LR_vs_9LR, FIG_NAME * "-3LR-vs-9LR"; hwratio=1.9, skip=[:vector, :full], override_theme=merge(FORMAT_TICKS, MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT))
