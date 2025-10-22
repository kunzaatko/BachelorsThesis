SKIP_PREPARE_IMAGES = NONIMAGE_DATA_LOADED = true
include("init.jl")

const FIG_NAME = getbase(@__FILE__)

function fig_cos_beats_addition()
    f1 = x -> cos(2π * x)
    f2 = x -> cos(2π * x * 1.10)
    fbeat = x -> f1(x) + f2(x)
    xmax = 30
    fig = Figure()
    ax = Makie.Axis(fig[2:7, 1]) # , xlabel = L"x", ylabel = L"f(x)")
    # f1_plt = lines!(ax, 0..xmax, f1, linestyle=:dash, alpha=0.5, linewidth=0.5)
    # f1_plt.label = L"\cos(2\pi x)"
    # f2_plt = lines!(ax, 0..xmax,f2, linestyle=:dash, alpha=0.5, linewidth=0.5)
    lines!(ax, 0 .. xmax, fbeat, label=L"\cos(2\pi x) + \cos(2.2\pi x)", linewidth=0.5)
    # f2_plt.label = L"\cos(2.2\pi x)"
    fig[1, 1] = Legend(fig[1, 1], ax, tellwidth=false, nbanks=1)
    # rowgap!(fig.layout, Relative(0.04)) # TODO: Set in theme <20-11-23>
    # colgap!(fig.layout, Relative(0.04)) # TODO: Set in theme <20-11-23>
    limits!(ax, (0, xmax), (-2, 2))
    fig
end

savefig(fig_cos_beats_addition, FIG_NAME * "-beats"; hwratio=1, skip=[:raster, :full, :eps], override_theme=merge(FORMAT_TICKS, Theme(figure_padding=5)), update=true)

function fig_cos_beats_multiplication()
    f1 = x -> cos(2π * x)
    f2 = x -> cos(2π * x * 1.1)
    fbeat = x -> f1(x) * f2(x)
    xmax = 30
    fig = Figure()
    ax = Makie.Axis(fig[2:7, 1]) #, xlabel = L"x", ylabel = L"f(x)")
    # lines!(ax, 0..xmax, f1, linestyle=:dash, alpha=0.5, label = L"\cos(2\pi x)")
    # lines!(ax, 0..xmax,f2, linestyle=:dash, alpha=0.5, label = L"\cos(2.2\pi x)")
    lines!(ax, 0 .. xmax, fbeat, label=L"\cos(2\pi x)\cdot\cos(2.2\pi x)", linewidth=0.5, color=COLORS[3])
    fig[1, 1] = Legend(fig[1, 1], ax, tellwidth=false, tellheight=false)
    # rowgap!(fig.layout, 1, Relative(10^(-10))) # TODO: Set in theme <20-11-23>
    # colgap!(fig.layout, Relative(0.000000001)) # TODO: Set in theme <20-11-23>
    ax.yticks = [-1, 0, 1]
    limits!(ax, (0, xmax), (-1.1, 1.1))
    fig
end

savefig(fig_cos_beats_multiplication, FIG_NAME * "-beats-mult"; hwratio=1, skip=[:raster, :full, :eps], override_theme=merge(FORMAT_TICKS, Theme(figure_padding=5)), update=true)
