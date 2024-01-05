using CairoMakie, GLMakie
const FIGURE_DIR = joinpath(abspath(dirname(@__FILE__)), "..")
vectorgraphic(x) = x ∈ [:svg, :eps, :pdf, :pdf_tex] ? true : false

"""
    savefig(fig, name, project_dir)

Save a figure in SVG, EPS and PDF formats.

# Parameters:
    - `fig`: figure object to save
    - `name`: name of the file to save the figure as
    - `dir`: relative or absolute path to the project directory
    - `dpi`: dots per inch
    - `size`: width of the figure in inches

This function saves a figure object in both SVG and PDF formats. The SVG file is saved in the parent directory with the given name and the extension ".svg". The PDF file is saved in the same directory with the given name and the extension ".pdf". The Inkscape command is used to convert the SVG file to PDF format with text in LaTeX using PDF_TEX.
"""
function savefig(fig_function::Function, name::AbstractString, dir::AbstractString=FIGURE_DIR;
    hwratio=HWRATIO,
    backend=CairoMakie,
    override_theme=Theme(),
    base_theme=BASE_THEME,
    margin_theme=MARGIN_THEME,
    full_theme=FULL_THEME,
    vector_theme=VECTOR_THEME,
    raster_theme=RASTER_THEME,
    gl_theme=GL_THEME,
    cairo_theme=CAIRO_THEME,
    skip=[:pdf, :eps], # :svg, :pdf, :pdf_tex, :eps, :png, :raster, :vector, :margin, :full
    fig_function_args=(),
    update=false,
    varargs...)

    # skip
    deny = []
    for s in skip
        if s == :raster
            append!(deny, [:png])
            continue
        elseif s == :vector
            append!(deny, [:eps, :pdf, :pdf_tex, :svg])
        else
            push!(deny, s)
        end
    end
    sort!(deny)
    unique!(deny)

    # matrix 
    avail_formats = backend == CairoMakie ? [:svg, :pdf, :eps, :pdf_tex, :png] : [:png]
    avail_modes = [:margin, :full]

    formats = setdiff(avail_formats, deny)
    sort!(formats; by=f -> f == :svg ? 1 : 2) # pdf_tex is reliant on svg so it has to go first
    :pdf_tex in formats && @assert :svg in formats ":pdf_tex can only be used if :svg is also generated"
    modes = setdiff(avail_modes, deny)

    # theming
    backend_theme = backend == CairoMakie ? cairo_theme : gl_theme
    format_theme(x) = vectorgraphic(x) ? vector_theme : raster_theme
    mode_theme(x) = x == :margin ? margin_theme : full_theme

    for f in formats
        for m in modes
            local figure_theme = merge(override_theme, mode_theme(m)(hwratio), format_theme(f), backend_theme, base_theme)
            with_theme(figure_theme) do
                fig = fig_function(fig_function_args...)
                savefig(fig, name, f, m, backend, dir; hwratio, varargs, update)
            end
        end
    end
end

if !isdefined(@__MODULE__, :EXTENSIONS)
    const EXTENSIONS = Dict(
        :svg => ".svg",
        :pdf => ".pdf",
        :eps => ".eps",
        :pdf_tex => ".pdf",
        :png => ".png",
    )
end
if !isdefined(@__MODULE__, :MODES_SLUGS)
    const MODES_SLUGS = Dict(
        :margin => "_margin",
        :full => "_full",
    )
end

function savefig(fig::Figure, name::AbstractString, format::Symbol, mode::Symbol, backend::Module, dir::AbstractString=FIGURE_DIR;
    extensions=EXTENSIONS, modes_slugs=MODES_SLUGS, hwratio=HWRATIO, wait=true, update=false, varargs...)

    path = joinpath(dir, name * modes_slugs[mode] * extensions[format])
    if format == :pdf_tex
        @info "Building figure at $(basename(path))_tex"
        svgpath = joinpath(dir, name * modes_slugs[mode] * extensions[:svg])
        cmd_parts = ["inkscape", svgpath, "--export-type=pdf", "--export-latex", "--export-filename", path]
        # FIX: How to send the output to /dev/null in Julia? <21-11-23> 
        # if !wait
        #     append!(cmd_parts, ["&>/dev/null"])
        # end
        inkscape_cmd = Cmd(cmd_parts)
        run(inkscape_cmd; wait)
    else
        @info "Building figure at $(basename(path))"
        if backend == CairoMakie
            # if vectorgraphic(format)
            Makie.save(path, fig; backend, px_per_unit=20, pt_per_unit=1, size=figsize(mode == :margin ? MARGIN_SIZE : FULL_SIZE, hwratio), update, varargs...)
            # else
            #     Makie.save(path, fig; backend, update=false, px_per_unit=20, varargs...)
            # end
        end
        backend == GLMakie && Makie.save(path, fig; backend, update=false, varargs...)
    end
end

function getbase(filename)
    return split(basename(filename)[5:end], ".")[1]
end
