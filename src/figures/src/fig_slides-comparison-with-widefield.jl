include("init.jl")
using Interpolations

const FIG_NAME = getbase(@__FILE__)

psf_model = psf(IdealOTFwithCurvature(488u"nm", 1.4, 1.0, 0.9), 15, 61u"nm").parent |> real
deconv_model, _ = deconvolution(gray.(LR_beads_sum), ifftshift(psf_model); iterations=100)
s_out_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/spatial_weiner_reconstruction_model.ser"))

function fig_weiner_vs_widefield_cutout()
    fig = Figure()
    ax_s, ax_widefield = Makie.Axis(fig[1, 1], title=L"\hat{s}_\text{SIM}(\vec{r})"), Makie.Axis(fig[1, 2], title=L"\hat{s}_\text{deconv}(\vec{r})")
    linkaxes!(ax_widefield, ax_s)
    colgap!(fig.layout, Relative(0.07))

    image!(ax_widefield, imresize(deconv_model, (1024, 1024), method=Constant())')
    image!(ax_s, real(s_out_model))

    lims = ((400, 540), (310, 450))
    limits!(ax_widefield, lims...)
    ax_widefield.xticks, ax_widefield.yticks = ax_s.xticks, ax_s.yticks = tick_locations(lims, 0.1)

    return fig
end

savefig(fig_weiner_vs_widefield_cutout, FIG_NAME; hwratio=4 / 7, skip=[:eps, :margin], override_theme=merge(MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT, MARGIN_PX_TICKS), update=true)
