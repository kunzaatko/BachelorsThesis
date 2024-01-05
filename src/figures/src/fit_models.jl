include("init.jl")
using PSFModels
using PSFModels: fit

gaussian_fits = Dict() # asymmetric fit
for patch in ["CC", "LT", "RT", "LB", "RB"]
    psf_estimate = get_psf_averaged_estimate(patch)
    data = psf_estimate[:psf]
    params = psf_estimate[:params]
    x0, y0 = size(data) .÷ 2
    FWHM0 = params[:FWHMs]
    amp0 = data[x0, y0]
    params_hat, model_hat = fit(gaussian, (; x=x0, y=y0, fwhm=FWHM0, amp=amp0, theta=0.0), data)
    gaussian_fits[patch] = (params_hat, model_hat)
end

airydisk_fits = Dict() # airydisk === Born&Wolf model
for patch in ["CC", "LT", "RT", "LB", "RB"]
    psf_estimate = get_psf_averaged_estimate(patch)
    data = psf_estimate[:psf]
    params = psf_estimate[:params]
    x0, y0 = size(data) .÷ 2
    FWHM0 = params[:FWHMs]
    amp0 = data[x0, y0]
    params_hat, model_hat = fit(airydisk, (; x=x0, y=y0, fwhm=FWHM0, amp=amp0, theta=0.0), data)
    airydisk_fits[patch] = (params_hat, model_hat)
end

function fig_compare_model_v_data_heatmap(patch)
    fig = Figure()
    ax = [Makie.Axis(fig[1, i], title="$i") for i in 1:4]
    linkaxes!(ax...)

    data = get_psf_averaged_estimate(patch)[:psf]
    xlims, ylims = extrema.(axes(data))
    len = 30
    xs, ys = range(xlims...; length=len), range(ylims...; length=len)
    xsg, ysg = ones(len) * xs', ys * ones(len)'

    ax[1].title = "Gaussian model"
    heatmap!(ax[1], xs, ys, gaussian_fits[patch][2].(xsg, ysg))
    ax[2].title = "Bead average estimate"
    # heatmap!(ax[2], data)
    ax[3].title = "Born & Wolf model"
    heatmap!(ax[3], xs, ys, airydisk_fits[patch][2].(xsg, ysg))
    ax[4].title = "Diff Gaussian - Born & Wolf"
    heatmap!(ax[4], xs, ys, gaussian_fits[patch][2].(xsg, ysg) .- airydisk_fits[patch][2].(xsg, ysg))
    fig
end

function fig_compare_model_v_data_3D(patch; plot=wireframe!)
    fig = Figure()
    ax = [Makie.Axis3(fig[1, i], title="$i") for i in 1:4]
    # linkaxes!(ax...)

    data = get_psf_averaged_estimate(patch)[:psf]
    xlims, ylims = extrema.(axes(data))
    len = 50
    xs, ys = range(xlims...; length=len), range(ylims...; length=len)
    xsg, ysg = ones(len) * xs', ys * ones(len)'

    ax[1].title = "Gaussian model"
    plot(ax[1], xs, ys, gaussian_fits[patch][2].(xsg, ysg))
    ax[2].title = "Bead average estimate"
    plot(ax[2], data)
    ax[3].title = "Born & Wolf model"
    plot(ax[3], xs, ys, airydisk_fits[patch][2].(xsg, ysg))
    ax[4].title = "Diff Gaussian - Born & Wolf"
    plot(ax[4], xs, ys, gaussian_fits[patch][2].(xsg, ysg) .- airydisk_fits[patch][2].(xsg, ysg))
    fig
end
# TODO: Make a comparison 2D with `stairs` and y-I x-I planes (I...intensity)<12-12-23> 
