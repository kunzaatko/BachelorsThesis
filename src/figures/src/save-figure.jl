using CairoMakie
using Unitful
const FIGURE_DIR = joinpath(abspath(dirname(@__FILE__)), "..")

# TODO: Should include the resolution of the save of the figure with either margin figure size (MARGIN_SIZE), or full
# resolution size (FULL_SIZE) instead of the preset `dpi` <16-11-23> 

const MARGIN_SIZE = 47.7u"mm" |> u"inch" |> ustrip
const FULL_SIZE = 107u"mm" |> u"inch" |> ustrip

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
function savefig(fig, name, dir=FIGURE_DIR; margin_size=MARGIN_SIZE, full_size=FULL_SIZE, hwratio=HWRATIO, wait=true, backend=CairoMakie, varargs...)
    @info "Building figure $name"
    backend.activate!()
    # if backend == CairoMakie
    svg_path_margin = joinpath(dir, name * "_margin" * ".svg")
    svg_path_full = joinpath(dir, name * "_full" * ".svg")
    Makie.save(svg_path_margin, fig; pt_per_unit=1, resolution=figsize(margin_size, hwratio), varargs...)
    Makie.save(svg_path_full, fig; pt_per_unit=1, resolution=figsize(full_size, hwratio), varargs...)

    eps_path_margin = joinpath(dir, name * "_margin" * ".eps")
    eps_path_full = joinpath(dir, name * "_full" * ".eps")
    Makie.save(eps_path_margin, fig; pt_per_unit=1, resolution=figsize(margin_size, hwratio), varargs...)
    Makie.save(eps_path_full, fig; pt_per_unit=1, resolution=figsize(full_size, hwratio), varargs...)

    pdf_path_margin = joinpath(dir, name * "_margin" * ".pdf")
    pdf_path_full = joinpath(dir, name * "_full" * ".pdf")
    # inkscape_cmd_margin = Cmd(["inkscape", svg_path_margin, "--export-area-page", "--export-dpi", string(dpi), "--export-type=pdf", "--export-latex", "--export-filename", pdf_path_margin])
    inkscape_cmd_margin = Cmd(["inkscape", svg_path_margin, "--export-type=pdf", "--export-latex", "--export-filename", pdf_path_margin])
    # inkscape_cmd_full = Cmd(["inkscape", svg_path_full, "--export-area-page", "--export-dpi", string(dpi), "--export-type=pdf", "--export-latex", "--export-filename", pdf_path_full])
    inkscape_cmd_full = Cmd(["inkscape", "-D", "-z", svg_path_full, "--export-type=pdf", "--export-latex", "--export-filename", pdf_path_full])
    run(inkscape_cmd_margin; wait)
    run(inkscape_cmd_full; wait)

    png_path_margin = joinpath(dir, name * "_margin" * ".png")
    png_path_full = joinpath(dir, name * "_full" * ".png")
    Makie.save(png_path_margin, fig; pt_per_unit=1, px_per_unit=20, resolution=figsize(margin_size, hwratio), varargs...)
    Makie.save(png_path_full, fig; pt_per_unit=1, px_per_unit=20, resolution=figsize(full_size, hwratio), varargs...)
end
