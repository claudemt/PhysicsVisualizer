from __future__ import annotations

from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
import shutil
import subprocess
from typing import Any

import numpy as np


@dataclass(frozen=True)
class StyleTokens:
    background: str = "#e9edf3"
    panel_background: str = "#fbfcfe"
    canvas_background: str = "#ffffff"
    control_background: str = "#f7f9fc"
    field_background: str = "#ffffff"
    primary: str = "#2563eb"
    accent: str = "#0f766e"
    primary_text: str = "#ffffff"
    secondary: str = "#e5e7eb"
    text: str = "#111827"
    muted_text: str = "#5f6b7a"
    border: str = "#d3dae6"
    error: str = "#b42318"
    font_family: str = "Segoe UI"
    math_font_family: str = "Latin Modern Roman"
    mono_font_family: str = "Consolas"
    font_size: int = 10
    small_font_size: int = 9
    button_font_size: int = 10
    axes_font_size: int = 11
    axes_title_size: int = 13
    line_width: float = 1.2
    panel_radius: int = 6
    control_padding: int = 8
    layout_margin: int = 8
    layout_spacing: int = 6
    dense_spacing: int = 4
    compact_label_min_width: int = 70
    form_label_min_width: int = 96
    label_max_width: int = 190
    compact_label_max_width: int = 156
    field_min_width: int = 128
    list_min_height: int = 108
    textarea_min_height: int = 88
    matrix_min_height: int = 118
    textarea_max_height: int = 172
    matrix_max_height: int = 220
    control_panel_min_width: int = 500
    control_panel_max_width: int = 820
    preview_canvas_min_width: int = 520
    preview_canvas_min_height: int = 400


TOKENS = StyleTokens()


@lru_cache(maxsize=1)
def latin_modern_fonts() -> dict[str, str]:
    """Register Latin Modern fonts when TeX Live provides them.

    Matplotlib does not discover TeX Live's OpenType tree on Windows.  The
    project therefore registers the fonts explicitly and falls back to the
    bundled STIX family when Latin Modern is unavailable.
    """
    from matplotlib import font_manager

    requested = {
        "roman": "lmroman10-regular.otf",
        "italic": "lmroman10-italic.otf",
        "bold": "lmroman10-bold.otf",
        "math": "latinmodern-math.otf",
    }
    found: dict[str, str] = {}
    kpsewhich = shutil.which("kpsewhich")
    if kpsewhich:
        try:
            result = subprocess.run(
                [kpsewhich, requested["roman"]],
                check=False,
                capture_output=True,
                text=True,
                timeout=4,
            )
        except (OSError, subprocess.SubprocessError):
            result = None
        roman = Path(result.stdout.strip()) if result is not None else Path()
        if roman.is_file():
            local_candidates = {
                "roman": roman,
                "italic": roman.with_name(requested["italic"]),
                "bold": roman.with_name(requested["bold"]),
                "math": roman.parent.parent / "lm-math" / requested["math"],
            }
            for key, candidate in local_candidates.items():
                if candidate.is_file():
                    font_manager.fontManager.addfont(str(candidate))
                    found[key] = str(candidate)
        for key, filename in requested.items():
            if key in found:
                continue
            try:
                result = subprocess.run(
                    [kpsewhich, filename],
                    check=False,
                    capture_output=True,
                    text=True,
                    timeout=4,
                )
            except (OSError, subprocess.SubprocessError):
                continue
            candidate = Path(result.stdout.strip())
            if candidate.is_file():
                font_manager.fontManager.addfont(str(candidate))
                found[key] = str(candidate)
    return found


def plot_font_family() -> str:
    """Return the canonical plot font, with a deterministic bundled fallback."""
    return "Latin Modern Roman" if latin_modern_fonts().get("roman") else "STIXGeneral"


def math_font_family() -> str:
    """Return the OpenType math family used for every mathtext expression."""
    return "Latin Modern Math" if latin_modern_fonts().get("math") else "STIXGeneral"


def plot_font_path(weight: str = "roman") -> str | None:
    """Return a registered font path for Pillow/export helpers."""
    fonts = latin_modern_fonts()
    return fonts.get(weight) or fonts.get("roman")


def tokens() -> StyleTokens:
    return TOKENS


def hex_to_rgb01(value: str) -> tuple[float, float, float]:
    value = value.strip().lstrip("#")
    return tuple(int(value[i:i + 2], 16) / 255 for i in (0, 2, 4))  # type: ignore[return-value]


def apply_matplotlib_defaults() -> None:
    import matplotlib as mpl

    t = tokens()
    family = plot_font_family()
    math_family = math_font_family()
    serif_stack = [family, "STIXGeneral", "DejaVu Serif"]
    mpl.rcParams.update({
        "figure.facecolor": t.canvas_background,
        "axes.facecolor": t.canvas_background,
        "savefig.facecolor": t.canvas_background,
        "font.family": ["serif"],
        "font.serif": serif_stack,
        "font.sans-serif": [t.font_family, "Arial", "DejaVu Sans"],
        "font.size": t.axes_font_size,
        "axes.titlesize": t.axes_title_size,
        "axes.labelsize": t.axes_font_size,
        "xtick.labelsize": t.axes_font_size - 1,
        "ytick.labelsize": t.axes_font_size - 1,
        "legend.fontsize": t.axes_font_size - 1,
        "axes.edgecolor": "#364152",
        "axes.labelcolor": t.text,
        "xtick.color": t.text,
        "ytick.color": t.text,
        "text.color": t.text,
        "grid.color": "#d8dee9",
        "grid.linewidth": 0.65,
        "mathtext.fontset": "custom" if family == "Latin Modern Roman" else "stix",
        "mathtext.rm": family,
        "mathtext.it": f"{family}:italic",
        "mathtext.bf": f"{family}:bold",
        "mathtext.cal": "STIXGeneral",
        "mathtext.fallback": "stix",
        "axes.titleweight": "normal",
        "axes.titlepad": 10,
        "xaxis.labellocation": "center",
        "yaxis.labellocation": "center",
        "axes.unicode_minus": False,
        "legend.frameon": True,
        "figure.autolayout": False,
        "figure.constrained_layout.use": False,
        "figure.dpi": 110,
        "savefig.dpi": 220,
    })


def heatmap_cmap_name() -> str:
    """Return the one canonical colormap for scalar heatmaps."""
    return visible_cmap_name()


def matlab_parula_cmap_name() -> str:
    """Register a MATLAB-like parula map for 3D scalar surfaces."""
    import matplotlib as mpl
    from matplotlib.colors import LinearSegmentedColormap

    name = "physics_matlab_parula"
    if name not in mpl.colormaps:
        anchors = np.array([
            [0.2081, 0.1663, 0.5292],
            [0.2116, 0.1898, 0.5777],
            [0.2123, 0.2386, 0.6534],
            [0.1959, 0.3162, 0.7315],
            [0.1636, 0.3953, 0.7569],
            [0.1284, 0.4692, 0.7065],
            [0.1253, 0.5415, 0.6353],
            [0.1806, 0.6072, 0.5352],
            [0.3128, 0.6594, 0.4069],
            [0.5167, 0.6934, 0.2635],
            [0.7624, 0.7012, 0.1378],
            [0.9763, 0.7495, 0.0964],
        ])
        mpl.colormaps.register(LinearSegmentedColormap.from_list(name, anchors, N=256))
    return name


def resolve_heatmap_cmap(cmap: Any = None, *, colorbar: bool = True) -> Any:
    """Normalize scalar heatmaps to the shared visible-spectrum style.

    Binary/mask images without a colorbar may stay grayscale. Any scalar field
    with a colorbar uses the visible-spectrum colormap, including signed fields;
    limits, not a diverging blue-red palette, should communicate sign.
    """
    from matplotlib.colors import ListedColormap

    if isinstance(cmap, np.ndarray):
        return ListedColormap(cmap)
    key = "" if cmap is None else str(cmap).strip().lower()
    if not colorbar and key in {"gray", "grey", "binary", "bw"}:
        return "gray"
    return heatmap_cmap_name()


def apply_axes(ax: Any, title: str | None = None, xlabel: str | None = None,
               ylabel: str | None = None, zlabel: str | None = None,
               grid: bool = False, box: bool = True,
               aspect: str | None = None) -> Any:
    t = tokens()
    family = plot_font_family()
    ax.set_facecolor(t.canvas_background)
    ax.tick_params(labelsize=t.axes_font_size - 1, colors=t.text)
    tick_labels = [*ax.get_xticklabels(), *ax.get_yticklabels()]
    if hasattr(ax, "get_zticklabels"):
        tick_labels.extend(ax.get_zticklabels())
    for label in tick_labels:
        label.set_fontfamily(family)
        label.set_fontsize(t.axes_font_size - 1)
        label.set_color(t.text)
    for spine in ax.spines.values():
        spine.set_visible(box)
        spine.set_color("#364152")
        spine.set_linewidth(0.9)
    if grid:
        ax.grid(True, alpha=0.7)
    else:
        ax.grid(False)
    if title:
        ax.set_title(title, fontsize=t.axes_title_size, fontfamily=family, fontweight="normal", pad=10)
    if xlabel:
        ax.set_xlabel(xlabel, fontsize=t.axes_font_size, fontfamily=family, labelpad=6)
    if ylabel:
        ax.set_ylabel(ylabel, fontsize=t.axes_font_size, fontfamily=family, labelpad=6)
    if zlabel and hasattr(ax, "set_zlabel"):
        ax.set_zlabel(zlabel, fontsize=t.axes_font_size, fontfamily=family, labelpad=6)
    axis_labels = [ax.title, ax.xaxis.label, ax.yaxis.label]
    if hasattr(ax, "zaxis"):
        axis_labels.append(ax.zaxis.label)
    for text in axis_labels:
        text.set_fontfamily(family)
        text.set_color(t.text)
    if aspect:
        ax.set_aspect(aspect)
    return ax


def apply_legend(legend: Any) -> Any:
    if legend is None:
        return legend
    t = tokens()
    frame = legend.get_frame()
    frame.set_facecolor(t.panel_background)
    frame.set_edgecolor(t.border)
    frame.set_alpha(0.92)
    for text in legend.get_texts():
        text.set_fontsize(t.axes_font_size - 1)
        text.set_fontfamily(plot_font_family())
        text.set_color(t.text)
    return legend


def apply_colorbar(colorbar: Any, label: str | None = None) -> Any:
    t = tokens()
    colorbar.ax.tick_params(labelsize=t.axes_font_size - 1, colors=t.text)
    for tick in colorbar.ax.get_yticklabels() + colorbar.ax.get_xticklabels():
        tick.set_fontfamily(plot_font_family())
        tick.set_fontsize(t.axes_font_size - 1)
        tick.set_color(t.text)
    if label:
        colorbar.set_label(label, fontsize=t.axes_font_size, labelpad=7)
        colorbar.ax.yaxis.label.set_fontfamily(plot_font_family())
        colorbar.ax.yaxis.label.set_color(t.text)
        colorbar.ax.xaxis.label.set_fontfamily(plot_font_family())
        colorbar.ax.xaxis.label.set_color(t.text)
    return colorbar


def notes_css() -> str:
    t = tokens()
    return (
        f"body{{font-family:{t.math_font_family},serif;max-width:980px;margin:32px auto;"
        f"padding:0 28px;line-height:1.62;color:{t.text};background:#fff;}}"
        "h1,h2,h3{font-weight:600;} code,pre{font-family:Consolas,monospace;}"
    )


def visible_colormap(n: int = 256) -> np.ndarray:
    wl = np.linspace(380.0, 780.0, int(n))
    rgb = np.zeros((wl.size, 3), dtype=float)
    for i, w in enumerate(wl):
        if 380 <= w < 440:
            r, g, b = -(w - 440) / 60, 0, 1
        elif w < 490:
            r, g, b = 0, (w - 440) / 50, 1
        elif w < 510:
            r, g, b = 0, 1, -(w - 510) / 20
        elif w < 580:
            r, g, b = (w - 510) / 70, 1, 0
        elif w < 645:
            r, g, b = 1, -(w - 645) / 65, 0
        else:
            r, g, b = 1, 0, 0
        if w < 420:
            factor = 0.3 + 0.7 * (w - 380) / 40
        elif w <= 700:
            factor = 1.0
        else:
            factor = 0.3 + 0.7 * (780 - w) / 80
        rgb[i] = np.power(np.clip([r, g, b], 0, 1) * factor, 0.8)
    return np.clip(rgb, 0, 1)


def visible_cmap_name() -> str:
    """Return the shared MATLAB-like visible-spectrum colormap name."""
    import matplotlib as mpl
    from matplotlib.colors import ListedColormap

    name = "physics_visible_spectrum"
    if name not in mpl.colormaps:
        mpl.colormaps.register(ListedColormap(visible_colormap(256), name=name))
    return name


def qt_stylesheet(font_family: str | None = None) -> str:
    t = tokens()
    qt_font = font_family or t.font_family
    cp = t.control_padding
    return f"""
    QMainWindow, QDialog {{
        background: {t.background};
        color: {t.text};
        font-family: "{qt_font}", "Microsoft YaHei UI", "Microsoft YaHei", "Segoe UI", "Arial", sans-serif;
        font-size: {t.font_size}pt;
    }}
    QWidget#ControlRail, QWidget#PreviewArea, QFrame#Panel, QFrame#ControlSection, QGroupBox {{
        background: {t.panel_background};
        border: 1px solid {t.border};
        border-radius: {t.panel_radius}px;
    }}
    QFrame#ControlSection {{
        border-color: #dfe5ef;
    }}
    QFrame#ActionBar {{
        background: transparent;
        border: none;
    }}
    QGroupBox {{
        margin-top: {cp + 6}px;
        padding-top: {cp + 2}px;
        font-weight: 600;
        border-color: #dfe5ef;
    }}
    QGroupBox::title {{
        subcontrol-origin: margin;
        left: {cp}px;
        padding: 0 {cp // 2}px;
        color: {t.text};
    }}
    QWidget#PreviewArea {{
        background: #ffffff;
    }}
    QStatusBar {{
        background: {t.panel_background};
        border-top: 1px solid {t.border};
        color: {t.muted_text};
    }}
    QProgressBar {{
        background: {t.control_background};
        border: 1px solid {t.border};
        border-radius: 4px;
        text-align: center;
        height: 18px;
    }}
    QProgressBar::chunk {{
        background: {t.primary};
        border-radius: 3px;
    }}
    QLabel#ProjectTitle {{
        font-size: 15pt;
        font-weight: 650;
        color: {t.text};
        padding: 1px 2px 0 2px;
        background: transparent;
    }}
    QLabel#ProjectDescription {{
        color: {t.muted_text};
        padding: 0 2px 4px 2px;
        background: transparent;
    }}
    QLabel#PreviewPlaceholder {{
        color: {t.muted_text};
        font-size: 12pt;
        background: #ffffff;
    }}
    QLabel#FieldLabel {{
        background: transparent;
        color: {t.text};
        font-size: {t.small_font_size}pt;
    }}
    QPushButton {{
        background: {t.secondary};
        border: 1px solid {t.border};
        border-radius: 5px;
        padding: {cp - 2}px {cp + 2}px;
    }}
    QPushButton:hover {{
        background: #d7deea;
    }}
    QPushButton[role="primary"] {{
        background: {t.primary};
        color: {t.primary_text};
        border-color: {t.primary};
    }}
    QPushButton[role="primary"]:hover {{
        background: #1d4ed8;
    }}
    QPushButton:disabled {{
        color: {t.muted_text};
        background: {t.control_background};
    }}
    QLineEdit, QComboBox, QSpinBox, QDoubleSpinBox, QTextEdit, QListWidget {{
        background: {t.field_background};
        border: 1px solid {t.border};
        border-radius: 4px;
        padding: {cp // 2}px;
        min-height: 24px;
    }}
    QLineEdit:focus, QComboBox:focus, QSpinBox:focus, QDoubleSpinBox:focus, QTextEdit:focus, QListWidget:focus {{
        border: 1px solid {t.primary};
    }}
    QTextEdit {{
        selection-background-color: {t.primary};
    }}
    QTabWidget::pane {{
        border: 1px solid {t.border};
        background: {t.panel_background};
        top: -1px;
        border-radius: 5px;
    }}
    QTabBar::tab {{
        background: #e8edf5;
        border: 1px solid {t.border};
        border-bottom: none;
        padding: 7px 12px;
        margin-right: 2px;
        border-top-left-radius: 5px;
        border-top-right-radius: 5px;
    }}
    QTabBar::tab:selected {{
        background: {t.panel_background};
        color: {t.primary};
        font-weight: 600;
    }}
    QTabBar::tab:!selected {{
        color: {t.muted_text};
    }}
    QTabBar::tab:west {{
        border: 1px solid {t.border};
        border-right: none;
        padding: 10px 8px;
        margin-right: 0;
        margin-bottom: 2px;
        border-top-left-radius: 5px;
        border-bottom-left-radius: 5px;
        border-top-right-radius: 0;
    }}
    QTabBar::tab:west:selected {{
        background: {t.panel_background};
        color: {t.primary};
    }}
    QScrollArea#PreviewScroll, QScrollArea#ControlsScroll {{
        border: none;
        background: transparent;
    }}
    QTextEdit#NotesPanel {{
        background: #fbfcfe;
        border-radius: 6px;
    }}
    """
