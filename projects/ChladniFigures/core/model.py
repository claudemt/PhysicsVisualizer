TITLE = "Chladni Figures"
DESCRIPTION = "Thin-plate mode and nodal-pattern visualization."
DEFAULTS = {"resolution": 240, "study": "modes", "mode_count": 10, "rect_boundary": "FFFF", "nu": 0.225, "xi0": 0.45}
FORMULAS = "Plate eigenmodes and static deflection."


def render(params):
    from .render import render as render_chladni

    return render_chladni(params)
