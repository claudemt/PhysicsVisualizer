from __future__ import annotations

from utils.control_schema import c, section, tab

from projects.RigidBodyRotation.core.presets import FIXED_PRESETS, FREE_PRESETS, MODE_PRESETS


def get_tabs():
    return [
        tab(
            "rigid_body",
            "rigid body",
            section(
                "parameters",
                c("mode", "mode", "combo", "free rotation", ("free rotation", "fixed point"),
                  preset_values=MODE_PRESETS),
                c("free_preset", "free preset", "combo", "Tennis-racket flip", tuple(FREE_PRESETS),
                  visible_when={"mode": ("free rotation",)}, preset_values=FREE_PRESETS),
                c("I", "I = [I1 I2 I3]", default="1 2 3"),
                c("w0", "w0 = [w1 w2 w3]", default="0.18 2.2 0.04"),
                c("phi0", "phi0", default=0, visible_when={"mode": ("free rotation",)}),
                c("tEnd", "tEnd", default=18),
                c("nSamples", "nSamples", default=2200),
                c("fixed_preset", "fixed preset", "combo", "Regular-precession-like", tuple(FIXED_PRESETS),
                  visible_when={"mode": ("fixed point",)}, preset_values=FIXED_PRESETS),
                c("aBody", "aBody", default="0 0 1", visible_when={"mode": ("fixed point",)}),
                c("mass", "mass", default=1, visible_when={"mode": ("fixed point",)}),
                c("g", "g", default=9.81, visible_when={"mode": ("fixed point",)}),
                c("Euler0", "Euler0 = [phi theta psi]", default="0 0.55 0", visible_when={"mode": ("fixed point",)}),
            ),
            section(
                "display / export",
                c("compare", "multi-IC comparison", "bool", False),
                c("compare_rows", "compare rows", "textarea", FREE_PRESETS["Tennis-racket flip"]["compare_rows"],
                  enabled_when={"compare": (True,)}),
                c("legend_2d", "legend 2d", "combo", "northeast", ("northeast", "northwest", "best")),
                c("legend_3d", "legend 3d", "combo", "northeast", ("northeast", "northwest", "best")),
                c("export_mode", "export mode", "combo", "images", ("images", "video")),
            ),
            section("actions"),
            preview="list",
            initial_message="run to refresh static rigid-body previews",
        )
    ]


def build_tab():
    return get_tabs()[0]


