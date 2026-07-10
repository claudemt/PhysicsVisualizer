from __future__ import annotations

from projects.CreativePlotStudio.app.catalog import CATALOG, STYLE_ITEMS
from utils.control_schema import c, section, tab


def _domain_tab(key: str, title: str):
    catalog = CATALOG[key]
    categories = tuple(category.category for category in catalog)
    projects = tuple(item for category in catalog for item in category.items)
    return tab(
        key,
        title,
        section(
            "category",
            c("category", "category", "combo", categories[0], categories),
            c("project", "project", "combo", projects[0], projects),
        ),
        section(
            "style / variant",
            c("style", "style", "combo", "default", STYLE_ITEMS),
            c("resolution", "sample count", default=90000),
        ),
        section(
            "parameter scan",
            c("projects", "project scan", "textarea", ""),
            c("styles", "style scan", default=""),
            c("resolutions", "resolution scan", default=""),
        ),
        section("actions"),
        preview="list",
        initial_message=f"select a {title.lower()} project and render",
        domain=key,
    )


def get_tabs():
    return [
        _domain_tab("art", "Art"),
        _domain_tab("fractals", "Fractals"),
        _domain_tab("nonlinear", "Nonlinear"),
    ]


def build_tab():
    return get_tabs()[0]
