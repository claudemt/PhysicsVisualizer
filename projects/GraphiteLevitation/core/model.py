TITLE = "Graphite Levitation"
DESCRIPTION = "Diamagnetic graphite over checkerboard magnet arrays."
DEFAULTS = {
    "resolution": 160,
    "shape": "circle",
    "d": "6",
    "rotation_deg": 0,
    "W_um": "40",
    "chi": "3.05",
    "array_size": "6 6",
    "magnet_size_mm": "10 10 10",
    "Br": 1.46,
    "height": 0.35,
    "spot_mm": "3 0",
    "P": "0.35",
}
FORMULAS = "Diamagnetic energy is proportional to -chi B^2."


def render(params):
    from .render import render as render_graphite

    return render_graphite(params)
