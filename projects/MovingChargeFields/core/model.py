TITLE = "Moving Charge Fields"
DESCRIPTION = "Relativistic electric and magnetic field maps."
DEFAULTS = {
    "resolution": 180,
    "motion": "circular",
    "slice": "xy",
    "field_part": "tot",
    "a_over_lambda": 1.2,
    "beta": 0.6,
    "slice_position": 0.0,
    "phase": 0.0,
    "fields": "E_mag,B_mag,E_stream,S_stream",
}
FORMULAS = "Lienard-Wiechert field structure for moving charges."


def render(params):
    from .render import render as render_moving_charge

    return render_moving_charge(params)
