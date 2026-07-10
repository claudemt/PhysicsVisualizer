from __future__ import annotations

from collections.abc import Iterable, Mapping, Sequence
from dataclasses import dataclass
import json
import re

from utils.image_output import slug as slugify


@dataclass(frozen=True)
class CatalogCategory:
    category: str
    folder: str
    items: tuple[str, ...]


@dataclass(frozen=True)
class CatalogSelection:
    domain: str
    category: CatalogCategory
    project: str

    @property
    def slug(self) -> str:
        return slugify(self.project)

    def as_params(self) -> dict[str, str]:
        return {
            "domain": self.domain,
            "category": self.category.category,
            "project": self.project,
        }


CATALOG: dict[str, tuple[CatalogCategory, ...]] = {
    "art": (
        CatalogCategory("Pixel & Texture", "pixel_texture", ("Bitwise Fractal", "Tablecloth", "Music Score")),
        CatalogCategory("Floral & Botanical", "floral_botanical", ("Sakura Tree", "Blue Rose", "Blooming Rose", "Rose Ball")),
        CatalogCategory("Scenes & Objects", "scenes_objects", ("Crystal Cluster", "Crystal Heart", "Moonlit Mountains", "Fireworks", "Ice Cream Soft Serve", "Ice Cream Bouquet", "Art Candlesticks")),
        CatalogCategory("Generative Art", "generative_art", ("Phyllotaxis Sunflower", "Superformula Bloom", "Plasma Clouds")),
    ),
    "fractals": (
        CatalogCategory("Escape-Time & Julia", "escape_time_julia", ("Mandelbrot Garden", "Julia Nebula", "Burning Ship Ember", "Tricorn Mandelbar", "Phoenix Julia", "Multibrot Cubic", "Celtic Mandelbrot", "Perpendicular Burning Ship")),
        CatalogCategory("Newton & Orbit Traps", "newton_orbit_traps", ("Newton Basin", "Nova Cubic Basin", "Orbit Trap Pearls")),
        CatalogCategory("Recursive & IFS", "recursive_ifs", ("Barnsley Fern", "Sierpinski Carpet", "Apollonian Gasket", "Dragon Curve", "Koch Snowflake", "Levy C Curve", "Pythagoras Tree", "Vicsek Fractal", "DLA Cluster")),
        CatalogCategory("Fractal Fields", "fractal_fields", ("Lyapunov Carpet", "Gray-Scott Coral")),
    ),
    "nonlinear": (
        CatalogCategory("Strange Attractors", "strange_attractors", ("Lorenz Attractor", "Rossler Ribbon", "Chua Double Scroll", "Clifford Attractor", "Aizawa Attractor", "Thomas Attractor", "Dadras Attractor", "De Jong Attractor", "Hopalong Attractor")),
        CatalogCategory("Maps & Bifurcations", "maps_bifurcations", ("Henon Map", "Standard Map Islands", "Ikeda Map", "Logistic Bifurcation", "Circle Map Tongues", "Lyapunov Carpet")),
        CatalogCategory("Oscillators & Vibration", "oscillators_vibration", ("Duffing Poincare", "Duffing Sweep", "Van der Pol Phase", "Double Pendulum Trace", "Chladni Resonance", "Lissajous Knot")),
        CatalogCategory("Reaction Waves", "reaction_waves", ("Gray-Scott Coral", "FitzHugh-Nagumo Spiral")),
    ),
}


STYLE_ITEMS = (
    "default", "dark", "electric", "zoom", "minimal", "vibrant", "neon", "detailed", "bright",
    "blue", "warm", "gold", "teal", "sunset", "violet",
    "chocolate", "vanilla", "strawberry", "matcha",
    "coolnight", "warmmountains", "monomoon",
    "deep zoom", "seahorse valley", "dragon", "spiral", "mitosis", "worms",
)


_DOMAIN_ALIASES = {
    "art": "art",
    "artwork": "art",
    "fractals": "fractals",
    "fractal": "fractals",
    "nonlinear": "nonlinear",
    "nonlinear dynamics": "nonlinear",
}


def normalize_domain(domain: object) -> str:
    key = str(domain or "art").strip().lower().replace("_", " ")
    return _DOMAIN_ALIASES.get(key, "art")


def get_domain_catalog(domain: str) -> tuple[CatalogCategory, ...]:
    return CATALOG[normalize_domain(domain)]


def iter_catalog(domain: str | None = None) -> Iterable[CatalogSelection]:
    domains = (normalize_domain(domain),) if domain is not None else tuple(CATALOG)
    for domain_key in domains:
        for category in CATALOG[domain_key]:
            for item in category.items:
                yield CatalogSelection(domain_key, category, item)


def catalog_size() -> int:
    return sum(1 for _ in iter_catalog())


def _category_aliases(category: CatalogCategory) -> set[str]:
    aliases = {slugify(category.category), slugify(category.folder)}
    words = [word for word in re.split(r"[_&\-\s]+", category.category.lower()) if word]
    if words:
        aliases.add(slugify(" ".join(words[:1])))
        aliases.add(slugify(" ".join(words[:2])))
    return aliases


def _find_category(catalog: tuple[CatalogCategory, ...], value: object) -> CatalogCategory | None:
    wanted = slugify(str(value or ""))
    if not wanted:
        return None
    exact = [category for category in catalog if wanted in _category_aliases(category)]
    if exact:
        return exact[0]
    partial = [
        category for category in catalog
        if any(wanted in alias or alias in wanted for alias in _category_aliases(category))
    ]
    return partial[0] if len(partial) == 1 else None


def find_item(
    domain: str,
    category_or_project: str,
    project: str | None = None,
    *,
    strict: bool = False,
) -> tuple[CatalogCategory, str]:
    domain_key = normalize_domain(domain)
    catalog = CATALOG[domain_key]
    if project is None:
        wanted_project = slugify(category_or_project)
        requested_category = None
    else:
        wanted_project = slugify(project)
        requested_category = _find_category(catalog, category_or_project)

    if wanted_project:
        search_order = list(catalog)
        if requested_category is not None:
            search_order.remove(requested_category)
            search_order.insert(0, requested_category)
        for category in search_order:
            for item in category.items:
                if slugify(item) == wanted_project:
                    return category, item

    if strict:
        raise ValueError(
            f"Unknown CreativePlotStudio selection: domain={domain_key!r}, "
            f"category={category_or_project!r}, project={project!r}."
        )
    fallback = requested_category or catalog[0]
    return fallback, fallback.items[0]


def _split_entries(text: str) -> list[str]:
    entries = [part.strip() for part in re.split(r"[;\n]+", text) if part.strip()]
    if len(entries) == 1 and "," in entries[0] and "=" not in entries[0]:
        entries = [part.strip() for part in entries[0].split(",") if part.strip()]
    return entries


def _selection_from_text(text: str, default_domain: str) -> CatalogSelection:
    value = text.strip()
    key_values = dict(
        (slugify(key), item.strip())
        for key, item in re.findall(r"(domain|category|project)\s*=\s*([^,;]+)", value, flags=re.I)
    )
    if key_values:
        domain = normalize_domain(key_values.get("domain", default_domain))
        category, project = find_item(
            domain,
            key_values.get("category", ""),
            key_values.get("project", ""),
            strict=True,
        )
        return CatalogSelection(domain, category, project)

    parts = [part.strip() for part in re.split(r"\s*(?:/|\||>)\s*", value) if part.strip()]
    if len(parts) == 1 and value.count(":") == 2:
        parts = [part.strip() for part in value.split(":")]
    if len(parts) >= 3:
        domain = normalize_domain(parts[0])
        category, project = find_item(domain, parts[1], parts[2], strict=True)
    elif len(parts) == 2 and slugify(parts[0]) in {slugify(key) for key in _DOMAIN_ALIASES}:
        domain = normalize_domain(parts[0])
        category, project = find_item(domain, parts[1], strict=True)
    elif len(parts) == 2:
        domain = normalize_domain(default_domain)
        category, project = find_item(domain, parts[0], parts[1], strict=True)
    else:
        domain = normalize_domain(default_domain)
        try:
            category, project = find_item(domain, value, strict=True)
        except ValueError:
            matches = [entry for entry in iter_catalog() if entry.slug == slugify(value)]
            if len(matches) != 1:
                raise
            return matches[0]
    return CatalogSelection(domain, category, project)


def parse_composite_input(value: object, default_domain: str = "art") -> list[CatalogSelection]:
    """Parse mappings, sequences, JSON, or MATLAB-like delimited project rows."""
    if value is None or value == "":
        return []
    if isinstance(value, CatalogSelection):
        return [value]
    if isinstance(value, Mapping):
        for key in ("projects", "composite", "selection", "selections", "items"):
            if key in value:
                return parse_composite_input(value[key], default_domain)
        domain = normalize_domain(value.get("domain", default_domain))
        category, project = find_item(
            domain,
            str(value.get("category", "")),
            str(value.get("project", "")),
            strict=True,
        )
        return [CatalogSelection(domain, category, project)]
    if isinstance(value, Sequence) and not isinstance(value, (str, bytes)):
        selections: list[CatalogSelection] = []
        for item in value:
            selections.extend(parse_composite_input(item, default_domain))
        return selections

    text = str(value).strip()
    if text.startswith("[") or text.startswith("{"):
        try:
            return parse_composite_input(json.loads(text), default_domain)
        except json.JSONDecodeError as exc:
            raise ValueError(f"Invalid CreativePlotStudio composite JSON: {exc.msg}.") from exc
    return [_selection_from_text(entry, default_domain) for entry in _split_entries(text)]


def all_slugs() -> dict[str, str]:
    return {entry.slug: entry.domain for entry in iter_catalog()}
