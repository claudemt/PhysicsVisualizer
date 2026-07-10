from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Mapping, Sequence

import numpy as np

from .catalog import get_family, get_variant
from .tuple_parser import parse_tuple_scan


@dataclass(frozen=True)
class PreviewRef:
    """One 1-based preview reference, matching MATLAB's run/file indexing."""

    run_index: int
    item_index: int

    @classmethod
    def from_value(cls, value: object) -> "PreviewRef":
        if isinstance(value, cls):
            return value
        if isinstance(value, Mapping):
            run = value.get("run_index", value.get("run", 0))
            item = value.get("item_index", value.get("item", value.get("file_index", 0)))
        elif isinstance(value, Sequence) and not isinstance(value, (str, bytes)) and len(value) == 2:
            run, item = value
        else:
            raise ValueError(f"Invalid history preview reference: {value!r}")
        ref = cls(int(run), int(item))
        if ref.run_index < 1 or ref.item_index < 1:
            raise ValueError("History preview references are 1-based positive indices.")
        return ref

    def to_dict(self) -> dict[str, int]:
        return {"run_index": self.run_index, "item_index": self.item_index}


@dataclass(frozen=True)
class RunSnapshot:
    """Normalized, serializable parameters for one generated Special Functions run."""

    params: dict[str, Any]

    @classmethod
    def from_params(cls, params: Mapping[str, object]) -> "RunSnapshot":
        return cls(normalize_run_params(params))


@dataclass(frozen=True)
class RunHistory:
    """Immutable collection used by project callers to preserve multi-run selection."""

    runs: tuple[RunSnapshot, ...] = ()

    @classmethod
    def from_payload(cls, payload: object) -> "RunHistory":
        if isinstance(payload, cls):
            return payload
        if isinstance(payload, Mapping):
            source = payload
            payload = source.get("runs", source.get("history_runs"))
            if payload is None:
                run_keys = sorted(
                    (key for key in source if str(key).startswith("run_")),
                    key=lambda key: str(key),
                )
                payload = [source[key] for key in run_keys]
        if payload is None:
            return cls()
        if isinstance(payload, (str, bytes)) or not isinstance(payload, Sequence):
            raise ValueError("history_runs must be a sequence of run parameter mappings.")
        snapshots = []
        for run in payload:
            if isinstance(run, RunSnapshot):
                snapshots.append(run)
            elif isinstance(run, Mapping):
                snapshots.append(RunSnapshot.from_params(run))
            else:
                raise ValueError("Each history run must be a parameter mapping.")
        return cls(tuple(snapshots))

    def append(self, params: Mapping[str, object]) -> "RunHistory":
        return RunHistory((*self.runs, RunSnapshot.from_params(params)))

    def selected_runs(self, refs: Sequence[object]) -> tuple[tuple[RunSnapshot, ...], tuple[PreviewRef, ...]]:
        parsed = tuple(PreviewRef.from_value(ref) for ref in refs)
        selected: list[RunSnapshot] = []
        slots: dict[int, int] = {}
        remapped: list[PreviewRef] = []
        for ref in parsed:
            if ref.run_index > len(self.runs):
                raise ValueError(f"History run {ref.run_index} does not exist.")
            if ref.run_index not in slots:
                slots[ref.run_index] = len(selected) + 1
                selected.append(self.runs[ref.run_index - 1])
            remapped.append(PreviewRef(slots[ref.run_index], ref.item_index))
        return tuple(selected), tuple(remapped)

    def export_params(
        self,
        refs: Sequence[object],
        *,
        layout: str = "auto",
        selected_files: Sequence[str] = (),
    ) -> dict[str, object]:
        """Build the legacy-shaped ``export``/``run_01`` parameter structure."""
        runs, remapped = self.selected_runs(refs)
        names = list(selected_files)
        if names and len(names) != len(remapped):
            raise ValueError("selected_files must match the number of selected history previews.")
        if not names:
            names = [f"{index:02d}_run_{ref.run_index:02d}_item_{ref.item_index:02d}.png"
                     for index, ref in enumerate(remapped, start=1)]
        output: dict[str, object] = {
            "export": {
                "layout": str(layout or "auto"),
                "selected_files": names,
                "selected_refs": [ref.to_dict() for ref in remapped],
            }
        }
        for index, run in enumerate(runs, start=1):
            output[f"run_{index:02d}"] = dict(run.params)
        return output


def normalize_run_params(params: Mapping[str, object]) -> dict[str, Any]:
    """Normalize current GUI and legacy reproduction parameter spellings."""
    family = get_family(str(params.get("family", "bessel")))
    variant = get_variant(family.key, str(params.get("variant", family.variants[0].key)))
    tuple_scan = str(params.get("tuple_scan", params.get("param_text", variant.default_tuple))).strip()
    if not tuple_scan and variant.param_labels:
        tuple_scan = variant.default_tuple
    xmin, xmax = _range_params(params, family.default_xrange)
    crop = _crop_params(params)
    legend = _legend_location(params)
    expected = len(variant.param_labels)
    args = parse_tuple_scan(tuple_scan, expected_cols=expected) if expected else np.empty((1, 0))
    layout = str(params.get("layout_text", params.get("preview_columns", "auto")) or "auto")
    return {
        "family": family.key,
        "variant": variant.key,
        "tuple_scan": tuple_scan,
        "param_text": tuple_scan,
        "arg_matrix": args.tolist(),
        "x_range": f"{xmin:g} {xmax:g}",
        "xmin": xmin,
        "xmax": xmax,
        "crop": crop,
        "crop_mode": crop["mode"],
        "y_min": crop["y_range"][0] if crop["y_range"] else "",
        "y_max": crop["y_range"][1] if crop["y_range"] else "",
        "layout_text": layout,
        "preview_columns": layout,
        "render_options": {"legend_location": legend},
        "legend_location": legend,
    }


def is_history_payload(params: Mapping[str, object]) -> bool:
    return "history_runs" in params or any(str(key).startswith("run_") for key in params)


def _range_params(params: Mapping[str, object], fallback: tuple[float, float]) -> tuple[float, float]:
    if "xmin" in params and "xmax" in params:
        try:
            xmin, xmax = float(params["xmin"]), float(params["xmax"])
            if xmax > xmin:
                return xmin, xmax
        except (TypeError, ValueError):
            pass
    raw = str(params.get("x_range", "")).replace(",", " ").strip()
    try:
        pieces = [float(piece) for piece in raw.split()[:2]]
        if len(pieces) == 2 and pieces[1] > pieces[0]:
            return pieces[0], pieces[1]
    except ValueError:
        pass
    return fallback


def _crop_params(params: Mapping[str, object]) -> dict[str, object]:
    supplied = params.get("crop")
    if isinstance(supplied, Mapping):
        mode = str(supplied.get("mode", "auto")).lower()
        values = supplied.get("y_range", ())
    else:
        mode = str(params.get("crop_mode", "auto")).lower()
        values = params.get("y_range", (params.get("y_min", ""), params.get("y_max", "")))
    if mode == "manual":
        mode = "yrange"
    if isinstance(values, str):
        values = values.replace(",", " ").split()
    try:
        low, high = (float(value) for value in values)
        y_range: list[float] = [low, high] if high > low else []
    except (TypeError, ValueError):
        y_range = []
    return {"mode": mode if mode in {"auto", "yrange", "none"} else "auto", "y_range": y_range}


def _legend_location(params: Mapping[str, object]) -> str:
    options = params.get("render_options")
    if isinstance(options, Mapping):
        value = options.get("legend_location", params.get("legend_location", "northwest"))
    else:
        value = params.get("legend_location", "northwest")
    return str(value or "northwest").lower()
