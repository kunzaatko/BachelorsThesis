include("init.jl")

# TODO: Better contrast... Maybe make the upper diff image to be simple diff instead of colordiff <kunzaatko martinkunz@email.cz> 

const FIG_NAME = getbase(@__FILE__)

otsu = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/otsu.ser"))

w_bg = LR_beads_sum .* otsu[:w_bg]
w_fg = LR_beads_sum .* otsu[:w_fg]
l_w_bg = LR_beads_sum .* otsu[:l_w_bg]
l_w_fg = LR_beads_sum .* otsu[:l_w_fg]

function fig_leakage()
    local cv, chv = colorview, channelview
    img = LR_beads_sum

    rgb_fgbg = cv(RGB, chv(w_bg), chv(w_fg), Zeros(size(w_fg))) |> collect
    rgb_fgbg_l = cv(RGB, chv(l_w_bg), chv(l_w_fg), Zeros(size(l_w_fg))) |> collect

    rgb_diff = cv(RGB, chv((otsu[:w_bg] .* otsu[:l_w_fg]) .* img), chv(otsu[:l_w_bg] .* img), Zeros(size(img)))

    fig = Figure()

    ax_l_1, ax_l_2, ax_diff = Makie.Axis(fig[1, 1]), Makie.Axis(fig[1, 2]), Makie.Axis(fig[2, 1:2])
    linkaxes!(ax_l_1, ax_l_2)

    # ax_l_1.title = L"f > t_o"
    image!(ax_l_1, adjust_histogram(rgb_fgbg, LinearStretching()))
    # ax_l_2.title = L"f > \tilde{t}_o"
    image!(ax_l_2, adjust_histogram(rgb_fgbg_l, LinearStretching()))
    image!(ax_diff, adjust_histogram(rgb_diff, LinearStretching()))

    colgap!(fig.layout, Relative(0.1))
    rowgap!(fig.layout, Relative(0.1))

    xlims, ylims = (236, 245), (244, 253)
    limits!(ax_l_1, xlims, ylims)
    xticks, yticks = tick_locations((xlims, ylims), 0.1)
    ax_l_1.xticks = ax_l_2.xticks = xticks
    ax_l_1.yticks = ax_l_2.yticks = yticks

    xlims_diff, ylims_diff = (145, 322), (75, 180)
    limits!(ax_diff, xlims_diff, ylims_diff)
    xticks_diff, yticks_diff = tick_locations((xlims_diff, ylims_diff), 0.1)
    ax_diff.xticks, ax_diff.yticks = xticks_diff, yticks_diff

    return fig
end

savefig(fig_leakage, FIG_NAME * "-leakage"; hwratio=1, skip=[:vector, :full], override_theme=merge(FORMAT_TICKS, MARGIN_PX_TICKS, NO_SPINE, DATA_ASPECT))

# type = :bin, :rgb
function fig_otsu_v_otsu_l(type=:bin)
    img = LR_beads_sum

    fig = Figure()
    ax_l, ax_im, ax_o = Makie.Axis(fig[1, 1]), Makie.Axis(fig[1, 2]), Makie.Axis(fig[1, 3])
    linkaxes!(ax_l, ax_im, ax_o)
    sl = SliderGrid(fig[type == :bin ? 2 : 3, :], (label=L"\alpha", range=0.2:0.005:1.0, startvalue=1))
    α = sl.sliders[1].value
    l_w_fg = @lift ($α .* otsu[:w_thresh]) .< img
    l_w_bg = @lift $l_w_fg .== 0

    image!(ax_im, img)
    if type == :bin
        image!(ax_o, otsu[:w_fg])
        image!(ax_l, l_w_fg)
    elseif type == :rgb
        local cv, chv = colorview, channelview

        w_rgb = cv(RGB, chv(otsu[:w_bg] .* img), chv(otsu[:w_fg] .* img), Zeros(size(img)))
        l_w_rgb = @lift cv(RGB, chv($l_w_bg .* img), chv($l_w_fg .* img), Zeros(size(img)))

        w_rgb_ls = adjust_histogram(w_rgb, LinearStretching())
        l_w_rgb_ls = @lift adjust_histogram($l_w_rgb, LinearStretching())

        image!(ax_o, w_rgb_ls)
        image!(ax_l, l_w_rgb_ls)

        ax_bg_l, ax_bg_o = Makie.Axis(fig[2, 1]), Makie.Axis(fig[2, 3])
        image!(ax_bg_l, @lift adjust_histogram($l_w_bg .* img, LinearStretching()))
        image!(ax_bg_o, adjust_histogram(otsu[:w_bg] .* img, LinearStretching()))
        linkaxes!(ax_l, ax_bg_l, ax_bg_o)
    end

    fig
end
