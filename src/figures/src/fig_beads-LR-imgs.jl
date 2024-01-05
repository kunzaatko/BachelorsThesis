include("init.jl")
const FIG_NAME = getbase(@__FILE__)

function fig_LR_imgs()
    npad = 10
    nw, nh = size(LR_beads[1])
    mos = mosaic(LR_beads...; ncol=3, fillvalue=1, npad)

    fig, ax, _ = image(mos)

    x_centers = [(nh + 1) / 2, (3nh + 1) / 2 + npad, (5nh + 1) / 2 + 2npad]
    y_centers = [(nw + 1) / 2, (3nw + 1) / 2 + npad, (5nw + 1) / 2 + 2npad]

    ax.xticks = (x_centers, [L"\phi_{1}", L"\phi_{2}", L"\phi_{3}"])
    ax.yticks = (y_centers, [L"n=1", L"n=2", L"n=3"])
    ax.yreversed = true

    return fig
end

savefig(fig_LR_imgs, FIG_NAME; hwratio=1, skip=[:vector], override_theme=merge(NO_SPINE, DATA_ASPECT))
