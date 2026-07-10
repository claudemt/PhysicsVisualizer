from __future__ import annotations

from utils.control_schema import c, section, tab


MODE_FIELD = ("mode field",)
DISPERSION = ("dispersion",)
FIELD_ACTIONS = ("mode field",)


def get_tabs():
    return [
        tab(
            "metal_guides",
            "metal guides",
            section(
                "study",
                c(
                    "guide",
                    "guide",
                    "combo",
                    "rectangular",
                    ("rectangular", "circular", "annular"),
                    preset_values={
                        "rectangular": {"polarization": "TE", "modes": "(1:3,0:3)"},
                        "circular": {"polarization": "TE", "modes": "(0:3,1:3)"},
                        "annular": {"polarization": "TEM", "modes": "(0:2,1:2)"},
                    },
                ),
                c("action", "action", "combo", "mode field", ("mode field", "dispersion", "cutoff map")),
                c(
                    "polarization",
                    "mode family",
                    "combo",
                    "TE",
                    ("TE", "TM"),
                    depends_on="guide",
                    options_by={
                        "rectangular": ("TE", "TM"),
                        "circular": ("TE", "TM"),
                        "annular": ("TEM", "TE", "TM"),
                    },
                ),
                c(
                    "modes",
                    "mode tuples",
                    "textarea",
                    "(1:3,0:3)",
                    tooltip="Circular and annular radial indices start at 1; rectangular TE indices may include 0.",
                    visible_when={"action": MODE_FIELD, "polarization": ("TE", "TM")},
                ),
            ),
            section(
                "parameters",
                c("a", "a (m)", default=0.03, visible_when={"guide": ("rectangular",)}),
                c("b", "b (m)", default=0.015, visible_when={"guide": ("rectangular",)}),
                c("xi0", "inner / outer radius", default=0.5, visible_when={"guide": ("annular",)}),
                c("radius", "radius (m)", default=0.03, visible_when={"guide": ("circular", "annular")}),
                c("max_order", "max order", default=5, visible_when={"action": ("dispersion", "cutoff map")}),
                c("fmax_ghz", "fmax (GHz)", default=10, visible_when={"action": DISPERSION}),
            ),
            section("actions"),
            preview="list",
            initial_message="run to generate metal waveguide previews",
            waveguide_kind="metal",
        ),
        tab(
            "planar_dielectric",
            "planar dielectric",
            section(
                "study",
                c("action", "action", "combo", "mode field", ("mode field", "dispersion", "existence", "thickness sweep")),
                c("polarization", "polarization", "combo", "TE", ("TE", "TM")),
                c("orders", "orders", "textarea", "(0:3)", visible_when={"action": MODE_FIELD}),
            ),
            section(
                "parameters",
                c("frequency_ghz", "f (GHz)", default=4.0, visible_when={"action": ("mode field", "thickness sweep")}),
                c("max_order", "max order", default=5, visible_when={"action": ("dispersion", "existence", "thickness sweep")}),
                c("nco", "nco", default=1.50, visible_when={"action": ("mode field", "dispersion", "thickness sweep")}),
                c("ncl", "ncl", default=1.45, visible_when={"action": ("mode field", "dispersion", "thickness sweep")}),
                c("d", "d", default=0.10, visible_when={"action": ("mode field", "thickness sweep")}),
            ),
            section("actions"),
            preview="list",
            initial_message="run to generate planar dielectric previews",
            waveguide_kind="planar",
        ),
        tab(
            "cylindrical_dielectric",
            "cylindrical dielectric vector modes",
            section(
                "study",
                c(
                    "action",
                    "action",
                    "combo",
                    "dispersion",
                    ("dispersion", "mode field"),
                    preset_values={"mode field": {"mode_class": "hybrid"}},
                ),
                c(
                    "mode_class",
                    "mode class",
                    "combo",
                    "hybrid",
                    ("hybrid", "axisymmetric"),
                    visible_when={"action": FIELD_ACTIONS},
                    preset_values={
                        "hybrid": {"polarization": "HE", "modes": "(1:2,1)"},
                        "axisymmetric": {"polarization": "TE", "radial_orders": "(1:2)"},
                    },
                ),
                c(
                    "polarization",
                    "mode family",
                    "combo",
                    "HE",
                    ("HE", "EH"),
                    depends_on="mode_class",
                    options_by={"hybrid": ("HE", "EH"), "axisymmetric": ("TE", "TM")},
                    visible_when={"action": FIELD_ACTIONS},
                ),
                c(
                    "modes",
                    "azimuthal, radial tuples",
                    "textarea",
                    "(1:2,1)",
                    visible_when={"action": FIELD_ACTIONS, "mode_class": ("hybrid",)},
                ),
                c(
                    "radial_orders",
                    "radial orders",
                    "textarea",
                    "(1:2)",
                    visible_when={"action": FIELD_ACTIONS, "mode_class": ("axisymmetric",)},
                ),
                c(
                    "phase",
                    "angular phase",
                    "combo",
                    "cos",
                    ("cos", "sin"),
                    visible_when={"action": FIELD_ACTIONS, "mode_class": ("hybrid",)},
                ),
                c(
                    "field_quantity",
                    "field quantity",
                    "combo",
                    "electric magnitude",
                    ("electric magnitude", "magnetic magnitude", "Ez", "Hz"),
                    depends_on="polarization",
                    options_by={
                        "HE": ("electric magnitude", "magnetic magnitude", "Ez", "Hz"),
                        "EH": ("electric magnitude", "magnetic magnitude", "Ez", "Hz"),
                        "TE": ("electric magnitude", "magnetic magnitude"),
                        "TM": ("electric magnitude", "magnetic magnitude"),
                    },
                    visible_when={"action": FIELD_ACTIONS},
                ),
            ),
            section(
                "parameters",
                c("radius", "core radius (m)", default=0.03, visible_when={"action": FIELD_ACTIONS}),
                c("nco", "nco", default=2.50),
                c("ncl", "ncl", default=1.50),
                c("max_order", "max order", default=5, visible_when={"action": DISPERSION}),
                c("v_number", "V number", default=8.0, visible_when={"action": FIELD_ACTIONS}),
                c("vmax", "V max", default=18.0, visible_when={"action": DISPERSION}),
            ),
            section("actions"),
            preview="list",
            initial_message="run to generate cylindrical dielectric previews",
            waveguide_kind="cylindrical",
        ),
    ]


def build_tab():
    return get_tabs()[0]
