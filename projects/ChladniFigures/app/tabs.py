from __future__ import annotations

from utils.control_schema import c, section, tab


def get_tabs():
    return [
        tab(
            "chladni_modes",
            "chladni modes",
            section(
                "plate and boundary",
                c("domain", "domain", "combo", "rect", ("rect", "circ", "annulus"), preset_values={"rect": {"rect_boundary": "FFFF"}, "circ": {"circ_boundary": "C"}, "annulus": {"circ_boundary": "CC"}}),
                c("rect_boundary", "rect boundary ULDR", "combo", "FFFF", ("FFFF", "SSSS", "CCCC", "SSFF", "CFFF", "CSFF", "SCFS", "CFSF", "CFCF", "SFSF"), depends_on="domain", visible_when={"domain": ("rect",)}),
                c("rect_solver", "rect solver", "combo", "auto", ("auto", "navier", "clamped_fd", "levy", "free_ritz", "free_sparse", "ritz"), depends_on="domain", visible_when={"domain": ("rect",)}),
                c("circ_boundary", "circ / annulus boundary", "combo", "C", ("C", "S", "F"), depends_on="domain", options_by={"circ": ("C", "S", "F"), "annulus": ("CC", "CS", "CF", "SC", "SS", "SF", "FC", "FS", "FF")}, visible_when={"domain": ("circ", "annulus")}),
                c("nu", "Poisson ratio", default=0.225),
                c("mode_count", "number of modes", default=10),
                c("resolution", "grid size", default=240),
                c("xi0", "aspect ratio / annulus xi_0", default=0.45, depends_on="domain", visible_when={"domain": ("rect", "annulus")}),
            ),
            section("actions"),
            preview="list",
            initial_message="run to generate Chladni mode previews",
            study="modes",
        ),
        tab(
            "static_sources",
            "static sources",
            section(
                "geometry and boundary",
                c("domain", "domain", "combo", "rect", ("rect", "circ", "annulus"), preset_values={"rect": {"rect_boundary": "SSSS"}, "circ": {"circ_boundary": "C"}, "annulus": {"circ_boundary": "CC"}}),
                c("rect_boundary", "rect boundary ULDR", "combo", "SSSS", ("SSSS", "CCCC", "FFFF", "SSFF", "CFFF", "CSFF", "SCFS", "CFSF", "CFCF", "SFSF"), depends_on="domain", visible_when={"domain": ("rect",)}),
                c("rect_solver", "rect solver", "combo", "auto", ("auto", "navier", "clamped_fd", "levy", "free_ritz", "free_sparse", "ritz"), depends_on="domain", visible_when={"domain": ("rect",)}),
                c("circ_boundary", "circ / annulus boundary", "combo", "C", ("C", "S", "F"), depends_on="domain", options_by={"circ": ("C", "S", "F"), "annulus": ("CC", "CS", "CF", "SC", "SS", "SF", "FC", "FS", "FF")}, visible_when={"domain": ("circ", "annulus")}),
                c("nu", "Poisson ratio", default=0.30),
                c("xi0", "aspect ratio / annulus xi_0", default=0.45, depends_on="domain", visible_when={"domain": ("rect", "annulus")}),
                c("resolution", "grid size", default=220),
                c("truncation", "modal truncation", default=60),
                c("D", "plate rigidity D", default=1.0),
            ),
            section(
                "static load q(x,y)",
                c("load_type", "load type", "combo", "points", ("points", "uniform", "custom", "mixed")),
                c("q0", "q0", default=1.0, depends_on="load_type", visible_when={"load_type": ("uniform", "mixed")}),
                c("sources", "sources [x y P sigma]", "textarea", "0 0 1 0\n0.35 0.25 -0.7 0.04", depends_on="load_type", visible_when={"load_type": ("points", "mixed")}),
                c("custom_load", "custom q(x,y)", "textarea", "sin(pi*x).*sin(pi*y)", depends_on="load_type", visible_when={"load_type": ("custom", "mixed")}),
            ),
            section("actions"),
            preview="list",
            initial_message="run to generate static deflection previews",
            study="static",
        ),
    ]


def build_tab():
    return get_tabs()[0]


