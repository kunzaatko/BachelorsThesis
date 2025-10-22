include("init.jl")

const FIG_NAME = getbase(@__FILE__)

using IterTools
using OffsetArrays: centered

s_sim_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/spatial_weiner_reconstruction_model_ccp3_apo.ser"))
f_sim_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/fourier_weiner_reconstruction_model_ccp3_apo.ser"))

modulations_ccp3 = collect(partition(repeat(IP_params_ccp3[:modulations_alt], inner=3), 3))

modulations_ccp3_alt = [(1, 1, 1), (1, 1, 1), (1, 1, 1)]

phase_offsets_ccp3 = map(IP_params_ccp3[:phase_offsets]) do ϕ
    ([0, 2π / 3, 4π / 3] .+ ϕ) .% 2π
end
shifts_ccp3 = IP_params_ccp3[:shifts]
HR_size = size(s_sim_model)
Δxy_HR = HR_beads_Δxy

IPs = map(modulations_ccp3, phase_offsets_ccp3, shifts_ccp3) do o_ms, o_ϕs, o_Δ
    (Harmonic(m, o_Δ, HR_size, ϕ, Δxy_HR) for (m, ϕ) in zip(o_ms, o_ϕs))
end

IPs = vcat(map(collect, IPs)...)
HR_I = map(IPs) do ip
    ip_grid = ip(Float64; Δxy=Δxy_HR)(-512:511, -512:511)
    # NOTE: This has little effect, but is theoretically necessary for consistent sum intensity in the `forward` function
    ip_grid ./= sum(ip_grid) / (HR_size[1] * HR_size[2])
end |> stack

function fig_pattern()
    fig = Figure()
    ax = Makie.Axis(fig[1, 1], title=L"i_{(m , \vec{k}_i, \phi)}(\vec{r})")
    image!(ax, HR_I[:, :, 1])
    fig
end

savefig(fig_pattern, FIG_NAME * "-pattern", hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(DATA_ASPECT, NO_SPINE, NO_TICKS, NO_TICKLABELS))

using TransferFunctions: taperedges, Cosine

function fig_pattern_fft()
    fig = Figure()
    ax = Makie.Axis(fig[1, 1], title=L"I_{(m , \vec{k}_i, \phi)}(\vec{r})")

    pat = Harmonic(1, shifts_ccp3[1], HR_size, 0, Δxy_HR)(Float64; Δxy=Δxy_HR)(-512:511, -512:511)
    fft_pat = fft(pat)
    fft_pat[abs.(fft_pat).<20_000] .= 0 # Little fake... :-3)
    image!(ax, 10 .* fftshift(log2.(abs.(fft_pat) .+ 1)))
    f_center_x, f_center_y = size(fft_pat) ./ 2 .+ 0.5
    linesegments!(ax, [size(fft_pat, 1), 0, f_center_x, f_center_x], [f_center_y, f_center_y, size(fft_pat, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)
    ax.xticks, ax.yticks = ([f_center_x], [L"0"]), ([f_center_y], [L"0"])
    ax.xticksvisible = ax.yticksvisible = ax.xticklabelsvisible = ax.yticklabelsvisible = true
    fig
end

savefig(fig_pattern_fft, FIG_NAME * "-pattern-fft", hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, DATA_ASPECT, NO_SPINE, ORANGE_TITLE))

function fig_fft_widefield()
    f_out = fft(gray.(LR_ccp3_sum))
    fig = Figure()
    ax = Makie.Axis(fig[1, 1], title=L"F(\vec{k})")
    image!(ax, fftshift(log2.(abs.(f_out) .+ 1)))
    f_center_x, f_center_y = size(f_out) ./ 2 .+ 0.5
    linesegments!(ax, [size(f_out, 1), 0, f_center_x, f_center_x], [f_center_y, f_center_y, size(f_out, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)
    ax.xticks, ax.yticks = ([f_center_x], [L"0"]), ([f_center_y], [L"0"])
    ax.xticksvisible = ax.yticksvisible = ax.xticklabelsvisible = ax.yticklabelsvisible = true
    fig
end

savefig(fig_fft_widefield, FIG_NAME * "-fft-widefield", hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, DATA_ASPECT, NO_SPINE, ORANGE_TITLE))

using IterTools
using SIMIlluminationPatterns: IlluminatedImage, separate_components
using TransferFunctions: padtosize, shift, FourierShiftTheorem
using FFTW


Δxy_LR = LR_beads_Δxy
HR_size = (1024, 1024)

transfer_function = IdealOTFwithCurvature(488u"nm", 1.4, 1.0, 0.9)

imgs = map(LR_ccp3) do img
    float64.(gray.(img))
end

IPs = map(modulations_ccp3, phase_offsets_ccp3, shifts_ccp3) do o_ms, o_ϕs, o_Δ
    (Harmonic(m, o_Δ, HR_size, ϕ, Δxy_HR) for (m, ϕ) in zip(o_ms, o_ϕs))
end

I_imgs = [(IlluminatedImage(img, ip, Δxy_HR) for (img, ip) in zip(o_imgs, o_IPs)) for (o_imgs, o_IPs) in zip(partition(imgs, 3), IPs)]
I_imgs = map(collect, I_imgs)
I_imgs = map(splat(tuple), I_imgs)

Cs = separate_components.(I_imgs)
Cs_vec = vcat(map(c -> [c...], Cs)...)

function fig_components_coloured()
    fig = Figure()
    ax = Makie.Axis(fig[1, 1], title=L"F_\text{SIM}(\vec{k})")
    local cv, chv = colorview, channelview
    local logabs(x) = log2(abs(x) + 1)
    comps = map(Cs_vec[1:3]) do comp
        scaleminmax(extrema(logabs.(comp.component))...).(logabs.(comp.component)) .* (otf(transfer_function, size(comp.component), 61u"nm") .!= 0)
    end
    image!(ax, cv(RGB, chv(fftshift(comps[1])), chv(fftshift(comps[2])), chv(fftshift(comps[3]))))
    local f_out = comps[1]
    f_center_x, f_center_y = size(f_out) ./ 2 .+ 0.5
    linesegments!(ax, [size(f_out, 1), 0, f_center_x, f_center_x], [f_center_y, f_center_y, size(f_out, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)
    ax.xticks, ax.yticks = ([f_center_x], [L"0"]), ([f_center_y], [L"0"])
    ax.xticksvisible = ax.yticksvisible = ax.xticklabelsvisible = ax.yticklabelsvisible = true
    fig
end

savefig(fig_components_coloured, FIG_NAME * "-fft-componets-coloured", hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, DATA_ASPECT, NO_SPINE, ORANGE_TITLE))

function fig_components_sep_coloured()
    fig = Figure()
    axes = [Makie.Axis(fig[1, i], title=t) for (i, t) in zip(1:3, [L"C_{-\vec{k}_i}(\vec{k})", L"C_{\vec{0}}(\vec{k})", L"C_{+\vec{k}_i}(\vec{k})"])]
    local cv, chv = colorview, channelview
    local logabs(x) = log2(abs(x) + 1)
    comps = map(Cs_vec[1:3]) do comp
        scaleminmax(extrema(logabs.(comp.component))...).(logabs.(comp.component))
    end
    local z = zeros(size(comps[1]))
    comps = [cv(RGB, z, z, chv(fftshift(comps[1]))), cv(RGB, chv(fftshift(comps[2])), z, z), cv(RGB, z, chv(fftshift(comps[3])), z)]
    for (ax, comp) in zip(axes, comps)
        comp .*= (fftshift(otf(transfer_function, size(comp), 61u"nm")) .!= 0)
        image!(ax, comp)
        local f_out = comp
        f_center_x, f_center_y = size(f_out) ./ 2 .+ 0.5
        linesegments!(ax, [size(f_out, 1), 0, f_center_x, f_center_x], [f_center_y, f_center_y, size(f_out, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)
        ax.xticks, ax.yticks = ([f_center_x], [L"0"]), ([f_center_y], [L"0"])
        ax.xticksvisible = ax.yticksvisible = ax.xticklabelsvisible = ax.yticklabelsvisible = true
        fig
    end
    fig
end

savefig(fig_components_sep_coloured, FIG_NAME * "-fft-componets-sep-coloured", hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, DATA_ASPECT, NO_SPINE, ORANGE_TITLE))

Δ_Cs_vec = map(Cs_vec) do c
    padded = padtosize(c.component, HR_size...; fourier=true) |> fftshift
    Δ_c = TransferFunctions.shift(FourierShiftTheorem(:fourier, true), padded, c.shift) |> ifftshift
    Δ_c
end

function fig_shifted_components()
    fig = Figure()
    ax = Makie.Axis(fig[1, 1], title=L"C_{-\vec{k}_i}(\vec{k} - \vec{k}_i) + C_{\vec{0}}(\vec{k}) + C_{+\vec{k}_i}(\vec{k} + \vec{k}_i)")

    local cv, chv = colorview, channelview
    local logabs(x) = log2(abs(x) + 1)
    comps = map(Δ_Cs_vec[1:3], Cs_vec[1:3]) do comp, c
        scaleminmax(extrema(logabs.(comp))...).(logabs.(comp)) .* (otf(transfer_function, size(comp), 30.5u"nm"; δ=-1 .* c.shift) .!= 0)
    end
    local z = zeros(size(comps[1]))
    image!(ax, cv(RGB, chv(fftshift(comps[1])), chv(fftshift(comps[2])), chv(fftshift(comps[3]))))

    local f_out = comps[1]
    f_center_x, f_center_y = size(f_out) ./ 2 .+ 0.5
    linesegments!(ax, [size(f_out, 1), 0, f_center_x, f_center_x], [f_center_y, f_center_y, size(f_out, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)
    ax.xticks, ax.yticks = ([f_center_x], [L"0"]), ([f_center_y], [L"0"])
    ax.xticksvisible = ax.yticksvisible = ax.xticklabelsvisible = ax.yticklabelsvisible = true

    return fig
end

savefig(fig_shifted_components, FIG_NAME * "-fft-componets-shifted-coloured", hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, DATA_ASPECT, NO_SPINE, ORANGE_TITLE))

function fig_fft_SIM_vs_widefield()
    local f_sim_model = deserialize(joinpath(abspath(dirname(@__FILE__)), "data/fourier_weiner_reconstruction_model_ccp3.ser"))
    f_out_w = fftshift(fft(gray.(LR_ccp3_sum)) .* (otf(transfer_function, size(LR_ccp3_sum), 61u"nm") .!= 0))
    f_out_w_buf = zeros(ComplexF64, size(f_sim_model))
    f_out_w_c = centered(f_out_w)
    centered(f_out_w_buf)[axes(f_out_w_c)...] .= f_out_w_c
    f_out_w = f_out_w_buf
    fig = Figure()
    ax_w, ax_sim = Makie.Axis(fig[1, 1], title=L"F(\vec{k})"), Makie.Axis(fig[1, 2], title=L"F_\text{SIM}(\vec{k})")
    image!(ax_w, log2.(abs.(f_out_w) .+ 1))
    image!(ax_sim, fftshift(log2.(abs.(f_sim_model) .+ 1)))

    for (ax, f_out) in zip([ax_w, ax_sim], [f_out_w, f_sim_model])
        f_center_x, f_center_y = size(f_out) ./ 2 .+ 0.5
        linesegments!(ax, [size(f_out, 1), 0, f_center_x, f_center_x], [f_center_y, f_center_y, size(f_out, 2), 0], color=:white, linewidth=0.5, linestyle=:dashdot, alpha=0.5)
        ax.xticks, ax.yticks = ([f_center_x], [L"0"]), ([f_center_y], [L"0"])
        ax.xticksvisible = ax.yticksvisible = ax.xticklabelsvisible = ax.yticklabelsvisible = true
    end
    fig
end

savefig(fig_fft_SIM_vs_widefield, FIG_NAME * "-fft-sim-vs-widefield", hwratio=4 / 7, skip=[:margin, :eps], override_theme=merge(MARGIN_PX_TICKS, DATA_ASPECT, NO_SPINE, ORANGE_TITLE))
