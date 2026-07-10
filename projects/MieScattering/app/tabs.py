from __future__ import annotations

from utils.control_schema import c, section, tab

FIELDS = (
    "sca Re Ex",
    "sca Re Ey",
    "sca Re Ez",
    "sca |Ex|",
    "sca |Ey|",
    "sca |Ez|",
    "sca Emag",
    "tot Re Ex",
    "tot Re Ey",
    "tot Re Ez",
    "tot |Ex|",
    "tot |Ey|",
    "tot |Ez|",
    "tot Emag",
)


def get_tabs():
    return [
        tab(
            "mie_scattering",
            "mie scattering",
            section(
                "physical parameters",
                c("epsilon_r", "epsilon_r", default="2+0.1i"),
                c("mu_r", "mu_r", default="0.8+0.05i"),
                c("radius", "R/lambda", default=0.5),
                c("nu", "nu", default=1.1),
                c("psi", "psi", default=0.2),
                c("wavenumber", "k", default=8.0),
                c("resolution", "grid N", default=260),
            ),
            section(
                "scattering setup",
                c("geometry", "geometry", "combo", "sphere", ("sphere", "cylinder")),
                c("slice", "slice", "combo", "xz", ("xy", "xz", "yz")),
                c("slice_position", "slice position/lambda", default=0),
                c("fields", "fields", "multiselect", "sca Re Ex,sca Re Ey,sca Re Ez,sca |Ex|,sca |Ey|,sca |Ez|,sca Emag", FIELDS),
                c("mask_inside", "mask inside", "bool", True),
            ),
            section("actions"),
            preview="list",
            initial_message="run to generate selected scattering field previews",
        )
    ]


def build_tab():
    return get_tabs()[0]


