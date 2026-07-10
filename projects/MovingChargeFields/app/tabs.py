from __future__ import annotations

from utils.control_schema import c, section, tab

FIELDS = ("E_in", "E_n", "E_mag", "B_in", "B_n", "B_mag", "S_stream", "tau", "E_stream", "B_stream")


def get_tabs():
    return [
        tab(
            "moving_charge",
            "moving charge",
            section(
                "physical parameters",
                c("motion", "motion", "combo", "circular", ("circular", "harmonic")),
                c("slice", "slice", "combo", "xy", ("xy", "xz", "yz")),
                c("field_part", "field part", "combo", "tot", ("tot", "vel", "rad")),
                c("a_over_lambda", "a/lambda", default=1.2),
                c("beta", "beta_max", default=0.6),
                c("slice_position", "slice position/lambda", default=0.0),
                c("phase", "phase t/T", default=0.0),
                c("resolution", "grid N", default=180),
            ),
            section(
                "custom output",
                c("output_mode", "output mode", "combo", "image", ("image", "image+video")),
                c("fields", "field views", "multiselect", "E_mag,B_mag,E_stream,S_stream", FIELDS),
            ),
            section("actions"),
            preview="list",
            initial_message="run to generate still previews before export",
        )
    ]


def build_tab():
    return get_tabs()[0]


