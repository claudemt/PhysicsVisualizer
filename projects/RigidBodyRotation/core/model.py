TITLE = "Rigid Body Rotation"
DESCRIPTION = "Free and fixed-point rigid-body attitude dynamics."
DEFAULTS = {
    "mode": "free rotation",
    "free_preset": "Tennis-racket flip",
    "fixed_preset": "Regular-precession-like",
    "I": "1 2 3",
    "w0": "0.18 2.2 0.04",
    "phi0": 0,
    "tEnd": 18,
    "nSamples": 2200,
    "aBody": "0 0 1",
    "mass": 1,
    "g": 9.81,
    "Euler0": "0 0.55 0",
}
FORMULAS = "Euler equations for principal-axis angular velocity."


def render(params):
    from .render import render as render_rigid_body

    return render_rigid_body(params)
