from utils.render_result import report
from projects.CreativePlotStudio.core.render_dispatch import render_creative
from projects.CreativePlotStudio.core.params import iter_parameter_scan
from utils import render_result as rr

TITLE = "Creative Plot Studio"
DESCRIPTION = "Generative art, fractal, and nonlinear plotting."
DEFAULTS = {"domain": "art", "category": "Pixel & Texture", "project": "Bitwise Fractal", "style": "default", "resolution": 90000}
FORMULAS = "Fractals, attractors, maps, and procedural art."


def render(params):
    scan = iter_parameter_scan(params)
    rendered = [render_creative(row) for row in scan]
    figures = [fig for fig, _ in rendered]
    dispatch_paths = [path for _, path in rendered]
    return rr.RenderBundle("CreativePlotStudio", figures, report("CreativePlotStudio", [
        f"Catalog dispatch: {', '.join(dispatch_paths)}.",
        f"Parameter scan produced {len(figures)} render(s).",
        "The Python renderer now follows the MATLAB domain/category/project catalog contract.",
        "Axes text, figure layout, and export styling use the shared utils interfaces.",
    ]))


