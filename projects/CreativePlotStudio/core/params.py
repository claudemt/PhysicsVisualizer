from __future__ import annotations

from collections.abc import Mapping, Sequence
from itertools import product
import json
import math
import re

from projects.CreativePlotStudio.app.catalog import (
    CatalogSelection,
    find_item,
    normalize_domain,
    parse_composite_input,
)
from projects.CreativePlotStudio.core.variants import normalize_variant


def _matlab_range(text: str) -> list[float] | None:
    if not re.fullmatch(r"\s*[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?\s*"
                        r":\s*[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?\s*"
                        r"(?::\s*[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?\s*)?", text):
        return None
    pieces = [float(piece.strip()) for piece in text.split(":")]
    if len(pieces) == 2:
        start, stop = pieces
        step = 1.0 if stop >= start else -1.0
    else:
        start, step, stop = pieces
    if step == 0:
        raise ValueError("CreativePlotStudio scan step cannot be zero.")
    if (stop - start) * step < 0:
        return []
    count = int(math.floor((stop - start) / step + 1e-12)) + 1
    return [start + index * step for index in range(max(0, count))]


def parse_scan_values(value: object, *, numeric: bool = False) -> list[object]:
    if value is None or value == "":
        return []
    if isinstance(value, Sequence) and not isinstance(value, (str, bytes)):
        values = list(value)
    elif isinstance(value, Mapping):
        raise ValueError("CreativePlotStudio scan values must be a scalar, sequence, or JSON array.")
    elif numeric and isinstance(value, (int, float)):
        values = [value]
    else:
        text = str(value).strip()
        if text.startswith("["):
            try:
                decoded = json.loads(text)
            except json.JSONDecodeError as exc:
                # MATLAB-style numeric vectors use spaces rather than JSON commas.
                if not numeric or not text.endswith("]"):
                    raise ValueError(f"Invalid CreativePlotStudio scan JSON: {exc.msg}.") from exc
                values = [part for part in re.split(r"[,;\s]+", text[1:-1].strip()) if part]
            else:
                values = decoded if isinstance(decoded, list) else [decoded]
        elif numeric and (expanded := _matlab_range(text)) is not None:
            values = expanded
        elif numeric:
            values = [part for part in re.split(r"[,;\s]+", text) if part]
        else:
            values = [part.strip() for part in re.split(r"[,;\n]+", text) if part.strip()]
    if not numeric:
        return values
    parsed: list[float] = []
    for item in values:
        expanded = _matlab_range(str(item))
        if expanded is not None:
            parsed.extend(expanded)
        else:
            parsed.append(float(item))
    if any(not math.isfinite(item) or item <= 0 for item in parsed):
        raise ValueError("CreativePlotStudio resolution scan values must be finite and positive.")
    return [int(round(item)) for item in parsed]


def _base_selection(params: Mapping[str, object]) -> CatalogSelection:
    domain = normalize_domain(params.get("domain", "art"))
    category, project = find_item(
        domain,
        str(params.get("category", "")),
        str(params.get("project", "")),
    )
    return CatalogSelection(domain, category, project)


def _selections(params: Mapping[str, object]) -> list[CatalogSelection]:
    source = params.get("projects") or params.get("composite") or params.get("selection")
    if source:
        return parse_composite_input(source, normalize_domain(params.get("domain", "art")))
    project = params.get("project")
    if isinstance(project, Sequence) and not isinstance(project, (str, bytes)):
        return parse_composite_input(project, normalize_domain(params.get("domain", "art")))
    return [_base_selection(params)]


def _extra_scan(params: Mapping[str, object]) -> dict[str, list[object]]:
    source = params.get("parameter_scan")
    if not source:
        return {}
    if isinstance(source, str):
        try:
            source = json.loads(source)
        except json.JSONDecodeError as exc:
            raise ValueError(f"Invalid CreativePlotStudio parameter_scan JSON: {exc.msg}.") from exc
    if not isinstance(source, Mapping):
        raise ValueError("CreativePlotStudio parameter_scan must be a mapping or JSON object.")
    scans: dict[str, list[object]] = {}
    for key, value in source.items():
        values = parse_scan_values(value, numeric=key == "resolution")
        if values:
            scans[str(key)] = values
    return scans


def iter_parameter_scan(params: Mapping[str, object]) -> list[dict[str, object]]:
    selections = _selections(params)
    styles = parse_scan_values(params.get("styles")) or parse_scan_values(params.get("style")) or ["default"]
    resolutions = (
        parse_scan_values(params.get("resolutions"), numeric=True)
        or parse_scan_values(params.get("resolution"), numeric=True)
        or [90000]
    )
    extra = _extra_scan(params)
    extra_keys = tuple(extra)
    extra_rows = product(*(extra[key] for key in extra_keys)) if extra_keys else [()]
    extra_rows = list(extra_rows)

    rows: list[dict[str, object]] = []
    for selection, style, resolution, extra_values in product(
        selections, styles, resolutions, extra_rows
    ):
        row = dict(params)
        row.pop("projects", None)
        row.pop("styles", None)
        row.pop("resolutions", None)
        row.pop("composite", None)
        row.pop("selection", None)
        row.pop("parameter_scan", None)
        row.update(selection.as_params())
        row["style"] = normalize_variant(style)
        row["resolution"] = int(resolution)
        row.update(zip(extra_keys, extra_values))
        rows.append(row)
    return rows
