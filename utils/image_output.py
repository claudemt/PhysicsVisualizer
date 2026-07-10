from __future__ import annotations

import json
import math
import re
from collections.abc import Sequence as SequenceABC
from functools import lru_cache
from pathlib import Path
from typing import Iterable, Mapping, Sequence

import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageOps

from . import style


def slug(text: str) -> str:
    value = re.sub(r"[^a-zA-Z0-9]+", "_", str(text).strip().lower())
    value = re.sub(r"_+", "_", value).strip("_")
    return value or "result"


def clean_label(text: str) -> str:
    value = str(text).strip()
    value = re.sub(r"^\s*\d{1,4}(?:[_\-\s.:)]+)", "", value)
    value = re.sub(r"^\s*#+\d+\s*", "", value)
    value = re.sub(r"\$|\\mathrm|\\", "", value)
    value = re.sub(r"[{}_^]", " ", value)
    value = re.sub(r"\s+", " ", value).strip()
    return value or "image"


def ensure_dir(path: str | Path) -> Path:
    p = Path(path)
    p.mkdir(parents=True, exist_ok=True)
    return p


def indexed_name(base: str, index: int = 1, suffix: str = ".png") -> str:
    text = str(base)
    name = Path(text).name
    ext = Path(name).suffix
    if ext.lower() in {".png", ".jpg", ".jpeg", ".tif", ".tiff", ".bmp", ".gif", ".svg", ".pdf"}:
        name = Path(name).stem
    return f"{index:02d}_{slug(clean_label(name))}{suffix}"


def figure_label(fig, fallback: str = "image") -> str:
    filename = getattr(fig, "_physics_filename", "")
    if filename:
        return clean_label(str(filename))
    return clean_label(figure_title(fig, fallback))


def figure_title(fig, fallback: str = "image") -> str:
    title = getattr(fig, "_physics_title", "")
    if not title and getattr(fig, "_suptitle", None):
        title = fig._suptitle.get_text()
    if not title:
        axes = [ax for ax in getattr(fig, "axes", []) if getattr(ax, "get_title", None)]
        for ax in axes:
            candidate = ax.get_title()
            if candidate:
                title = candidate
                break
    value = str(title or fallback).strip()
    value = re.sub(r"^\s*\d{1,4}(?:[_\-\s.:)]+)", "", value)
    return value or "image"


def figure_export_title(fig, fallback: str = "image") -> str:
    """Return a figure-level export title, never a first-panel title."""
    title = getattr(fig, "_physics_title", "")
    if not title and getattr(fig, "_suptitle", None):
        title = fig._suptitle.get_text()
    return str(title or fallback).strip() or fallback


def _is_blank(pixel: tuple, background: tuple = (255, 255, 255), tol: int = 12) -> bool:
    return all(abs(a - b) <= tol for a, b in zip(pixel[:3], background))


def _non_background_bbox(image: Image.Image, background: tuple = (255, 255, 255),
                         tolerance: int = 10) -> tuple[int, int, int, int] | None:
    """Return the bbox of pixels that differ from a known background color."""
    arr = np.asarray(image.convert("RGB"), dtype=np.int16)
    bg = np.asarray(background[:3], dtype=np.int16)
    diff = np.max(np.abs(arr - bg), axis=2)
    mask = diff > int(tolerance)
    if not np.any(mask):
        return None
    ys, xs = np.nonzero(mask)
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def smart_crop(path: str | Path, margin: int = 12, background: tuple = (255, 255, 255),
               crop_top: bool = True, tolerance: int = 10) -> Path:
    """Crop to the non-background pixel bbox while keeping a safety margin.

    Unlike corner-pixel or fixed-band cropping, this scans the whole raster for
    non-white pixels, so axes titles, tick labels, colorbar text, and thin line
    art all participate in the crop box.
    """
    p = Path(path)
    image = Image.open(p).convert("RGB")
    bbox = _non_background_bbox(image, background, tolerance)
    if not bbox:
        return p
    left, top, right, bottom = bbox
    left = max(0, left - margin)
    top = max(0, top - margin) if crop_top else 0
    right = min(image.width, right + margin)
    bottom = min(image.height, bottom + margin)
    if right - left < 32 or bottom - top < 32:
        return p
    image.crop((left, top, right, bottom)).save(p)
    return p


def _load_title_font(size: int, *, bold: bool = False):
    registered = style.plot_font_path("bold" if bold else "roman")
    candidates = [registered] if registered else []
    candidates.extend(("STIXGeneral.ttf", "times.ttf", "timesbd.ttf", "DejaVuSerif.ttf"))
    for candidate in candidates:
        try:
            return ImageFont.truetype(candidate, size)
        except (OSError, TypeError):
            continue
    return ImageFont.load_default()


def _wrapped_lines(draw: ImageDraw.ImageDraw, text: str, font, max_width: int) -> list[str]:
    words = str(text).split()
    if not words:
        return []
    lines: list[str] = []
    current = words[0]
    for word in words[1:]:
        candidate = f"{current} {word}"
        bbox = draw.textbbox((0, 0), candidate, font=font)
        if bbox[2] - bbox[0] <= max_width:
            current = candidate
        else:
            lines.append(current)
            current = word
    lines.append(current)
    return lines


def _measure_lines(draw: ImageDraw.ImageDraw, lines: Sequence[str], font) -> tuple[int, int]:
    if not lines:
        return (0, 0)
    widths: list[int] = []
    heights: list[int] = []
    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=font)
        widths.append(bbox[2] - bbox[0])
        heights.append(bbox[3] - bbox[1])
    return max(widths), sum(heights) + max(0, len(lines) - 1) * 6


def _draw_centered_lines(draw: ImageDraw.ImageDraw, lines: Sequence[str], font, y: int,
                         width: int, fill: tuple[int, int, int], line_gap: int = 6) -> int:
    cursor = y
    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=font)
        line_w = bbox[2] - bbox[0]
        line_h = bbox[3] - bbox[1]
        draw.text(((width - line_w) // 2, cursor), line, fill=fill, font=font)
        cursor += line_h + line_gap
    return cursor


@lru_cache(maxsize=256)
def _mathtext_line(text: str, size: int, bold: bool, color: tuple[int, int, int]) -> Image.Image:
    """Rasterize mixed plain/math text with the same font stack as plots."""
    from matplotlib.font_manager import FontProperties
    from matplotlib.mathtext import MathTextParser

    style.apply_matplotlib_defaults()
    prop = FontProperties(
        family=style.plot_font_family(),
        size=size,
        weight="bold" if bold else "normal",
    )
    try:
        parsed = MathTextParser("agg").parse(str(text), dpi=100, prop=prop)
        alpha = Image.fromarray(np.asarray(parsed.image))
        rendered = Image.new("RGBA", alpha.size, (*color, 0))
        rendered.putalpha(alpha)
        return rendered
    except (ValueError, RuntimeError):
        font = _load_title_font(size, bold=bold)
        measure = ImageDraw.Draw(Image.new("L", (1, 1)))
        bbox = measure.textbbox((0, 0), str(text), font=font)
        rendered = Image.new("RGBA", (max(1, bbox[2] - bbox[0]), max(1, bbox[3] - bbox[1])), (*color, 0))
        draw = ImageDraw.Draw(rendered)
        draw.text((-bbox[0], -bbox[1]), str(text), font=font, fill=(*color, 255))
        return rendered


def _measure_math_lines(lines: Sequence[str], size: int, bold: bool, line_gap: int = 6) -> tuple[int, int]:
    images = [_mathtext_line(line, size, bold, (0, 0, 0)) for line in lines]
    if not images:
        return (0, 0)
    return max(image.width for image in images), sum(image.height for image in images) + line_gap * (len(images) - 1)


def _paste_centered_math_lines(base: Image.Image, lines: Sequence[str], size: int, bold: bool,
                               y: int, color: tuple[int, int, int], line_gap: int = 6) -> int:
    cursor = y
    for line in lines:
        rendered = _mathtext_line(line, size, bold, color)
        base.paste(rendered, ((base.width - rendered.width) // 2, cursor), rendered)
        cursor += rendered.height + line_gap
    return cursor


def add_title_band(path: str | Path, title: str | None, subtitle: str | None = None) -> Path:
    if not title:
        return Path(path)
    p = Path(path)
    image = Image.open(p).convert("RGB")
    title_size = max(22, min(34, image.width // 22))
    sub_size = max(14, min(20, image.width // 36))
    title_font = _load_title_font(title_size, bold=True)
    sub_font = _load_title_font(sub_size)
    measure = ImageDraw.Draw(Image.new("RGB", (image.width, 1), "white"))
    max_text_w = max(80, image.width - 36)
    title_lines = _wrapped_lines(measure, title, title_font, max_text_w)
    subtitle_lines = _wrapped_lines(measure, subtitle, sub_font, max_text_w) if subtitle else []
    _, title_h = _measure_math_lines(title_lines, title_size, True)
    _, subtitle_h = _measure_math_lines(subtitle_lines, sub_size, False)
    band_h = max(72, title_h + subtitle_h + (18 if subtitle_lines else 0) + 30)
    band = Image.new("RGB", (image.width, band_h), "white")
    y = max(10, (band_h - title_h - subtitle_h - (12 if subtitle_lines else 0)) // 2)
    y = _paste_centered_math_lines(band, title_lines, title_size, True, y, (18, 24, 38))
    if subtitle:
        _paste_centered_math_lines(band, subtitle_lines, sub_size, False, y + 6, (90, 100, 120), line_gap=4)
    out = Image.new("RGB", (image.width, image.height + band_h), "white")
    out.paste(band, (0, 0))
    out.paste(image, (0, band_h))
    out.save(p)
    return p


def save_figure(fig, folder: str | Path, name: str, dpi: int = 300,
                title_band: str | None = None, crop: bool = True) -> Path:
    folder_path = ensure_dir(folder)
    path = folder_path / name
    hidden = _hide_redundant_export_titles(fig, title_band)
    try:
        fig.savefig(path, dpi=dpi, facecolor="white", bbox_inches="tight", pad_inches=0.16)
    finally:
        for artist in hidden:
            artist.set_visible(True)
    if crop:
        smart_crop(path)
    add_title_band(path, title_band)
    return path


def _hide_redundant_export_titles(fig, title_band: str | None) -> list:
    """Hide only titles duplicated by the external band while saving."""
    if not title_band:
        return []
    target = slug(clean_label(title_band))
    hidden = []
    suptitle = getattr(fig, "_suptitle", None)
    if suptitle is not None and slug(clean_label(suptitle.get_text())) == target:
        suptitle.set_visible(False)
        hidden.append(suptitle)
    plot_axes = [ax for ax in getattr(fig, "axes", []) if ax.get_label() != "<colorbar>"]
    if len(plot_axes) == 1:
        axes_title = plot_axes[0].title
        axes_key = slug(clean_label(axes_title.get_text()))
        if axes_title.get_text() and (axes_key == target or target.endswith(axes_key)):
            axes_title.set_visible(False)
            hidden.append(axes_title)
    return hidden


def layout_rows(layout: str | int | Sequence[int] | None, n: int) -> list[int]:
    if n <= 0:
        return []
    if isinstance(layout, SequenceABC) and not isinstance(layout, (str, bytes)):
        values = [int(value) for value in layout if int(value) > 0]
        return _bounded_rows(values, n) or layout_rows("auto", n)
    if layout is None:
        layout_text = "auto"
    else:
        layout_text = str(layout).strip().lower()
    if not layout_text or layout_text == "auto":
        target_aspect = 1.45
        max_cols = min(n, max(1, int(math.ceil(math.sqrt(n) * 1.6))))
        best_score: tuple[float, float, int] | None = None
        cols = 1
        for candidate_cols in range(1, max_cols + 1):
            candidate_rows = int(math.ceil(n / candidate_cols))
            unused = candidate_cols * candidate_rows - n
            aspect = candidate_cols / max(candidate_rows, 1)
            score = (unused * 2.0 + abs(aspect - target_aspect), candidate_rows, candidate_cols)
            if best_score is None or score < best_score:
                best_score = score
                cols = candidate_cols
        out = [cols] * int(math.ceil(n / cols))
        out[-1] = n - cols * (len(out) - 1)
        return [value for value in out if value > 0]
    if layout_text.startswith("columns:"):
        layout_text = layout_text.split(":", 1)[1]
    if any(separator in layout_text for separator in ("+", ",", " ")):
        parts = [part for part in re.split(r"[+,\s]+", layout_text) if part.strip()]
        try:
            values = [int(float(part)) for part in parts]
        except ValueError:
            return layout_rows("auto", n)
        values = [value for value in values if value > 0]
        return _bounded_rows(values, n) or layout_rows("auto", n)
    try:
        cols = max(1, int(round(float(layout_text))))
    except ValueError:
        return layout_rows("auto", n)
    out = [cols] * int(math.ceil(n / cols))
    out[-1] = n - cols * (len(out) - 1)
    return [value for value in out if value > 0]


def _bounded_rows(values: Sequence[int], n: int) -> list[int]:
    if not values:
        return []
    if sum(values) < n:
        values = [*values, n - sum(values)]
    total = 0
    out = []
    for value in values:
        if total >= n:
            break
        keep = min(int(value), n - total)
        if keep > 0:
            out.append(keep)
            total += keep
    return out


def compose_grid(paths: Sequence[str | Path], out_path: str | Path,
                 columns: int | str | Sequence[int] | None = None, padding: int = 18,
                 title: str | None = None, subtitle: str | None = None) -> Path:
    """Compose images into a grid with an optional overall title band.

    The row syntax follows the MATLAB studio helper: ``auto``, ``columns:N``,
    a plain column count, or explicit row counts such as ``3+2+1``.
    """
    images = [Image.open(p).convert("RGB") for p in paths]
    if not images:
        raise ValueError("compose_grid requires at least one image")
    row_counts = layout_rows(columns, len(images))
    columns_count = max(row_counts)
    rows = len(row_counts)
    cell_w = max(img.width for img in images)
    cell_h = max(img.height for img in images)

    header_h = 0
    header_img: Image.Image | None = None
    if title:
        header_w = columns_count * cell_w + (columns_count + 1) * padding
        measure = ImageDraw.Draw(Image.new("RGB", (header_w, 1), "white"))
        title_size = max(28, min(42, header_w // 28))
        sub_size = max(16, min(22, header_w // 54))
        title_font = _load_title_font(title_size, bold=True)
        sub_font = _load_title_font(sub_size)
        title_lines = _wrapped_lines(measure, title, title_font, max(100, header_w - 2 * padding))
        subtitle_lines = _wrapped_lines(measure, subtitle, sub_font, max(100, header_w - 2 * padding)) if subtitle else []
        _, title_h = _measure_math_lines(title_lines, title_size, True)
        _, subtitle_h = _measure_math_lines(subtitle_lines, sub_size, False)
        header_h = max(80, title_h + subtitle_h + (18 if subtitle_lines else 0) + 32)
        header_img = Image.new("RGB", (columns_count * cell_w + (columns_count + 1) * padding, header_h), "white")
        y = max(10, (header_h - title_h - subtitle_h - (12 if subtitle_lines else 0)) // 2)
        y = _paste_centered_math_lines(header_img, title_lines, title_size, True, y, (18, 24, 38))
        if subtitle:
            _paste_centered_math_lines(header_img, subtitle_lines, sub_size, False, y + 6, (90, 100, 120), line_gap=4)

    grid_h = rows * cell_h + (rows + 1) * padding
    out_w = columns_count * cell_w + (columns_count + 1) * padding
    out_h = grid_h + header_h
    out = Image.new("RGB", (out_w, out_h), "white")
    if header_img is not None:
        out.paste(header_img, (0, 0))

    image_index = 0
    for r, row_cols in enumerate(row_counts):
        row_w = row_cols * cell_w + max(0, row_cols - 1) * padding
        x0 = max(padding, (out_w - row_w) // 2)
        for c in range(row_cols):
            if image_index >= len(images):
                break
            img = images[image_index]
            x = x0 + c * (cell_w + padding) + (cell_w - img.width) // 2
            y = header_h + padding + r * (cell_h + padding) + (cell_h - img.height) // 2
            out.paste(img, (x, y))
            image_index += 1
    p = Path(out_path)
    ensure_dir(p.parent)
    out.save(p)
    return p


def composite_layout_from_params(params: Mapping[str, object] | None) -> object | None:
    """Read a project-neutral MATLAB-style composite row layout parameter."""
    if not params:
        return None
    for key in ("composite_layout", "grid_layout", "row_layout", "composite_columns"):
        value = params.get(key)
        if value not in (None, ""):
            return value
    return None


def _format_params_text(params: Mapping[str, object]) -> str:
    lines = []
    for key, value in params.items():
        if isinstance(value, (list, tuple)):
            lines.append(f"{key} = {list(value)}")
        else:
            lines.append(f"{key} = {value}")
    return "\n".join(lines) + "\n"


def _reproduce_script(project_name: str, tab_key: str, params: Mapping[str, object]) -> str:
    """Generate a runnable Python reproduction script for a GUI/CLI export."""
    params_json = json.dumps(dict(params), indent=2, ensure_ascii=False, default=str)
    return f'''"""Auto-generated reproduction script for {project_name} / {tab_key}.

Re-run with:
    python reproduce.py --output <folder>
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def _add_repo_root() -> None:
    anchors = [Path.cwd().resolve(), Path(__file__).resolve().parent]
    for anchor in anchors:
        for candidate in (anchor, *anchor.parents):
            if (candidate / "app" / "project_registry.py").is_file():
                if str(candidate) not in sys.path:
                    sys.path.insert(0, str(candidate))
                return


_add_repo_root()

from app.project_registry import get_project
from utils import image_output


PARAMS = json.loads({params_json!r})


def reproduce(output_dir: str | Path | None = None) -> list[Path]:
    project = get_project({project_name!r})
    params = dict(project.defaults)
    params.update(PARAMS)
    bundle = project.render(params)
    out = image_output.ensure_dir(output_dir or Path(__file__).resolve().parent)
    return image_output.export_bundle(
        {project_name!r},
        bundle.figures,
        out,
        params,
        bundle.report,
        tab_key={tab_key!r},
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default="")
    args = parser.parse_args()
    paths = reproduce(args.output or None)
    for p in paths:
        print(p)
'''


def export_bundle(project_name: str, figures: Iterable, output_dir: str | Path,
                  params: Mapping[str, object] | None = None,
                  notes: str | None = None,
                  *,
                  tab_key: str | None = None,
                  composite_title: str | None = None,
                  write_reproduce: bool = True) -> list[Path]:
    """Export figures, composite, parameters, notes, and reproduce code.

    - Each figure keeps the MATLAB-style in-canvas titles and labels; no extra
      external project-title band is added by default.
    - ``parameters.txt`` (human-readable) and ``parameters.json`` are written.
    - ``reproduce.py`` is written when ``write_reproduce`` is true and ``tab_key``
      is provided, so GUI/CLI exports ship a runnable reproduction script.
    """
    folder = ensure_dir(Path(output_dir))
    exported: list[Path] = []
    figures = list(figures)
    for i, fig in enumerate(figures, start=1):
        label = figure_label(fig, project_name)
        exported.append(save_figure(fig, folder, indexed_name(label, i), title_band=None))
    if len(exported) > 1:
        exported.append(compose_grid(
            exported,
            folder / "composite.png",
            columns=composite_layout_from_params(params),
        ))
    if params is not None:
        (folder / "parameters.json").write_text(json.dumps(params, indent=2, ensure_ascii=False, default=str), encoding="utf-8")
        (folder / "parameters.txt").write_text(_format_params_text(params), encoding="utf-8")
    if notes:
        (folder / "notes.md").write_text(notes, encoding="utf-8")
    if write_reproduce and tab_key:
        (folder / "reproduce.py").write_text(_reproduce_script(project_name, tab_key, params or {}), encoding="utf-8")
    manifest_outputs = [path.name for path in exported]
    for name in ("parameters.txt", "parameters.json", "notes.md", "reproduce.py"):
        if (folder / name).exists():
            manifest_outputs.append(name)
    manifest = {
        "project": project_name,
        "tab": tab_key,
        "parameters": dict(params or {}),
        "outputs": manifest_outputs,
        "notes": notes or "",
    }
    (folder / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False, default=str), encoding="utf-8")
    return exported


def write_manifest(folder: str | Path, project: str, example: str,
                   params: Iterable[Mapping[str, object]],
                   outputs: Iterable[str | Path],
                   notes: str = "") -> Path:
    target = ensure_dir(folder) / "manifest.json"
    payload = {
        "project": project,
        "example": example,
        "params": list(params),
        "outputs": [str(Path(path).name) for path in outputs],
        "notes": notes,
    }
    target.write_text(json.dumps(payload, indent=2, ensure_ascii=False, default=str), encoding="utf-8")
    return target


def export_rendered_figures(project: str, example: str, bundle,
                            folder: str | Path, params: Mapping[str, object],
                            start_index: int = 1,
                            title_band: str | None = None,
                            close: bool = True) -> list[Path]:
    from matplotlib import pyplot as plt

    out_dir = ensure_dir(folder)
    paths: list[Path] = []
    for offset, fig in enumerate(bundle.figures):
        index = start_index + offset
        name = indexed_name(figure_label(fig, f"{example}_{bundle.title}"), index)
        paths.append(save_figure(fig, out_dir, name, title_band=title_band))
    if close:
        plt.close("all")
    return paths


def save_gif(frames: Sequence[str | Path], out_path: str | Path, duration: float = 0.08) -> Path:
    if not frames:
        raise ValueError("save_gif requires at least one frame")
    p = Path(out_path)
    ensure_dir(p.parent)
    images = [Image.open(frame).convert("P", palette=Image.ADAPTIVE) for frame in frames]
    images[0].save(
        p,
        save_all=True,
        append_images=images[1:],
        duration=max(1, int(duration * 1000)),
        loop=0,
        optimize=False,
    )
    return p


def save_animation(frames: Sequence[str | Path], out_path: str | Path, fps: int = 12) -> Path:
    if not frames:
        raise ValueError("save_animation requires at least one frame")
    p = Path(out_path)
    ensure_dir(p.parent)
    try:
        import imageio.v2 as imageio
        import numpy as np

        arrays = _normalized_animation_arrays(frames)
        imageio.mimsave(p, [np.asarray(array) for array in arrays], fps=fps)
        return p
    except Exception:
        fallback = p.with_suffix(".gif")
        return save_gif(frames, fallback, duration=1 / max(fps, 1))


def _normalized_animation_arrays(frames: Sequence[str | Path], block_size: int = 16) -> list[Image.Image]:
    images = [Image.open(frame).convert("RGB") for frame in frames]
    width = max(image.width for image in images)
    height = max(image.height for image in images)
    if block_size > 1:
        width = int(math.ceil(width / block_size) * block_size)
        height = int(math.ceil(height / block_size) * block_size)
    normalized: list[Image.Image] = []
    for image in images:
        left = (width - image.width) // 2
        top = (height - image.height) // 2
        right = width - image.width - left
        bottom = height - image.height - top
        normalized.append(ImageOps.expand(image, border=(left, top, right, bottom), fill="white"))
    return normalized
