include("init.jl")
using Interpolations
const FIG_NAME = getbase(@__FILE__)

function fig_diffraction_limited()
    fig = Figure()
    ax = Makie.Axis(fig[1, 1], title=L"f(\vec{r})")
    image!(ax, LR_ccp3_sum)
    fig
end

savefig(fig_diffraction_limited, FIG_NAME * "-diff-limited", hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(NO_TICKS, NO_TICKLABELS, DATA_ASPECT, NO_SPINE))

function fig_diffraction_limited_cutout()
    fig = Figure()
    ax = Makie.Axis(fig[1, 1], title=L"f(\vec{r})")
    image!(ax, LR_ccp3_sum)
    lims = ((320, 380), (120, 170))
    limits!(ax, lims...)
    ax.xticks, ax.yticks = tick_locations(lims, 0.1)
    fig
end

savefig(fig_diffraction_limited_cutout, FIG_NAME * "-diff-limited-cutout", hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, DATA_ASPECT, NO_SPINE))

psf_model = psf(IdealOTFwithCurvature(488u"nm", 1.4, 1.0, 0.9), 15, 61u"nm").parent |> real
deconv_model, _ = deconvolution(gray.(LR_ccp3_sum), ifftshift(psf_model); iterations=100)

function fig_deconv()
    fig = Figure()
    ax = Makie.Axis(fig[1, 2], title=L"\hat{s}_\text{deconv}(\vec{r})")
    ax2 = Makie.Axis(fig[1, 1], title=L"f(\vec{r})")
    image!(ax2, LR_ccp3_sum)
    image!(ax, deconv_model)
    fig
end

savefig(fig_deconv, FIG_NAME * "-deconv", hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(NO_TICKS, NO_TICKLABELS, DATA_ASPECT, NO_SPINE))

function fig_deconv_compare()
    fig = Figure()
    ax_d, ax_l = Makie.Axis(fig[1, 2], title=L"\hat{s}_\text{deconv}(\vec{r})"), Makie.Axis(fig[1, 1], title=L"f(\vec{r})")
    linkaxes!(ax_d, ax_l)
    image!(ax_l, LR_ccp3_sum)
    image!(ax_d, deconv_model)
    lims = ((320, 380), (120, 170))
    limits!(ax_l, lims...)
    ax_d.xticks, ax_d.yticks = ax_l.xticks, ax_l.yticks = tick_locations(lims, 0.1)
    fig
end

savefig(fig_deconv_compare, FIG_NAME * "-deconv-comp", hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, DATA_ASPECT, NO_SPINE))

s_sim_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/spatial_weiner_reconstruction_model_ccp3_apo.ser"))
f_sim_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/fourier_weiner_reconstruction_model_ccp3_apo.ser"))

function fig_sim()
    fig = Figure()
    ax_d, ax_s = Makie.Axis(fig[1, 1], title=L"\hat{s}_\text{deconv}(\vec{r})"), Makie.Axis(fig[1, 2], title=L"\hat{s}_\text{SIM}(\vec{r})")
    linkaxes!(ax_d, ax_s)
    image!(ax_d, imresize(deconv_model, size(s_sim_model), method=Constant()))
    image!(ax_s, abs.(s_sim_model))
    fig
end

savefig(fig_sim, FIG_NAME * "-SIM", hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(NO_TICKS, NO_TICKLABELS, DATA_ASPECT, NO_SPINE))

function fig_sim_compare()
    fig = Figure()
    ax_d, ax_s = Makie.Axis(fig[1, 1], title=L"\hat{s}_\text{deconv}(\vec{r})"), Makie.Axis(fig[1, 2], title=L"\hat{s}_\text{SIM}(\vec{r})")
    linkaxes!(ax_d, ax_s)
    image!(ax_d, imresize(deconv_model, size(s_sim_model), method=Constant()))
    image!(ax_s, abs.(s_sim_model)')
    lims = ((320, 380), (120, 170))
    limits!(ax_s, 2 .* lims[1], 2 .* lims[2])
    ax_d.xticks, ax_d.yticks = ax_s.xticks, ax_s.yticks = (2 .* tick_locations((lims), 0.1)[1], latexstring.(tick_locations(lims, 0.1)[1])), (2 .* tick_locations(lims, 0.1)[2], latexstring.(tick_locations(lims, 0.1)[2]))
    fig
end

savefig(fig_sim_compare, FIG_NAME * "-SIM-comp", hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, DATA_ASPECT, NO_SPINE))
