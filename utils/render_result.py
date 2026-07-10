from __future__ import annotations

from dataclasses import dataclass, field
from typing import Callable, Sequence
import re

import matplotlib.pyplot as plt
import numpy as np

from . import style


@dataclass
class RenderBundle:
    title: str
    figures: list = field(default_factory=list)
    report: str = ""


def new_figure(title: str, rows: int = 1, cols: int = 1, size: tuple[float, float] = (10, 6),
               *, visible_title: bool = False):
    style.apply_matplotlib_defaults()
    fig, axes = plt.subplots(rows, cols, figsize=size, squeeze=False)
    set_figure_title(fig, title, visible=visible_title)
    return fig, axes


def clean_title(title: str | None) -> str:
    if not title:
        return ""
    value = str(title).strip()
    value = re.sub(r"^\s*\d{1,4}(?:[_\-.:\)]\s*|\s+)", "", value)
    return value.strip()


def math_text(text: str | None) -> str:
    """Normalize visible plot text to a MATLAB-like mathtext string."""
    clean = clean_title(text)
    if not clean:
        return ""
    if any(ord(ch) > 127 for ch in clean):
        return clean
    if "$" in clean:
        parts = re.split(r"(\$[^$]*\$)", clean)
        fragments = []
        for part in parts:
            if not part:
                continue
            if part.startswith("$") and part.endswith("$"):
                body = _normalize_math_body(part[1:-1].strip())
                if body:
                    fragments.append(body)
            else:
                body = _plain_math_fragment(part)
                if body:
                    fragments.append(body)
        return "$" + r"\ ".join(fragments) + "$" if fragments else ""
    semantic = _semantic_math_text(clean)
    if semantic:
        return semantic
    if _looks_like_math_expression(clean):
        return "$" + _normalize_math_body(clean) + "$"
    return "$" + _plain_math_fragment(clean) + "$"


def _semantic_math_text(text: str) -> str:
    """Convert common physics variable prose into compact math notation."""
    normalized = text.strip()
    units = {
        "deg": r"\mathrm{(deg)}",
        "rad": r"\mathrm{(rad)}",
        "GHz": r"\mathrm{(GHz)}",
        "mm": r"\mathrm{(mm)}",
        "m": r"\mathrm{(m)}",
        "pixel": r"\mathrm{(pixel)}",
        "waves": r"\mathrm{(waves)}",
    }
    greek = {
        "alpha": r"\alpha",
        "gamma": r"\gamma",
        "theta": r"\theta",
        "theta_i": r"\theta_i",
        "theta_a": r"\theta_a",
        "omega": r"\omega",
    }
    match = re.fullmatch(r"([A-Za-z]+(?:_[A-Za-z0-9]+)?)\s*\(([A-Za-z]+)\)", normalized)
    if match and match.group(1) in greek and match.group(2) in units:
        return "$" + greek[match.group(1)] + r"\ " + units[match.group(2)] + "$"
    match = re.fullmatch(r"([A-Z]{1,4})\s*\(fc=([0-9.]+)\s*GHz\)", normalized)
    if match:
        return "$" + rf"\mathrm{{{match.group(1)}}}\ (f_c={match.group(2)}\ \mathrm{{GHz}})" + "$"
    return ""


def _looks_like_math_expression(text: str) -> bool:
    """Recognize compact symbolic labels without treating prose as algebra."""
    if re.search(r"\s", text):
        return False
    if not re.fullmatch(r"[A-Za-z0-9_{}^+\-*/=|().,\\]+", text):
        return False
    return (
        len(text) == 1
        or any(marker in text for marker in ("_", "^", "=", "\\", "(", ")", "|"))
    )


def _plain_math_fragment(text: str) -> str:
    value = text.strip()
    if not value:
        return ""
    for raw, escaped in (
        ("\\", r"\backslash "),
        ("_", r"\_"),
        ("%", r"\%"),
        ("#", r"\#"),
        ("&", r"\&"),
    ):
        value = value.replace(raw, escaped)
    value = re.sub(r"\s+", r"\\ ", value)
    return r"\mathrm{" + value + "}"


def _normalize_math_body(text: str) -> str:
    text = re.sub(r"\[([A-Za-z][A-Za-z0-9/*^\-]*)\]", r"[\\mathrm{\1}]", text)
    return text


def _text_identity(text: str | None) -> str:
    value = clean_title(text)
    value = re.sub(r"\\(?:mathrm|mathbf|mathit)\s*", "", value)
    return re.sub(r"[^A-Za-z0-9]+", "", value).lower()


def set_figure_title(fig, title: str | None, *, visible: bool = True) -> str:
    """Set the figure-level title and export title metadata once."""
    clean = clean_title(title)
    fig._physics_title = clean  # type: ignore[attr-defined]
    current = getattr(fig, "_suptitle", None)
    if current is not None:
        current.remove()
        fig._suptitle = None  # type: ignore[attr-defined]
    if clean and visible:
        fig.suptitle(
            math_text(clean),
            fontsize=style.tokens().axes_title_size + 1,
            y=0.985,
            fontfamily=style.plot_font_family(),
            fontweight="normal",
        )
    return clean


def set_axis_text(ax, title: str | None = None, xlabel: str | None = None,
                  ylabel: str | None = None, zlabel: str | None = None,
                  *, grid: bool = False, box: bool = True,
                  aspect: str | None = None):
    """Project-facing helper for axes title/labels using the shared style."""
    return style.apply_axes(
        ax,
        title=math_text(title),
        xlabel=math_text(xlabel),
        ylabel=math_text(ylabel),
        zlabel=math_text(zlabel),
        grid=grid,
        box=box,
        aspect=aspect,
    )


def apply_colorbar(colorbar, label: str | None = None):
    return style.apply_colorbar(colorbar, math_text(label))


def apply_legend(legend):
    if legend is not None:
        for text in legend.get_texts():
            text.set_text(math_text(text.get_text()))
    return style.apply_legend(legend)


def finish_figure(fig, *, title: str | None = None, reserve_title: bool = True,
                  hspace: float = 0.34, wspace: float = 0.30,
                  left: float = 0.10, right: float | None = None,
                  bottom: float = 0.11, top: float | None = None):
    """Shared layout finalizer.

    This replaces project-local ``tight_layout(rect=...)`` calls. It leaves
    stable title space, avoids aggressive title cropping, and restyles all axes,
    legends, and colorbars with the shared LaTeX-like font contract.
    """
    style.apply_matplotlib_defaults()
    if title is not None:
        set_figure_title(fig, title)
    plot_axes = [
        ax for ax in getattr(fig, "axes", [])
        if getattr(ax, "get_label", lambda: "")() != "<colorbar>"
    ]
    if len(plot_axes) == 1 and plot_axes[0].get_title():
        current = getattr(fig, "_suptitle", None)
        if current is not None and _text_identity(current.get_text()) == _text_identity(plot_axes[0].get_title()):
            current.remove()
            fig._suptitle = None  # type: ignore[attr-defined]
    if top is None:
        top = 0.88 if reserve_title and getattr(fig, "_suptitle", None) else 0.94
    for ax in getattr(fig, "axes", []):
        if getattr(ax, "get_label", lambda: "")() == "<colorbar>":
            continue
        style.apply_axes(ax)
        legend = ax.get_legend()
        if legend is not None:
            style.apply_legend(legend)
    if right is None:
        has_colorbar = any(
            getattr(ax, "get_label", lambda: "")() == "<colorbar>"
            for ax in getattr(fig, "axes", [])
        )
        right = 0.84 if has_colorbar else 0.94
    fig.subplots_adjust(left=left, right=right, bottom=bottom, top=top, wspace=wspace, hspace=hspace)
    return fig


def image(ax, data, title: str = "", cmap: str | np.ndarray | None = "viridis",
          extent=None, colorbar: bool = True, label: str | None = None,
          aspect: str = "auto"):
    cmap = style.resolve_heatmap_cmap(cmap, colorbar=colorbar)
    im = ax.imshow(data, origin="lower", cmap=cmap, extent=extent, aspect=aspect)
    set_axis_text(ax, title=title, box=True)
    if colorbar:
        cb = ax.figure.colorbar(im, ax=ax, fraction=0.038, pad=0.035)
        apply_colorbar(cb, label)
    return im


def curve(ax, x, y, title: str = "", xlabel: str = "", ylabel: str = "",
          label: str | None = None, grid: bool = True, **kwargs):
    (line,) = ax.plot(x, y, label=math_text(label) if label else label, linewidth=style.tokens().line_width, **kwargs)
    set_axis_text(ax, title=title, xlabel=xlabel, ylabel=ylabel, grid=grid)
    if label:
        apply_legend(ax.legend(loc="best"))
    return line


def surface(ax, x, y, z, title: str = "", cmap: str = "viridis"):
    cmap = style.resolve_heatmap_cmap(cmap, colorbar=True)
    surf = ax.plot_surface(x, y, z, cmap=cmap, linewidth=0, antialiased=True, alpha=0.95)
    set_axis_text(ax, title=title)
    cb = ax.figure.colorbar(surf, ax=ax, shrink=0.72, pad=0.08)
    apply_colorbar(cb)
    return surf


def vector_field(ax, x, y, u, v, title: str = "", density: int = 3):
    sl = (slice(None, None, density), slice(None, None, density))
    mag = np.hypot(u, v)
    image(ax, mag, title=title, cmap=style.heatmap_cmap_name(), colorbar=True, label="magnitude")
    ax.quiver(x[sl], y[sl], u[sl], v[sl], color="black", alpha=0.65, scale=35)
    return ax


def render_many(title: str, renderers: Sequence[Callable], cols: int = 2,
                size: tuple[float, float] = (11, 7)) -> RenderBundle:
    rows = int(np.ceil(len(renderers) / cols))
    fig, axes = new_figure(title, rows, cols, size)
    flat = axes.ravel()
    for ax, renderer in zip(flat, renderers):
        renderer(ax)
    for ax in flat[len(renderers):]:
        ax.axis("off")
    finish_figure(fig, hspace=0.46 if rows > 1 else 0.34)
    return RenderBundle(title=title, figures=[fig])


def grid(n: int = 240, extent: float = 1.0):
    x = np.linspace(-extent, extent, n)
    y = np.linspace(-extent, extent, n)
    return x, y, np.meshgrid(x, y)


def report(title: str, lines: list[str]) -> str:
    return "# " + title + "\n\n" + "\n".join(f"- {line}" for line in lines)
