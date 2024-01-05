include("init.jl")
using Interpolations, DataFrames

const FIG_NAME = getbase(@__FILE__)

function fig_bead_models_LR_HR(orientation=:vert)
    LR_bead = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/LR_bead.ser")).parent
    HR_bead = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/HR_bead.ser")).parent
    # HR_bead = imresize(HR_bead, 2 .* size(HR_bead), method=Constant())
    # LR_bead = imresize(LR_bead, size(HR_bead), method=Constant())
    fig = Figure()
    ax_LR, ax_HR = Makie.Axis(fig[1, 1], title=L"m_\text{LR}"), Makie.Axis(fig[orientation == :vert ? 2 : 1, orientation == :vert ? 1 : 2], title=L"m_\text{HR}")
    # linkaxes!(ax_LR, ax_HR)
    image!(ax_LR, LR_bead)
    image!(ax_HR, HR_bead)
    rowgap!(fig.layout, Relative(0.04))
    colgap!(fig.layout, Relative(0.04))
    fig
end

savefig(fig_bead_models_LR_HR, FIG_NAME * "-single-bead"; hwratio=1.9, skip=[:vector, :full], override_theme=merge(NO_TICKS, NO_TICKLABELS, NO_SPINE, DATA_ASPECT), fig_function_args=(orientation=:vert,))
savefig(fig_bead_models_LR_HR, FIG_NAME * "-single-bead"; hwratio=0.5, skip=[:vector, :margin], override_theme=merge(NO_TICKS, NO_TICKLABELS, NO_SPINE, DATA_ASPECT), fig_function_args=(orientation=:horiz,))


ccorr = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/ccorr.ser"))

function fig_ccorr()
    fig = Figure()
    ax = Makie.Axis(fig[1, 1], title=L"\mathcal{C}_{m_{\text{HR}} \times \hat{s}}")

    plt = heatmap!(ax, ccorr, colormap=:Spectral)
    cb = Colorbar(fig[1, 2], plt)
    cb.leftspinevisible = cb.rightspinevisible = false

    xlims, ylims = (330, 520), (490, 680)
    limits!(ax, xlims, ylims)
    ax.xticks, ax.yticks = tick_locations((xlims, ylims), 0.1)

    colgap!(fig.layout, Relative(0.04))

    return fig
end
savefig(fig_ccorr, FIG_NAME * "-ccorr"; skip=[:vector], hwratio=0.9, override_theme=merge(MARGIN_PX_TICKS, FORMAT_TICKS, NO_SPINE, DATA_ASPECT))

ccorr_threshed = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/ccorr-thresh.ser"))
wide_threshed = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/wide-thresh.ser"))
narrow_threshed = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/narrow-thresh.ser"))

HR_img = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/spatial_weiner_reconstruction_model.ser")) .|> real
HR_img = scaleminmax(extrema(HR_img)...).(HR_img)

function fig_discarded(passed=ccorr_threshed, title=L"\mathcal{C}_{m_{\text{HR}} \times \hat{s}} > \alpha", lims=((295, 510), (345, 560)))
    fig = Figure()
    ax = Makie.Axis(fig[1, 1]; title)
    xlims, ylims = lims
    color_diff = colorview_image_diff(HR_img .* (passed .== false), HR_img .* passed)
    image!(ax, adjust_histogram(color_diff, LinearStretching()))
    ax.xticks, ax.yticks = tick_locations(lims, 0.1)
    limits!(ax, xlims, ylims)
    DataInspector(fig)
    fig
end

savefig(fig_discarded, FIG_NAME * "-ccorr-discarded"; skip=[:vector, :full], hwratio=1.1, override_theme=merge(MARGIN_PX_TICKS, FORMAT_TICKS, NO_SPINE, DATA_ASPECT), fig_function_args=(passed=ccorr_threshed, title=L"(\mathcal{C}_{m_{\text{HR}} \times \hat{s}}) > \alpha", lims=((295, 510), (345, 560))))
savefig(fig_discarded, FIG_NAME * "-wide-mean-discarded"; skip=[:vector, :full], hwratio=1.1, override_theme=merge(MARGIN_PX_TICKS, FORMAT_TICKS, NO_SPINE, DATA_ASPECT), fig_function_args=(passed=wide_threshed, title=L"\hat{s} > \beta_{\text{W}} \cdot \hat{s}_{\text{W}}", lims=((725, 1000), (0, 275))))
savefig(fig_discarded, FIG_NAME * "-narrow-mean-discarded"; skip=[:vector, :full], hwratio=1.1, override_theme=merge(MARGIN_PX_TICKS, FORMAT_TICKS, NO_SPINE, DATA_ASPECT), fig_function_args=(passed=narrow_threshed, title=L"\hat{s} > \beta_{\text{n}} \cdot \hat{s}_{\text{n}}", lims=((238, 295), (353, 410))))

function fig_gaussian_fits_sum(orientation=:vert, lims=((610, 940), (580, 910)))
    gauss_dict = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/gaussian_sum_model.ser"))
    filtered = gauss_dict[:filtered]
    bead_fits_df = gauss_dict[:bead_fits_df]
    bead_fits_df_s = gauss_dict[:bead_fits_df_s]
    beads_fit_data_s = gauss_dict[:bead_fit_data_s]
    bead_centers_s = gauss_dict[:bead_centers_s]
    # bead_fits_df_f = gauss_dict[:bead_fits_df_f]

    fig = Figure()
    ax_HR = Makie.Axis(fig[1, 1], title=L"\hat{s}")
    ax_m = Makie.Axis(fig[orientation == :vert ? 2 : 1, orientation == :vert ? 1 : 2], title=L"\hat{s}_{\Sigma}")
    linkaxes!(ax_m, ax_HR)

    image!(ax_HR, HR_img)

    scatter!(ax_HR, getindex.(bead_fits_df[!, :μ], 1) .- 1 / 2, getindex.(bead_fits_df[!, :μ], 2) .- 1 / 2;
        # markersize=7,
        markerspace=:data,
        color=map(c -> c ? :red : :green, filtered),
        markersize=map(c -> c ? 7 : 4, filtered),
        # alpha=0.6
        alpha=0.3
    )
    function gaussian_model(size, μ)
        xs, ys = (1:size[1]) * ones(size[2])' .- μ[1], ones(size[1]) * (1:size[2])' .- μ[2]
        return (I_0, I, Δx, Δy, σ²) -> @. I_0 + I * exp(-((xs - Δx)^2 + (ys - Δy)^2) / 2σ²)
    end
    fit_buf = zeros(size(HR_img))
    for (inds, fit, c) in zip(map(x -> x[3], beads_fit_data_s), eachrow(bead_fits_df_s), bead_centers_s)
        gauss = gaussian_model(length.(inds), fit[:μ_rel])
        fit_buf[inds...] .+= gauss(fit[:I_0], fit[:I], (fit[:μ] .- c)..., fit[:σ²])
    end
    image!(ax_m, fit_buf)

    xlims, ylims = lims
    xticks, yticks = tick_locations(lims, 0.1)
    ax_HR.xticks = ax_m.xticks = xticks
    ax_HR.yticks = ax_m.yticks = yticks
    limits!(ax_HR, xlims, ylims)

    colgap!(fig.layout, Relative(0.04))
    rowgap!(fig.layout, Relative(0.04))
    fig
end

savefig(fig_gaussian_fits_sum, FIG_NAME * "-gaussian-sum"; skip=[:vector, :full], hwratio=1.9, override_theme=merge(MARGIN_PX_TICKS, FORMAT_TICKS, NO_SPINE, DATA_ASPECT))
savefig(fig_gaussian_fits_sum, FIG_NAME * "-gaussian-sum"; skip=[:vector, :margin], hwratio=0.5, override_theme=merge(MARGIN_PX_TICKS, FORMAT_TICKS, NO_SPINE, DATA_ASPECT), fig_function_args=(:horiz,))

source_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/beads_model.ser"))

function fig_source_model(orientation=:vert, lims=((295, 510), (345, 560)))
    fig = Figure()
    ax_HR = Makie.Axis(fig[1, 1], title=L"\hat{s}")
    ax_m = Makie.Axis(fig[orientation == :vert ? 2 : 1, orientation == :vert ? 1 : 2], title=L"\hat{m}")
    linkaxes!(ax_HR, ax_m)

    xlims, ylims = lims
    xticks, yticks = tick_locations(lims, 0.1)
    ax_HR.xticks = ax_m.xticks = xticks
    ax_HR.yticks = ax_m.yticks = yticks

    colgap!(fig.layout, Relative(0.04))
    rowgap!(fig.layout, Relative(0.04))

    image!(ax_HR, HR_img)
    image!(ax_m, source_model)

    limits!(ax_HR, xlims, ylims)
    fig
end

savefig(fig_source_model, FIG_NAME; skip=[:vector, :full], hwratio=1.9, override_theme=merge(MARGIN_PX_TICKS, FORMAT_TICKS, NO_SPINE, DATA_ASPECT), fig_function_args=(orientation=:vert, lims=((295, 510), (345, 560)),))
savefig(fig_source_model, FIG_NAME; skip=[:vector, :margin], hwratio=0.5, override_theme=merge(NO_TICKS, NO_TICKLABELS, FORMAT_TICKS, NO_SPINE, DATA_ASPECT), fig_function_args=(orientation=:horiz, lims=((1, 1024), (1, 1024))))
