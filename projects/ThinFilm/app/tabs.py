from __future__ import annotations

from utils.control_schema import c, section, tab


def get_tabs():
    return [
        tab(
            "elastic_thin_film",
            "elastic film",
            section(
                "incident wave",
                c("omega", "omega", default=1),
                c("k_x", "k_x", default=0.1),
                c("phi_i", "phi_i", default=1),
                c("psi_i", "psi_i", default=1),
            ),
            section(
                "boundary media",
                c("medium_a", "air a [lambda mu eta]", "textarea", "1.3 1 1"),
                c("medium_g", "substrate g [lambda mu eta]", "textarea", "1.3 5.2 1.9"),
            ),
            section(
                "film layers",
                c("layers", "lambda mu eta h", "textarea", "4 1.5 4.4 9.8"),
            ),
            section("actions"),
            preview="text",
            initial_message="run to compute elastic thin-film transfer report",
            film_kind="elastic",
        ),
        tab(
            "optical_thin_film",
            "optical film",
            section(
                "incidence",
                c("omega", "omega", default=1),
                c("theta_a", "theta_a", default=0.524),
                c("scan_mode", "render mode", "combo", "single", ("single", "angle sweep", "thickness sweep")),
            ),
            section(
                "boundary media",
                c("medium_a", "medium a [eps mu]", "textarea", "1 1"),
                c("medium_g", "medium g [eps mu]", "textarea", "2.25 1"),
            ),
            section(
                "film layers",
                c("layers", "eps mu h", "textarea", "2.25 1 0.25*lambda"),
            ),
            section(
                "optical sweep",
                c("angle_start", "theta start (rad)", default=0.0, visible_when={"scan_mode": ("angle sweep",)}),
                c("angle_stop", "theta stop (rad)", default=1.4, visible_when={"scan_mode": ("angle sweep",)}),
                c("layer_index", "layer index (1-based)", default=1, visible_when={"scan_mode": ("thickness sweep",)}),
                c("thickness_start", "thickness start", default=0.0, visible_when={"scan_mode": ("thickness sweep",)}),
                c("thickness_stop", "thickness stop", default=2.0, visible_when={"scan_mode": ("thickness sweep",)}),
                c("sweep_samples", "samples", default=181, visible_when={"scan_mode": ("angle sweep", "thickness sweep")}),
            ),
            section("actions"),
            preview="text",
            initial_message="run to compute optical thin-film transfer report",
            film_kind="optical",
        ),
    ]


def build_tab():
    return get_tabs()[0]


