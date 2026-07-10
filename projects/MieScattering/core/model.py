TITLE = "Mie Scattering"
DESCRIPTION = "Electromagnetic scattering field slices."
DEFAULTS = {
    "resolution": 220,
    "epsilon_r": "2+0.1i",
    "mu_r": "0.8+0.05i",
    "radius": 0.5,
    "nu": 1.1,
    "psi": 0.2,
    "geometry": "sphere",
    "slice": "xz",
    "fields": "sca Re Ex,sca Re Ey,sca Re Ez,sca |Ex|,sca |Ey|,sca |Ez|,sca Emag",
}
FORMULAS = "Incident plus scattered fields around compact inclusions."


def render(params):
    from .render import render as render_mie

    return render_mie(params)
