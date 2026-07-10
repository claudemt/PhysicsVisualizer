from __future__ import annotations

from dataclasses import dataclass


RECT_BOUNDARY_OPTIONS = ("FFFF", "SSSS", "CCCC", "SSFF", "CFFF", "CSFF", "SCFS", "CFSF")
CIRC_BOUNDARY_OPTIONS = ("C", "S", "F")


@dataclass(frozen=True)
class RectBoundaryMeta:
    code: str
    top: str
    left: str
    bottom: str
    right: str
    is_all_free: bool
    is_all_simply: bool
    is_all_clamped: bool
    title_tag: str
    file_tag: str


def rect_boundary_options() -> tuple[str, ...]:
    return RECT_BOUNDARY_OPTIONS


def circ_boundary_options() -> tuple[str, ...]:
    return CIRC_BOUNDARY_OPTIONS


def rect_boundary_meta(boundary: str = "FFFF") -> RectBoundaryMeta:
    aliases = {"free": "FFFF", "simply": "SSSS", "clamped": "CCCC"}
    code = aliases.get(str(boundary).strip().lower(), str(boundary).strip().upper())
    if len(code) != 4 or any(ch not in "CSF" for ch in code):
        raise ValueError("Rectangular boundary must be a 4-letter ULDR code over C, S, F.")
    return RectBoundaryMeta(
        code=code,
        top=code[0],
        left=code[1],
        bottom=code[2],
        right=code[3],
        is_all_free=code == "FFFF",
        is_all_simply=code == "SSSS",
        is_all_clamped=code == "CCCC",
        title_tag=code,
        file_tag=code.lower(),
    )


def edge_zero_mask(meta: RectBoundaryMeta) -> dict[str, bool]:
    return {
        "left": meta.left != "F",
        "right": meta.right != "F",
        "bottom": meta.bottom != "F",
        "top": meta.top != "F",
    }
