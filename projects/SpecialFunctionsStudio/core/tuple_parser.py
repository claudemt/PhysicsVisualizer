from __future__ import annotations

from itertools import product

import numpy as np


def parse_tuple_scan(text: str, expected_cols: int | None = None) -> np.ndarray:
    raw = str(text or "").strip()
    if not raw:
        raw = "(0:5)"
    raw = _strip_outer(raw)
    columns = [_parse_column(part) for part in _split_top_level(raw)]
    if expected_cols is not None:
        if expected_cols == 1:
            # MATLAB treats ``(0,1,1.5,3,5)`` as a scan of one parameter,
            # rather than five columns.  Multi-parameter scans remain
            # explicitly separated by their expected tuple arity.
            columns = [[value for column in columns for value in column]]
        elif len(columns) < expected_cols:
            columns.extend([[0.0]] * (expected_cols - len(columns)))
        elif len(columns) > expected_cols:
            columns = columns[:expected_cols]
    rows = list(product(*columns))
    return np.asarray(rows, dtype=float)


def _strip_outer(text: str) -> str:
    text = text.strip()
    if text.startswith("(") and text.endswith(")") and _balanced(text[1:-1]):
        return text[1:-1].strip()
    return text


def _balanced(text: str) -> bool:
    depth = 0
    for char in text:
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth < 0:
                return False
    return depth == 0


def _split_top_level(text: str) -> list[str]:
    parts: list[str] = []
    depth = 0
    start = 0
    for idx, char in enumerate(text):
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
        elif char == "," and depth == 0:
            parts.append(text[start:idx].strip())
            start = idx + 1
    tail = text[start:].strip()
    if tail:
        parts.append(tail)
    return parts or ["0"]


def _parse_column(text: str) -> list[float]:
    item = _strip_outer(text)
    if "," in item:
        values: list[float] = []
        for part in _split_top_level(item):
            values.extend(_parse_column(part))
        return values
    if ":" in item:
        pieces = [float(p.strip()) for p in item.split(":") if p.strip()]
        if len(pieces) == 2:
            start, stop = pieces
            step = 1.0 if stop >= start else -1.0
        elif len(pieces) == 3:
            start, step, stop = pieces
        else:
            return [0.0]
        count = int(np.floor((stop - start) / step)) + 1 if step else 1
        return [start + k * step for k in range(max(count, 0))]
    return [float(item)]
