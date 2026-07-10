from __future__ import annotations

from utils.control_schema import c, section, tab


def get_tabs():
    return [
        tab(
            "crystal_boundary",
            "crystal boundary optics",
            section(
                "incident wave",
                c("n_incident", "n_inc", default=1.0),
                c("k_inc", "k_inc = [kx ky kz]", "textarea", "0.60 0.64 -0.48"),
            ),
            section(
                "polarization",
                c(
                    "pol_type",
                    "type",
                    "combo",
                    "angle",
                    ("angle", "vector", "sweep"),
                    "Angle uses the s/p basis; vector is projected transverse to k_inc; sweep spans [0, 180) degrees.",
                ),
                c("alpha_deg", "alpha (deg)", default=0.0, visible_when={"pol_type": ("angle",)}),
                c("pol_vector", "E vector [Ex Ey Ez]", "textarea", "1 0 0", visible_when={"pol_type": ("vector",)}),
                c("num_samples", "sweep samples", default=181, visible_when={"pol_type": ("sweep",)}),
                c(
                    "angle_list_deg",
                    "custom sweep angles (deg)",
                    "textarea",
                    "",
                    tooltip="Optional whitespace/comma-separated angles; blank uses the sample count.",
                    visible_when={"pol_type": ("sweep",)},
                ),
            ),
            section(
                "crystal parameters",
                c("material_input", "material input", "combo", "principal + orientation", ("principal + orientation", "direct eps_lab")),
                c("eps_diag", "eps_diag", "textarea", "2.25 2.56 3.24", visible_when={"material_input": ("principal + orientation",)}),
                c("orientation", "orientation", "combo", "none", ("none", "axis", "euler_zyx", "matrix"), visible_when={"material_input": ("principal + orientation",)}),
                c("optic_axis", "optic axis", "textarea", "0 0 1", visible_when={"material_input": ("principal + orientation",), "orientation": ("axis",)}),
                c("euler_zyx", "Euler ZYX deg", "textarea", "0 0 0", visible_when={"material_input": ("principal + orientation",), "orientation": ("euler_zyx",)}),
                c("orientation_R", "orientation R 3x3", "matrix", "1 0 0\n0 1 0\n0 0 1", visible_when={"material_input": ("principal + orientation",), "orientation": ("matrix",)}),
                c("eps_lab", "eps_lab 3x3", "matrix", "2.25 0 0\n0 2.56 0\n0 0 3.24", visible_when={"material_input": ("direct eps_lab",)}),
            ),
            section("actions"),
            preview="text",
            initial_message="run to compute the crystal boundary report",
        )
    ]


def build_tab():
    return get_tabs()[0]


