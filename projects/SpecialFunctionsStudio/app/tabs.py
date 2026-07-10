from __future__ import annotations

from utils.control_schema import c, section, tab
from projects.SpecialFunctionsStudio.core.catalog import FAMILIES as FUNCTION_FAMILIES

FAMILIES = tuple(family.name for family in FUNCTION_FAMILIES)
VARIANTS_BY_FAMILY = {
    family.name: tuple(variant.name for variant in family.variants)
    for family in FUNCTION_FAMILIES
}
FAMILY_PRESETS = {
    family.name: {
        "x_range": f"{family.default_xrange[0]:g} {family.default_xrange[1]:g}",
        "tuple_label": f"({', '.join(family.variants[0].param_labels)})" if family.variants[0].param_labels else "none",
        "tuple_scan": family.variants[0].default_tuple,
    }
    for family in FUNCTION_FAMILIES
}
VARIANT_PRESETS = {
    variant.name: {
        "tuple_label": f"({', '.join(variant.param_labels)})" if variant.param_labels else "none",
        "tuple_scan": variant.default_tuple,
    }
    for family in FUNCTION_FAMILIES
    for variant in family.variants
}


def get_tabs():
    return [
        tab(
            "special_functions",
            "special functions",
            section(
                "function",
                c("family", "family", "combo", "Bessel", FAMILIES, preset_values=FAMILY_PRESETS),
                c(
                    "variant", "function / variant", "combo", "Bessel J",
                    VARIANTS_BY_FAMILY["Bessel"],
                    depends_on="family", options_by=VARIANTS_BY_FAMILY, preset_values=VARIANT_PRESETS,
                ),
            ),
            section(
                "parameters",
                c("tuple_label", "tuple order label", default="(nu)"),
                c("tuple_scan", "tuple scan", "textarea", "(0:5)"),
            ),
            section(
                "1d display",
                c("x_range", "x range", default="0 20"),
                c("crop_mode", "crop mode", "combo", "auto", ("auto", "manual", "none")),
                c("y_min", "y min", default="", visible_when={"crop_mode": ("manual",)}),
                c("y_max", "y max", default="", visible_when={"crop_mode": ("manual",)}),
                c("legend_location", "legend location", "combo", "northwest", ("northwest", "northeast", "best")),
            ),
            section(
                "preview layout",
                c("preview_columns", "preview columns", default="auto"),
                c("composite", "composite", "bool", True),
            ),
            section("actions"),
            preview="list",
            initial_message="run to generate selected special-function previews",
        )
    ]


def build_tab():
    return get_tabs()[0]


