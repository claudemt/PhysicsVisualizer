"""Generative-art content variants decoded from the MATLAB ``style`` field.

This module deliberately contains only artwork and simulation parameters:
palettes, artwork backgrounds, strokes, camera angles, iteration budgets, and
framing.  It must not define GUI, fonts, ordinary axes styling, layout, or
export behavior.  Those concerns remain in the shared ``utils`` layer.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass
import re

from projects.CreativePlotStudio.app.catalog import STYLE_ITEMS


def _key(value: object) -> str:
    return re.sub(r"\s+", " ", str(value or "default").strip().lower())


@dataclass(frozen=True)
class ContentVariant:
    name: str
    palette: str
    background: str
    line_width_scale: float
    line_alpha: float
    iteration_scale: float
    zoom: float
    view: tuple[float, float] | None
    native: bool
    strategy: str


# Every dropdown value has a concrete, renderer-facing visual difference.
# Palette names are resolved to project-local artistic colormaps by dispatch.
_STYLE_TOKENS: dict[str, tuple[str, str, float, float, float, float, tuple[float, float] | None]] = {
    "default": ("twilight", "#ffffff", 1.0, 0.85, 1.0, 1.0, None),
    "dark": ("twilight", "#060812", 0.85, 0.72, 1.12, 1.0, (18, -36)),
    "electric": ("neon", "#02040c", 1.12, 0.94, 1.25, 1.08, (22, -42)),
    "zoom": ("nebula", "#070914", 0.92, 0.88, 1.35, 1.45, (24, -30)),
    "minimal": ("balance", "#f7f7f2", 0.62, 0.78, 0.72, 0.92, None),
    "vibrant": ("coral", "#081018", 1.18, 0.96, 1.22, 1.0, (20, -32)),
    "neon": ("neon", "#03030a", 1.05, 0.96, 1.16, 1.04, (26, -38)),
    "detailed": ("twilight", "#05070e", 0.72, 0.92, 1.55, 1.0, (19, -35)),
    "bright": ("coral", "#faf8f0", 1.0, 0.9, 1.15, 1.0, None),
    "blue": ("twilight", "#06142b", 1.0, 0.9, 1.0, 1.0, (20, -34)),
    "warm": ("ember", "#1a0906", 1.08, 0.92, 1.05, 1.0, (20, -28)),
    "gold": ("coral", "#201306", 1.12, 0.94, 1.08, 1.0, (22, -30)),
    "teal": ("coral", "#031516", 0.96, 0.9, 1.05, 1.0, (18, -38)),
    "sunset": ("ember", "#210713", 1.1, 0.92, 1.1, 1.0, (19, -32)),
    "violet": ("nebula", "#11051f", 1.04, 0.94, 1.12, 1.0, (24, -40)),
    "chocolate": ("ember", "#25130b", 1.08, 0.9, 1.0, 1.0, (18, -32)),
    "vanilla": ("coral", "#fff3d1", 0.95, 0.9, 1.0, 1.0, (18, -32)),
    "strawberry": ("nebula", "#2a0714", 1.06, 0.94, 1.05, 1.0, (20, -34)),
    "matcha": ("coral", "#0b1b0b", 0.98, 0.9, 1.05, 1.0, (20, -34)),
    "coolnight": ("twilight", "#02030a", 0.92, 0.9, 1.0, 1.0, None),
    "warmmountains": ("coral", "#f9decb", 1.0, 0.9, 1.0, 1.0, None),
    "monomoon": ("balance", "#000000", 0.88, 0.9, 1.0, 1.0, None),
    "deep zoom": ("twilight", "#030510", 0.78, 0.9, 1.52, 16.0, None),
    "seahorse valley": ("twilight", "#040611", 0.82, 0.92, 1.45, 10.0, None),
    "dragon": ("nebula", "#080511", 1.0, 0.94, 1.22, 1.1, (24, -40)),
    "spiral": ("nebula", "#100518", 0.94, 0.94, 1.22, 1.1, (24, -40)),
    "mitosis": ("coral", "#07120f", 0.95, 0.94, 1.35, 1.0, None),
    "worms": ("coral", "#15100a", 1.08, 0.94, 1.35, 1.0, None),
}


_NATIVE_STYLES: dict[tuple[str, str], frozenset[str]] = {
    ("fractals", "mandelbrot_garden"): frozenset({"default", "deep zoom", "seahorse valley"}),
    ("fractals", "julia_nebula"): frozenset({"default", "dragon", "spiral"}),
    ("fractals", "gray_scott_coral"): frozenset({"default", "mitosis", "worms"}),
    ("nonlinear", "gray_scott_coral"): frozenset({"default", "mitosis", "worms"}),
    ("art", "art_candlesticks"): frozenset({"coolnight", "warmmountains", "monomoon"}),
    ("art", "ice_cream_soft_serve"): frozenset({"chocolate", "vanilla", "strawberry", "matcha"}),
    ("art", "ice_cream_bouquet"): frozenset({"chocolate", "vanilla", "strawberry", "matcha"}),
    ("art", "fireworks"): frozenset({"blue", "warm", "gold"}),
    ("art", "rose_ball"): frozenset({"blue", "teal", "sunset", "violet"}),
}


def normalize_variant(value: object) -> str:
    """Return a canonical MATLAB dropdown value or raise a useful error."""
    style = _key(value)
    if style not in _STYLE_TOKENS:
        raise ValueError(
            f"Unknown CreativePlotStudio style {value!r}. Available styles: {', '.join(STYLE_ITEMS)}."
        )
    return style


def resolve_variant(domain: object, project_slug: object, value: object = "default") -> ContentVariant:
    """Resolve a MATLAB dropdown value into artwork/simulation parameters."""
    style = normalize_variant(value)
    palette, background, width, alpha, iterations, zoom, view = _STYLE_TOKENS[style]
    native = style in _NATIVE_STYLES.get((_key(domain), _key(project_slug).replace(" ", "_")), frozenset())
    strategy = "native renderer variant" if native else "artistic fallback palette, stroke, and view"
    return ContentVariant(style, palette, background, width, alpha, iterations, zoom, view, native, strategy)


def variant_difference(value: object, *, domain: object = "art", project_slug: object = "") -> dict[str, object]:
    """Return fields that differ from default; suitable for tests and diagnostics."""
    current = asdict(resolve_variant(domain, project_slug, value))
    baseline = asdict(resolve_variant(domain, project_slug, "default"))
    return {key: item for key, item in current.items() if item != baseline[key]}


def variant_smoke_cases() -> tuple[ContentVariant, ...]:
    """One parsed, non-default-differing case for every GUI dropdown item."""
    return tuple(resolve_variant("art", "", style) for style in STYLE_ITEMS)
