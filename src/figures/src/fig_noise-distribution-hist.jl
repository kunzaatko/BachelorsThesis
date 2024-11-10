include("init.jl")
using Distributions, SpecialFunctions, StatsBase, Polynomials

const FIG_NAME = getbase(@__FILE__)

otsu = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/otsu.ser"))

l_w_bg_img = LR_beads_sum_noscale .* otsu[:l_w_bg] .|> gray
l_w_fg_img = LR_beads_sum_noscale .* otsu[:l_w_fg] .|> gray

bg_data = l_w_bg_img[otsu[:l_w_bg]]
fg_data = l_w_fg_img[otsu[:l_w_fg]]

bg_mean_img = mapwindow(l_w_bg_img, (21, 21)) do w
    mean(skipmissing(w))
end

gt_data = bg_mean_img[otsu[:l_w_bg]]

function fig_mean_bg()
    fig = Figure()
    ax_bg, ax_img = Makie.Axis(fig[1, 1]), Makie.Axis(fig[1, 2])
    linkaxes!(ax_bg, ax_img)
    image!(ax_bg, bg_mean_img)
    image!(ax_img, LR_beads_sum)
    DataInspector(fig)
    fig
end

function fig_ambient_light()
    fig = Figure()
    ax = Makie.Axis(fig[1, 1])
    im = image!(ax, bg_mean_img)
    cb = Colorbar(fig[1, 2], im)
    cb.leftspinevisible = cb.rightspinevisible = false
    cb.tellheight = false
    colgap!(fig.layout, Relative(0.04))
    fig
end
savefig(fig_ambient_light, "ambient-light"; hwratio=0.9, skip=[:vector, :full], override_theme=merge(NO_TICKS, NO_SPINE, NO_TICKLABELS, DATA_ASPECT))

function fig_noise_hist_bg_mean()
    bg_data_demean = bg_data .- gt_data
    fig, ax, _ = hist(bg_data_demean; bins=50, normalization=:pdf)
    ylims!(ax, (0, 70))
    ax.yticksvisible = false
    ax.yticklabelsvisible = false
    xlims!(ax, (-0.002, 0.032))
    DataInspector(fig)
    fig
end
savefig(fig_noise_hist_bg_mean, FIG_NAME * "-demeaned")

function estimate_noise_params(s_img, gt_img)
    s_k2 = cumulant(s_img, 2)
    s_k3 = cumulant(s_img, 3)

    gt_mean = mean(gt_img)
    gt_mean_sr = gt_mean^2
    gt_sr_mean = mean(gt_img .^ 2)
    gt_mean_cb = gt_mean^3
    gt_cb_mean = mean(gt_img .^ 3)

    poly = Polynomial([
        gt_cb_mean - 3 * gt_sr_mean * gt_mean + 2 * gt_mean_cb - s_k3,
        3 * gt_sr_mean - 3 * gt_mean_sr,
        gt_mean
    ])
    rs = roots(poly)

    a = 1 ./ rs[rs.>0]
    @assert length(a) > 0 "No possitive roots found"

    a = a[1]
    b_sr = s_k2 - gt_sr_mean + gt_mean_sr - gt_mean / a

    return (a, b_sr > 0 ? sqrt(b_sr) : 0)
end

noise_params = estimate_noise_params(bg_data, gt_data)
a, b = noise_params

pois_nois_dist(a, intens) = x -> smooth_poiss(BigFloat(a * x); λ=a * intens)
avg_pois_nois_dist = pois_nois_dist(a, mean(gt_data))

function fig_poisson_gaussian_mean_gt_dist()
    fig = Figure()
    ax = Makie.Axis(fig[1, 1])
    xs = range(0, 0.025; length=1_000)

    lines!(ax, xs, avg_pois_nois_dist)

    DataInspector()
    fig
end

function fig_clip_hist_noise(gt_clip=(0.9 * mean(gt_data), 1.1 * mean(gt_data)), bins=20, show_model=true)
    min_gt, max_gt = gt_clip
    center = 0.5 * (min_gt + max_gt)
    fig, ax, _ = hist(bg_data[min_gt.<gt_data.<max_gt] .- gt_data[min_gt.<gt_data.<max_gt]; bins, normalization=:probability)
    if show_model
        xs = range(0, 0.03; length=1_000)
        lines!(ax, xs, pois_nois_dist(a, center))
    end
    DataInspector(fig)
    fig
end

# TODO: Do MLE of the noise model from the paper... This is shit! Why does it not fucking work! <29-12-23> 
