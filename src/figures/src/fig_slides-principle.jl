include("init.jl")
const FIG_NAME = getbase(@__FILE__)

function fig_source_cos()
    f1 = x -> cos(2π * x)
    xmax = 30
    fig = Figure()
    ax = Makie.Axis(fig[2:7, 1]) #, xlabel = L"x", ylabel = L"f(x)")
    lines!(ax, 0 .. xmax, f1, label=L"s(x) = \cos(2\pi x)", linewidth=0.5, color=COLORS[1])
    fig[1, 1] = Legend(fig[1, 1], ax, tellwidth=false, tellheight=false)
    limits!(ax, (0, xmax), (-1.1, 1.1))
    fig
end

savefig(fig_source_cos, FIG_NAME * "-source-cos"; hwratio=4 / 7, skip=[:raster, :margin, :eps], override_theme=merge(MARGIN_PX_TICKS, FORMAT_TICKS, Theme(figure_padding=5)))

function fig_ip_cos()
    f2 = x -> cos(2π * x * 1.1)
    xmax = 30
    fig = Figure()
    ax = Makie.Axis(fig[2:7, 1]) #, xlabel = L"x", ylabel = L"f(x)")
    lines!(ax, 0 .. xmax, f2, label=L"i(x) = \cos(2.2\pi x)", linewidth=0.5, color=COLORS[2])
    fig[1, 1] = Legend(fig[1, 1], ax, tellwidth=false, tellheight=false)
    limits!(ax, (0, xmax), (-1.1, 1.1))
    fig
end

savefig(fig_ip_cos, FIG_NAME * "-ip-cos"; hwratio=4 / 7, skip=[:raster, :margin, :eps], override_theme=merge(MARGIN_PX_TICKS, FORMAT_TICKS, Theme(figure_padding=5)))

function fig_ip_source_cos()
    f1 = x -> cos(2π * x)
    f2 = x -> cos(2π * x * 1.1)
    xmax = 30
    fig = Figure()
    ax = Makie.Axis(fig[2:7, 1]) #, xlabel = L"x", ylabel = L"f(x)")
    lines!(ax, 0 .. xmax, f1, label=L"s(x) = \cos(2\pi x)", linewidth=0.5, color=COLORS[1])
    lines!(ax, 0 .. xmax, f2, label=L"i(x) = \cos(2.2\pi x)", linewidth=0.5, color=COLORS[2])
    fig[1, 1] = Legend(fig[1, 1], ax, tellwidth=false, tellheight=false, nbanks=1, orientation=:horizontal)
    limits!(ax, (0, xmax), (-1.1, 1.1))
    ax.yticks = [-1, 0, 1]
    fig
end


savefig(fig_ip_source_cos, FIG_NAME * "-ip-source-cos"; hwratio=4 / 7, skip=[:raster, :margin, :eps],
    override_theme=merge(MARGIN_PX_TICKS, FORMAT_TICKS, Theme(figure_padding=5)))

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

savefig(fig_cos_beats_multiplication, FIG_NAME * "-beats-mult"; hwratio=4 / 7, skip=[:raster, :margin, :eps], override_theme=merge(MARGIN_PX_TICKS, FORMAT_TICKS, Theme(figure_padding=5)))
