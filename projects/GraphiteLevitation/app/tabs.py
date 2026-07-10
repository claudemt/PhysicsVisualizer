from __future__ import annotations

from utils.control_schema import c, section, tab


def get_tabs():
    return [
        tab(
            "visualization",
            "visualization",
            section(
                "graphite sample",
                c("shape", "shape", "combo", "circle", ("circle", "square")),
                c("d", "radius / side d (mm)", default="6", tooltip="Scalar or tuple, range, or linspace scan."),
                c("rotation_deg", "rotation deg", default=0),
                c("W_um", "thickness W (um)", default="40", tooltip="Scalar or tuple, range, or linspace scan."),
                c("chi", "|chi| (1e-4)", default="3.05", tooltip="Scalar or tuple in units of 1e-4."),
            ),
            section(
                "compact checkerboard magnets",
                c("array_size", "array size", default="6 6"),
                c("magnet_size_mm", "magnet size mm", default="10 10 10"),
                c("Br", "Br (T)", default=1.46),
            ),
            section(
                "laser susceptibility perturbation",
                c("spot_mm", "spot mm", default="3 0"),
                c("P", "P", default="0.35", tooltip="P=0 disables the laser; tuples create a Cartesian scan."),
            ),
            section("actions"),
            preview="list",
            initial_message="run to generate the seven graphite levitation previews",
        )
    ]


def build_tab():
    return get_tabs()[0]


