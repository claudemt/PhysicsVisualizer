from __future__ import annotations

from collections.abc import Callable

import numpy as np
from matplotlib.colors import ListedColormap
from matplotlib.collections import LineCollection

from projects.CreativePlotStudio.app.catalog import find_item, normalize_domain, slugify
from projects.CreativePlotStudio.core.variants import ContentVariant, resolve_variant
from utils import render_result as rr


def _sample(params: dict[str, object], default: int = 90000) -> int:
    value = int(float(params.get("resolution", default)))
    if value <= 0:
        raise ValueError("CreativePlotStudio resolution must be positive.")
    return max(600, value)


def _side(sample: int, maximum: int, minimum: int = 96) -> int:
    return max(minimum, min(maximum, int(round(np.sqrt(sample) * 2.0))))


def _points(sample: int, maximum: int, minimum: int = 600) -> int:
    return max(minimum, min(maximum, sample))


def _rng(key: str) -> np.random.Generator:
    seed = sum((i + 1) * ord(ch) for i, ch in enumerate(key)) % (2**32)
    return np.random.default_rng(seed)


def _palette(stops: list[tuple[float, float, float]], n: int = 256) -> ListedColormap:
    x = np.linspace(0, 1, len(stops))
    q = np.linspace(0, 1, n)
    arr = np.column_stack([np.interp(q, x, [c[i] for c in stops]) for i in range(3)])
    return ListedColormap(np.clip(arr, 0, 1))


TWILIGHT = _palette([(0.03, 0.05, 0.14), (0.13, 0.21, 0.55), (0.25, 0.66, 0.72), (0.96, 0.76, 0.38), (0.80, 0.18, 0.25)])
NEBULA = _palette([(0.01, 0.02, 0.08), (0.18, 0.08, 0.40), (0.46, 0.12, 0.62), (0.86, 0.27, 0.55), (1.00, 0.76, 0.45)])
EMBER = _palette([(0.00, 0.00, 0.02), (0.18, 0.03, 0.02), (0.58, 0.09, 0.02), (1.00, 0.48, 0.05), (1.00, 0.92, 0.45)])
NEON = _palette([(0.02, 0.02, 0.08), (0.00, 0.72, 1.00), (0.82, 0.14, 1.00), (1.00, 0.92, 0.20)])
CORAL = _palette([(0.04, 0.05, 0.12), (0.08, 0.32, 0.36), (0.14, 0.58, 0.46), (0.88, 0.62, 0.35), (1.00, 0.86, 0.62)])
BALANCE = _palette([(0.00, 0.00, 0.08), (0.08, 0.28, 0.70), (0.95, 0.95, 0.92), (0.76, 0.16, 0.13), (0.20, 0.00, 0.00)])

_STYLE_CMAPS = {
    "twilight": TWILIGHT,
    "nebula": NEBULA,
    "ember": EMBER,
    "neon": NEON,
    "coral": CORAL,
    "balance": BALANCE,
}


def _matlab_title(slug: str, title: str, variant: ContentVariant | None = None) -> str:
    """Return MATLAB renderer titles for catalog items with legacy names."""
    if slug == "fireworks":
        if str(title).startswith("Fireworks --"):
            return title
        palette = (variant.palette if variant is not None else "").replace("_", " ")
        return f"Fireworks -- {palette}" if palette else "Fireworks"
    legacy = {
        "bitwise_fractal": "Bitwise pseudo-fractal",
        "tablecloth": "Perspective tablecloth",
        "music_score": "Bitwise music score",
        "ice_cream_soft_serve": "Ice Cream -- Soft Serve",
        "ice_cream_bouquet": "Ice Cream -- Bouquet",
        "sakura_tree": "Sakura tree",
        "moonlit_mountains": "Moonlit Mountains",
        "crystal_cluster": "Crystal cluster",
        "crystal_heart": "Crystal heart",
        "rose_ball": "Rose ball",
    }
    return legacy.get(slug, title)


def _apply_content_variant(fig, variant: ContentVariant) -> None:
    """Apply artwork-only variant tokens after a renderer has made its axes."""
    cmap = _STYLE_CMAPS[variant.palette]
    for ax in fig.axes:
        ax.set_facecolor(variant.background)
        for image in ax.images:
            image.set_cmap(cmap)
        for line in ax.lines:
            line.set_linewidth(max(0.15, line.get_linewidth() * variant.line_width_scale))
            line.set_alpha(variant.line_alpha)
        for collection in ax.collections:
            if hasattr(collection, "set_cmap"):
                collection.set_cmap(cmap)
            if hasattr(collection, "get_segments") and hasattr(collection, "set_color"):
                segments = collection.get_segments()
                if len(segments):
                    colors = cmap(np.linspace(0, 1, len(segments)))
                    colors[:, 3] = variant.line_alpha
                    collection.set_color(colors)
                if hasattr(collection, "set_linewidth"):
                    collection.set_linewidth(max(0.15, 0.8 * variant.line_width_scale))
        if variant.view is not None and hasattr(ax, "view_init") and ax.name == "3d":
            ax.view_init(elev=variant.view[0], azim=variant.view[1])
        if not variant.native and variant.zoom > 1 and ax.name != "3d":
            x0, x1 = ax.get_xlim()
            y0, y1 = ax.get_ylim()
            cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
            ax.set_xlim(cx + (x0 - cx) / variant.zoom, cx + (x1 - cx) / variant.zoom)
            ax.set_ylim(cy + (y0 - cy) / variant.zoom, cy + (y1 - cy) / variant.zoom)


def _finish(
    ax,
    title: str,
    *,
    equal: bool = True,
    box: bool = False,
    grid: bool = False,
    art_background: str | None = None,
) -> None:
    rr.set_axis_text(ax, title=title, box=box, grid=grid, aspect="equal" if equal else "auto")
    if art_background:
        # These colors encode the rendered artwork, not application chrome.
        ax.set_facecolor(art_background)
    if not box:
        ax.set_xticks([])
        ax.set_yticks([])


def _image(ax, data: np.ndarray, title: str, cmap=TWILIGHT, extent=None, vlim: tuple[float, float] | None = None) -> None:
    im = ax.imshow(data, origin="lower", cmap=cmap, extent=extent, aspect="equal")
    if vlim is not None:
        im.set_clim(*vlim)
    _finish(ax, title)


def _colored_line(ax, x: np.ndarray, y: np.ndarray, cmap=NEBULA, lw: float = 0.8, alpha: float = 0.85) -> None:
    pts = np.column_stack([x, y]).reshape(-1, 1, 2)
    segs = np.concatenate([pts[:-1], pts[1:]], axis=1)
    colors = cmap(np.linspace(0, 1, len(segs)))
    colors[:, 3] = alpha
    ax.add_collection(LineCollection(segs, colors=colors, linewidths=lw))
    ax.autoscale_view()


def _colored_line3(ax, x: np.ndarray, y: np.ndarray, z: np.ndarray, color="#2dd4bf", lw: float = 0.55) -> None:
    ax.plot(x, y, z, color=color, linewidth=lw, alpha=0.9)
    ax.set_axis_off()
    ax.set_box_aspect((np.ptp(x) or 1, np.ptp(y) or 1, np.ptp(z) or 1))


def _escape(ax, title: str, kind: str, n: int = 600, variant: ContentVariant | None = None) -> None:
    configs = {
        "mandelbrot_garden": ((-2.25, 0.75), (-1.35, 1.35), 170, 2.0, TWILIGHT),
        "julia_nebula": ((-1.55, 1.55), (-1.55, 1.55), 190, 2.0, NEBULA),
        "burning_ship_ember": ((-2.35, -1.35), (-0.62, 0.28), 190, 2.0, EMBER),
        "tricorn_mandelbar": ((-2.0, 2.0), (-1.7, 1.7), 180, 2.0, TWILIGHT),
        "phoenix_julia": ((-1.9, 1.9), (-1.6, 1.6), 170, 4.0, NEBULA),
        "multibrot_cubic": ((-1.65, 1.25), (-1.45, 1.45), 170, 2.4, EMBER),
        "celtic_mandelbrot": ((-2.2, 1.2), (-1.6, 1.6), 170, 2.0, TWILIGHT),
        "perpendicular_burning_ship": ((-2.25, 1.25), (-1.75, 1.75), 170, 2.0, EMBER),
    }
    xr, yr, max_iter, escape_r, cmap = configs[kind]
    variant_name = variant.name if variant else "default"
    const = -0.70176 - 0.3842j
    if kind == "mandelbrot_garden" and variant_name == "deep zoom":
        xr, yr, max_iter = (-0.78, -0.70), (0.06, 0.14), 230
    elif kind == "mandelbrot_garden" and variant_name == "seahorse valley":
        xr, yr, max_iter = (-0.86, -0.70), (0.03, 0.18), 220
    elif kind == "julia_nebula" and variant_name == "dragon":
        const = -0.835 - 0.2321j
    elif kind == "julia_nebula" and variant_name == "spiral":
        const = -0.8 + 0.156j
    elif variant_name in {"dark", "electric"} and kind in {"burning_ship_ember", "tricorn_mandelbar", "phoenix_julia"}:
        max_iter = int(round(max_iter * variant.iteration_scale))
        if kind == "burning_ship_ember":
            xr, yr = ((-2.15, -1.55), (-0.35, 0.15)) if variant_name == "dark" else ((-1.92, -1.68), (-0.09, 0.06))
        elif kind == "tricorn_mandelbar" and variant_name == "electric":
            xr, yr = (-1.2, 1.2), (-1.2, 1.2)
    x = np.linspace(xr[0], xr[1], n)
    y = np.linspace(yr[0], yr[1], n)
    xx, yy = np.meshgrid(x, y)
    c = xx + 1j * yy
    z = np.zeros_like(c)
    old = np.zeros_like(c)
    if kind == "julia_nebula":
        z = c.copy()
    elif kind == "phoenix_julia":
        z = c.copy()
        const = -0.5 + 0.54j
        p = -0.45
    escape = np.zeros(c.shape)
    mask = np.ones(c.shape, dtype=bool)
    for k in range(1, max_iter + 1):
        if kind == "burning_ship_ember":
            z[mask] = (np.abs(z[mask].real) + 1j * np.abs(z[mask].imag)) ** 2 + c[mask]
        elif kind == "tricorn_mandelbar":
            z[mask] = np.conj(z[mask]) ** 2 + c[mask]
        elif kind == "julia_nebula":
            z[mask] = z[mask] ** 2 + const
        elif kind == "phoenix_julia":
            zn = z[mask] ** 2 + const + p * old[mask]
            old[mask] = z[mask]
            z[mask] = zn
        elif kind == "multibrot_cubic":
            z[mask] = z[mask] ** 3 + c[mask]
        elif kind == "celtic_mandelbrot":
            z2 = z[mask] ** 2
            z[mask] = np.abs(z2.real) + 1j * z2.imag + c[mask]
        elif kind == "perpendicular_burning_ship":
            z[mask] = (np.abs(z[mask].real) + 1j * z[mask].imag) ** 2 + c[mask]
        else:
            z[mask] = z[mask] ** 2 + c[mask]
        escaped = mask & (np.abs(z) > escape_r)
        escape[escaped] = k - np.log2(np.log(np.abs(z[escaped]) + np.finfo(float).eps))
        mask[escaped] = False
    escape[mask] = max_iter
    _image(ax, escape, title, cmap, extent=(xr[0], xr[1], yr[0], yr[1]))


def _newton(ax, title: str, nova: bool = False, n: int = 560, variant: ContentVariant | None = None) -> None:
    x, y = np.meshgrid(np.linspace(-2, 2, n), np.linspace(-2, 2, n))
    z = x + 1j * y
    alpha = 1.0 if not nova else 0.6 + 0.25j
    conv = np.zeros(z.shape)
    degree = 4 if variant and variant.name == "electric" else 5 if variant and variant.name == "dark" else 3
    roots = np.exp(1j * 2 * np.pi * np.arange(degree) / degree)
    for k in range(1, int(49 * (variant.iteration_scale if variant else 1))):
        dz = alpha * (z**degree - 1) / (degree * z ** (degree - 1) + np.finfo(float).eps)
        z -= dz
        conv[(conv == 0) & (np.abs(dz) < 1e-5)] = k
    stack = np.stack([np.abs(z - r) for r in roots], axis=-1)
    val = np.argmin(stack, axis=-1) + 1 + 0.08 * conv
    _image(ax, val, title, NEON)


def _orbit_trap(ax, n: int = 560) -> None:
    x, y = np.meshgrid(np.linspace(-2.1, 0.8, n), np.linspace(-1.4, 1.4, n))
    c = x + 1j * y
    z = np.zeros_like(c)
    trap = np.full(c.shape, np.inf)
    active = np.ones(c.shape, dtype=bool)
    for _ in range(110):
        z[active] = z[active] * z[active] + c[active]
        trap[active] = np.minimum(trap[active], np.abs(np.abs(z[active]) - 0.5) + 0.2 * np.abs(z[active].real))
        active &= np.abs(z) < 16
    _image(ax, np.log(trap + 1e-5), "Orbit Trap Pearls", TWILIGHT)


def _lyapunov(ax, title: str, n: int = 360, iterations: int = 240, variant: ContentVariant | None = None) -> None:
    variant_name = variant.name if variant else "default"
    lo, seq = (2.7, "AABAB") if variant_name == "electric" else (2.4, "ABBBAB") if variant_name == "dark" else (2.5, "AB")
    a, b = np.meshgrid(np.linspace(lo, 4.0, n), np.linspace(lo, 4.0, n))
    x = np.full_like(a, 0.5)
    lya = np.zeros_like(a)
    iterations = int(round(iterations * (variant.iteration_scale if variant else 1)))
    transient = max(30, iterations // 3)
    for k in range(iterations):
        use_a = seq[k % len(seq)] == "A"
        r = np.where(use_a, a, b)
        x = r * x * (1 - x)
        if k >= transient:
            lya += np.log(np.abs(r * (1 - 2 * x)) + np.finfo(float).eps)
    _image(ax, lya / max(1, iterations - transient), title, BALANCE, vlim=(-1, 1))


def _gray_scott(ax, title: str, n: int = 180, iterations: int = 1000, variant: ContentVariant | None = None) -> None:
    u = np.ones((n, n))
    v = np.zeros((n, n))
    mid = n // 2
    u[mid - 14:mid + 15, mid - 14:mid + 15] = 0.5
    v[mid - 14:mid + 15, mid - 14:mid + 15] = 1.0
    rng = _rng(title)
    u += 0.015 * rng.standard_normal(u.shape)
    v += 0.015 * rng.standard_normal(v.shape)
    variant_name = variant.name if variant else "default"
    f, k = (0.0367, 0.0649) if variant_name == "mitosis" else (0.078, 0.061) if variant_name == "worms" else (0.035, 0.060)
    du, dv = 0.16, 0.08
    iterations = int(round(iterations * (variant.iteration_scale if variant else 1)))
    for step in range(iterations):
        lu = -u + 0.2 * (np.roll(u, 1, 0) + np.roll(u, -1, 0) + np.roll(u, 1, 1) + np.roll(u, -1, 1))
        lu += 0.05 * (np.roll(np.roll(u, 1, 0), 1, 1) + np.roll(np.roll(u, 1, 0), -1, 1) + np.roll(np.roll(u, -1, 0), 1, 1) + np.roll(np.roll(u, -1, 0), -1, 1))
        lv = -v + 0.2 * (np.roll(v, 1, 0) + np.roll(v, -1, 0) + np.roll(v, 1, 1) + np.roll(v, -1, 1))
        lv += 0.05 * (np.roll(np.roll(v, 1, 0), 1, 1) + np.roll(np.roll(v, 1, 0), -1, 1) + np.roll(np.roll(v, -1, 0), 1, 1) + np.roll(np.roll(v, -1, 0), -1, 1))
        uvv = u * v * v
        u += du * lu - uvv + f * (1 - u)
        v += dv * lv + uvv - (f + k) * v
        if step % 200 == 0:
            u = np.clip(u, 0, 1.2)
            v = np.clip(v, 0, 1.2)
    _image(ax, v, title, CORAL)


def _plasma(ax, sample: int = 90000) -> None:
    target = _side(sample, 513, 129)
    power = max(7, min(9, int(round(np.log2(target - 1)))))
    n = 2**power + 1
    rng = _rng("plasma_clouds")
    m = np.zeros((n, n))
    m[np.ix_([0, n - 1], [0, n - 1])] = rng.random((2, 2))
    step = n - 1
    scale = 1.0
    while step > 1:
        half = step // 2
        for i in range(0, n - 1, step):
            for j in range(0, n - 1, step):
                m[i + half, j + half] = np.mean([m[i, j], m[i + step, j], m[i, j + step], m[i + step, j + step]]) + scale * (rng.random() - 0.5)
        for i in range(0, n, half):
            start = half if (i // half) % 2 == 0 else 0
            for j in range(start, n, step):
                vals = []
                if i - half >= 0:
                    vals.append(m[i - half, j])
                if i + half < n:
                    vals.append(m[i + half, j])
                if j - half >= 0:
                    vals.append(m[i, j - half])
                if j + half < n:
                    vals.append(m[i, j + half])
                m[i, j] = float(np.mean(vals)) + scale * (rng.random() - 0.5)
        step = half
        scale *= 0.54
    m = (m - m.min()) / (np.ptp(m) + np.finfo(float).eps)
    _image(ax, m, "Plasma Clouds", NEBULA)


def _barnsley(ax, sample: int = 90000) -> None:
    rng = _rng("barnsley_fern")
    n = _points(sample, 120000)
    x = np.zeros(n)
    y = np.zeros(n)
    for i in range(1, n):
        r = rng.random()
        if r < 0.01:
            x[i], y[i] = 0, 0.16 * y[i - 1]
        elif r < 0.86:
            x[i], y[i] = 0.85 * x[i - 1] + 0.04 * y[i - 1], -0.04 * x[i - 1] + 0.85 * y[i - 1] + 1.6
        elif r < 0.93:
            x[i], y[i] = 0.20 * x[i - 1] - 0.26 * y[i - 1], 0.23 * x[i - 1] + 0.22 * y[i - 1] + 1.6
        else:
            x[i], y[i] = -0.15 * x[i - 1] + 0.28 * y[i - 1], 0.26 * x[i - 1] + 0.24 * y[i - 1] + 0.44
    ax.scatter(x + 0.01 * rng.standard_normal(n), y + 0.01 * rng.standard_normal(n), c=np.linspace(0, 1, n), s=0.2, cmap=_palette([(0, 0.15, 0.05), (0.20, 0.75, 0.25), (0.95, 1, 0.75)]), alpha=0.22, linewidths=0)
    _finish(ax, "Barnsley Fern", art_background="#051008")


def _sierpinski(ax) -> None:
    level = 6
    size = 3**level
    i, j = np.indices((size, size))
    m = np.ones((size, size))
    for s in range(1, level + 1):
        third = 3 ** (s - 1)
        m[((i // third) % 3 == 1) & ((j // third) % 3 == 1)] = 0
    _image(ax, m, "Sierpinski Carpet", NEON)


def _apollonian(ax) -> None:
    colors = _palette([(0.05, 0.08, 0.16), (0.2, 0.65, 0.85), (1, 0.85, 0.42)], 128)
    theta = np.linspace(0, 2 * np.pi, 360)
    ax.plot(np.cos(theta), np.sin(theta), color=colors(1.0), linewidth=1.1)
    queue = [(0.0, 0.0, 1.0)]
    for depth in range(1, 7):
        next_q = []
        for cx, cy, r0 in queue:
            if depth == 1:
                angles = np.arange(3) * 2 * np.pi / 3 + np.pi / 2
                radii = [0.42] * 3
                xs = 0.46 * np.cos(angles)
                ys = 0.46 * np.sin(angles)
            else:
                angles = np.arange(3) * 2 * np.pi / 3 + depth * 0.17
                radii = [r0 * 0.39] * 3
                xs = cx + r0 * 0.55 * np.cos(angles)
                ys = cy + r0 * 0.55 * np.sin(angles)
            for x, y, r in zip(xs, ys, radii):
                if np.hypot(x, y) + r < 1.02 and r > 0.01:
                    ax.fill(x + r * np.cos(theta), y + r * np.sin(theta), color=colors(min(1, 0.08 + depth * 0.13)), alpha=0.20, linewidth=0.4)
                    next_q.append((float(x), float(y), float(r)))
        queue = next_q
    _finish(ax, "Apollonian Gasket", art_background="#05050a")


def _dragon(ax, levy: bool = False) -> None:
    if levy:
        pts = np.array([[0.0, 0.0], [1.0, 0.0]])
        for level in range(15):
            out = np.zeros((pts.shape[0] * 2 - 1, 2))
            out[::2] = pts
            for k in range(pts.shape[0] - 1):
                mid = (pts[k] + pts[k + 1]) / 2
                vec = pts[k + 1] - pts[k]
                normal = np.array([-vec[1], vec[0]]) / 2
                out[2 * k + 1] = mid + normal * (-1 if (k + level) % 2 == 0 else 1)
            pts = out
        title = "Levy C Curve"
    else:
        z = np.array([0 + 0j, 1 + 0j])
        for _ in range(16):
            z = np.concatenate([z, z[-1] + 1j * (z[-2::-1] - z[-1])])
        pts = np.column_stack([z.real, z.imag])
        title = "Dragon Curve"
    pts = (pts - pts.min(axis=0)) / (np.ptp(pts, axis=0) + np.finfo(float).eps)
    _colored_line(ax, pts[:, 0], pts[:, 1], NEBULA, lw=0.55 if not levy else 0.8)
    _finish(ax, title, art_background="#050812")


def _koch(ax) -> None:
    pts = np.array([[0.0, 0.0], [1.0, 0.0], [0.5, np.sqrt(3) / 2], [0.0, 0.0]])
    rot = np.array([[np.cos(np.pi / 3), -np.sin(np.pi / 3)], [np.sin(np.pi / 3), np.cos(np.pi / 3)]])
    for _ in range(5):
        out = []
        for p1, p5 in zip(pts[:-1], pts[1:]):
            v = (p5 - p1) / 3
            out.extend([p1, p1 + v, p1 + v + rot @ v, p1 + 2 * v])
        out.append(pts[-1])
        pts = np.array(out)
    _colored_line(ax, pts[:, 0], pts[:, 1], NEON, lw=1.2)
    _finish(ax, "Koch Snowflake")


def _pythagoras(ax) -> None:
    def rec(p: np.ndarray, s: float, theta: float, depth: int) -> None:
        if depth <= 0 or s < 0.01:
            return
        rot = np.array([[np.cos(theta), -np.sin(theta)], [np.sin(theta), np.cos(theta)]])
        base = np.array([[0, 0], [s, 0], [s, s], [0, s]])
        verts = base @ rot.T + p
        color = np.clip([0.15 + 0.06 * depth, 0.38 + 0.03 * depth, 0.12 + 0.02 * depth], 0, 1)
        ax.fill(verts[:, 0], verts[:, 1], color=color, edgecolor="none", alpha=0.95)
        rec(verts[3], s * np.cos(np.pi / 4), theta + np.pi / 4, depth - 1)
        rec(verts[2] + rot @ np.array([0, s * np.sin(np.pi / 4)]), s * np.sin(np.pi / 4), theta - np.pi / 4, depth - 1)

    rec(np.array([0.0, 0.0]), 1.0, np.pi / 2, 10)
    _finish(ax, "Pythagoras Tree")


def _vicsek(ax) -> None:
    m = np.array([[1]])
    seed = np.array([[0, 1, 0], [1, 1, 1], [0, 1, 0]])
    for _ in range(5):
        m = np.kron(m, seed)
    _image(ax, m, "Vicsek Fractal", _palette([(0.02, 0.02, 0.02), (0.9, 0.92, 0.95)]))


def _dla(ax, sample: int = 90000) -> None:
    rng = _rng("dla_cluster")
    n = 221
    center = n // 2
    grid = np.zeros((n, n), dtype=bool)
    grid[center, center] = True
    launch = 10
    kill = n // 2 - 2
    particles = max(120, min(650, sample // 35))
    walk_steps = max(900, min(4500, sample // 8))
    for _ in range(particles):
        angle = 2 * np.pi * rng.random()
        x = center + int(round(launch * np.cos(angle)))
        y = center + int(round(launch * np.sin(angle)))
        for _ in range(walk_steps):
            step = rng.integers(4)
            x += int(step == 0) - int(step == 1)
            y += int(step == 2) - int(step == 3)
            if x < 2 or x > n - 3 or y < 2 or y > n - 3 or np.hypot(x - center, y - center) > kill:
                angle = 2 * np.pi * rng.random()
                radius = min(launch + 5, kill - 2)
                x = center + int(round(radius * np.cos(angle)))
                y = center + int(round(radius * np.sin(angle)))
            if grid[x - 1:x + 2, y - 1:y + 2].any():
                grid[x, y] = True
                launch = min(max(launch, int(np.ceil(np.hypot(x - center, y - center))) + 6), kill - 2)
                break
    i, j = np.indices((n, n))
    _image(ax, np.hypot(i - center, j - center) * grid, "DLA Cluster", NEON)


def _flower(ax, slug: str, title: str, sample: int = 90000, variant: ContentVariant | None = None) -> None:
    theta = np.linspace(0, 2 * np.pi, _points(sample, 2400))
    if slug == "sakura_tree":
        rng = _rng(slug)
        ax.plot([0, 0], [0, 1.35], color="#5b342b", linewidth=7, solid_capstyle="round")
        for branch in np.linspace(-0.9, 0.9, 13):
            length = 0.52 + 0.25 * rng.random()
            y0 = 0.28 + 0.95 * rng.random()
            x = np.linspace(0, length * np.sin(branch), 60)
            y = y0 + np.linspace(0, length * np.cos(branch) * 0.45, 60)
            ax.plot(x, y, color="#6b3e33", linewidth=2)
            blossoms = 20
            bx = x[-1] + 0.18 * rng.standard_normal(blossoms)
            by = y[-1] + 0.15 * rng.standard_normal(blossoms)
            ax.scatter(bx, by, s=18, color="#f7b7c7", alpha=0.75, linewidths=0)
        _finish(ax, title)
        return
    if slug == "rose_ball":
        side = _side(sample, 260)
        u = np.linspace(0, np.pi, max(64, side // 2))
        v = np.linspace(0, 2 * np.pi, side)
        uu, vv = np.meshgrid(u, v)
        r = 1 + 0.12 * np.sin(8 * uu) * np.cos(11 * vv)
        x = r * np.sin(uu) * np.cos(vv)
        y = r * np.sin(uu) * np.sin(vv)
        z = r * np.cos(uu)
        fig = ax.figure
        fig.delaxes(ax)
        ax = fig.add_subplot(111, projection="3d")
        ax.plot_surface(x, y, z, cmap=_STYLE_CMAPS[(variant.palette if variant else "nebula")], linewidth=0, antialiased=True, alpha=0.95)
        ax.set_axis_off()
        rr.set_axis_text(ax, title=title)
        return
    petals = 6 if slug == "blue_rose" else 8
    r = 0.48 + 0.42 * np.cos(petals * theta) + 0.08 * np.sin(29 * theta)
    color = "#2563eb" if slug == "blue_rose" else "#d94f8c"
    ax.fill(r * np.cos(theta), r * np.sin(theta), color=color, alpha=0.38)
    for scale in np.linspace(0.2, 1.0, 12):
        radius = scale * (0.55 + 0.35 * np.cos(petals * theta + scale))
        ax.plot(radius * np.cos(theta), radius * np.sin(theta), color=color, linewidth=0.8, alpha=0.75)
    _finish(ax, title)


def _art_texture(ax, slug: str, title: str, sample: int = 90000) -> None:
    n = _side(sample, 620, 128)
    x, y = np.indices((n, n))
    if slug == "bitwise_fractal":
        data = np.bitwise_xor(x, y)
        cmap = TWILIGHT
    elif slug == "tablecloth":
        data = np.sin(x / 7) + np.cos(y / 11) + 0.65 * np.sin((x + y) / 17) + 0.25 * np.sin(np.hypot(x - n / 2, y - n / 2) / 5)
        cmap = _palette([(0.95, 0.96, 1), (0.25, 0.45, 0.86), (0.95, 0.28, 0.38), (1, 0.95, 0.75)])
    else:
        staff = np.zeros((n, n))
        margin = max(12, n // 16)
        staff_rows = np.linspace(n * 0.2, n * 0.82, 5, dtype=int)
        for yy in staff_rows:
            for off in range(5):
                spacing = max(2, n // 68)
                staff[yy + off * spacing:yy + off * spacing + max(1, n // 310), margin:n - margin] = 1
        rng = _rng(slug)
        for _ in range(max(24, min(80, sample // 500))):
            cx, cy = rng.integers(margin * 2, n - margin * 2), rng.integers(margin * 2, n - margin * 2)
            radius = rng.integers(max(2, n // 100), max(3, n // 48))
            mask = (x - cy) ** 2 + (y - cx) ** 2 <= radius**2
            staff[mask] = 1
            staff[max(0, cy - n // 15):cy, cx + radius:min(n, cx + radius + max(1, n // 200))] = 1
        data = staff
        cmap = _palette([(1, 1, 0.94), (0.02, 0.02, 0.02)])
    _image(ax, data, _matlab_title(slug, title), cmap)


def _scene(ax, slug: str, title: str, variant: ContentVariant | None = None) -> None:
    rng = _rng(slug)
    if slug == "moonlit_mountains":
        x = np.linspace(0, 1, 800)
        ax.scatter([0.76], [0.82], s=2600, color="#f4f1d0", alpha=0.9)
        for layer, color in enumerate(["#15263d", "#213f5d", "#345c73"]):
            y = 0.25 + 0.12 * layer + 0.11 * np.sin(10 * x + layer) + 0.05 * np.sin(37 * x)
            ax.fill_between(x, y, 0, color=color, alpha=0.95)
        _finish(ax, _matlab_title(slug, title), art_background="#07111f")
    elif slug == "fireworks":
        palette = _STYLE_CMAPS[(variant.palette if variant else "twilight")]
        for _ in range(12):
            cx, cy = rng.uniform(-1, 1), rng.uniform(-0.1, 1)
            angles = np.linspace(0, 2 * np.pi, 80)
            radius = rng.uniform(0.12, 0.35)
            color = palette(rng.uniform(0.15, 0.95))
            ax.scatter(cx + radius * np.cos(angles), cy + radius * np.sin(angles), s=4, color=color, alpha=0.75, linewidths=0)
        _finish(ax, title, art_background="#020617")
    elif "ice_cream" in slug:
        flavor = {"vanilla": "#f9e4bc", "strawberry": "#f9a8d4", "matcha": "#86a65a"}.get(variant.name if variant else "", "#7c4a2d")
        flavors = [flavor] * 4 if "bouquet" in slug else [flavor]
        for i, color in enumerate(flavors):
            cx = (i - (len(flavors) - 1) / 2) * 0.28
            ax.fill([cx - 0.16, cx, cx + 0.16], [-0.75, -1.35, -0.75], color="#d69b63")
            for k in range(5):
                t = np.linspace(0, np.pi, 120)
                ax.plot(cx + (0.19 - k * 0.025) * np.cos(t), -0.62 + k * 0.12 + 0.08 * np.sin(t), color=color, linewidth=9, solid_capstyle="round")
        _finish(ax, title)
    elif "crystal" in slug:
        count = 34 if slug == "crystal_cluster" else 18
        for _ in range(count):
            cx, cy = rng.uniform(-1, 1), rng.uniform(-0.8, 0.9)
            sides = 6
            theta = np.linspace(0, 2 * np.pi, sides + 1) + rng.uniform(0, np.pi)
            r = rng.uniform(0.08, 0.22)
            if slug == "crystal_heart":
                cx *= 0.55
                cy = 0.62 * np.sqrt(max(0, 1 - cx * cx)) - abs(cx) * 0.45 + rng.uniform(-0.18, 0.12)
            ax.fill(cx + r * np.cos(theta), cy + r * np.sin(theta), color="#67e8f9", alpha=0.22, edgecolor="#cffafe", linewidth=0.8)
        _finish(ax, title, art_background="#08111f")
    else:
        x = np.linspace(-1, 1, 300)
        for i in range(9):
            cx = -0.85 + i * 0.21
            h = 0.45 + 0.25 * rng.random()
            ax.add_patch(plt_rect(cx - 0.035, -0.75, 0.07, h, "#f8fafc"))
            ax.plot([cx, cx], [-0.75 + h, -0.75 + h + 0.18], color="#fbbf24", linewidth=1)
        ax.plot(x, -0.78 + 0.03 * np.sin(8 * x), color="#334155", linewidth=2)
        _finish(ax, title)


def plt_rect(x: float, y: float, w: float, h: float, color: str):
    from matplotlib.patches import Rectangle

    return Rectangle((x, y), w, h, color=color, alpha=0.85)


def _superformula(ax, sample: int = 90000) -> None:
    side = _side(sample, 300)
    theta = np.linspace(-np.pi, np.pi, side)
    phi = np.linspace(-np.pi / 2, np.pi / 2, max(64, side // 2))
    th, ph = np.meshgrid(theta, phi)
    m, n1, n2, n3 = 6, 0.28, 1.15, 1.70
    def sr(t):
        return (np.abs(np.cos(m * t / 4)) ** n2 + np.abs(np.sin(m * t / 4)) ** n3) ** (-1 / n1)

    r1, r2 = sr(th), sr(ph)
    x = r1 * np.cos(th) * r2 * np.cos(ph)
    y = r1 * np.sin(th) * r2 * np.cos(ph)
    z = r2 * np.sin(ph)
    fig = ax.figure
    fig.delaxes(ax)
    ax = fig.add_subplot(111, projection="3d")
    ax.plot_surface(x, y, z, facecolors=TWILIGHT((z - z.min()) / (np.ptp(z) + np.finfo(float).eps)), linewidth=0, antialiased=True)
    ax.set_axis_off()
    rr.set_axis_text(ax, title="Superformula Bloom")


def _phyllotaxis(ax, sample: int = 90000) -> None:
    n = _points(sample, 1600)
    idx = np.arange(1, n + 1)
    angle = 2 * np.pi / ((1 + np.sqrt(5)) / 2) ** 2
    r = 0.082 * np.sqrt(idx)
    t = idx * angle
    colors = np.column_stack([0.35 + 0.60 * idx / n, 0.18 + 0.70 * (0.5 + 0.5 * np.sin(idx * 0.08)), 0.02 + 0.18 * (1 - idx / n)])
    ax.scatter(r * np.cos(t), r * np.sin(t), s=6 + 42 * (idx / n) ** 1.7, c=colors, alpha=0.92, linewidths=0)
    _finish(ax, "Phyllotaxis Sunflower", art_background="#090907")


def _ode_path(kind: str, n: int = 12000) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    dt = {"lorenz_attractor": 0.006, "rossler_ribbon": 0.025, "chua_double_scroll": 0.012, "aizawa_attractor": 0.010, "thomas_attractor": 0.018, "dadras_attractor": 0.008}.get(kind, 0.01)
    x, y, z = 0.1, 0.0, 0.0
    out = np.empty((n, 3))
    for i in range(n):
        if kind == "rossler_ribbon":
            dx, dy, dz = -y - z, x + 0.2 * y, 0.2 + z * (x - 5.9)
        elif kind == "chua_double_scroll":
            alpha, beta, m0, m1 = 15.6, 28.0, -1.143, -0.714
            h = m1 * x + 0.5 * (m0 - m1) * (abs(x + 1) - abs(x - 1))
            dx, dy, dz = alpha * (y - x - h), x - y + z, -beta * y
        elif kind == "aizawa_attractor":
            dx = (z - 0.7) * x - 3.5 * y
            dy = 3.5 * x + (z - 0.7) * y
            dz = 0.6 + 0.95 * z - z**3 / 3 - (x*x + y*y) * (1 + 0.25 * z) + 0.1 * z * x**3
        elif kind == "thomas_attractor":
            b = 0.19
            dx, dy, dz = np.sin(y) - b * x, np.sin(z) - b * y, np.sin(x) - b * z
        elif kind == "dadras_attractor":
            dx, dy, dz = y - 3 * x + 2 * y * z, 1.7 * y - x * z + z, 9 * x * y - 2.7 * z
        else:
            dx, dy, dz = 10 * (y - x), x * (28 - z) - y, x * y - 8 / 3 * z
        x += dt * dx
        y += dt * dy
        z += dt * dz
        out[i] = (x, y, z)
    return out[n // 8:, 0], out[n // 8:, 1], out[n // 8:, 2]


def _attractor(ax, slug: str, title: str, sample: int = 90000) -> None:
    if slug == "clifford_attractor":
        n = _points(sample, 180000)
        a, b, c, d = -1.4, 1.6, 1.0, 0.7
        x = np.zeros(n)
        y = np.zeros(n)
        for k in range(1, n):
            x[k] = np.sin(a * y[k - 1]) + c * np.cos(a * x[k - 1])
            y[k] = np.sin(b * x[k - 1]) + d * np.cos(b * y[k - 1])
        burn = min(2000, n // 8)
        ax.scatter(x[burn:], y[burn:], c=np.linspace(0, 1, n - burn), s=0.2, cmap=NEBULA, alpha=0.08, linewidths=0)
        _finish(ax, title, art_background="#03030a")
    elif slug == "de_jong_attractor":
        n = _points(sample, 150000)
        a, b, c, d = -2.0, -2.5, -1.2, 2.0
        x = y = 0.0
        pts = np.empty((n, 2))
        for k in range(n):
            x, y = np.sin(a * y) - np.cos(b * x), np.sin(c * x) - np.cos(d * y)
            pts[k] = (x, y)
        ax.scatter(pts[:, 0], pts[:, 1], c=np.linspace(0, 1, n), s=0.2, cmap=NEBULA, alpha=0.12, linewidths=0)
        _finish(ax, title)
    elif slug == "hopalong_attractor":
        n = _points(sample, 140000)
        a, b, c = 0.7, 1.3, 0.1
        x = y = 0.0
        pts = np.empty((n, 2))
        for k in range(n):
            x, y = y - np.sign(x) * np.sqrt(abs(b * x - c)), a - x
            pts[k] = (x, y)
        ax.scatter(pts[:, 0], pts[:, 1], c=np.linspace(0, 1, n), s=0.2, cmap=EMBER, alpha=0.12, linewidths=0)
        _finish(ax, title)
    else:
        x, y, z = _ode_path(slug, _points(sample, 14000, 1200))
        _colored_line3(ax, x, y, z, color={"lorenz_attractor": "#38bdf8", "rossler_ribbon": "#fb7185", "chua_double_scroll": "#a78bfa", "aizawa_attractor": "#67e8f9", "thomas_attractor": "#fb923c", "dadras_attractor": "#c084fc"}.get(slug, "#38bdf8"))
        ax.view_init(elev=18, azim=-36 if slug != "rossler_ribbon" else 42)
        rr.set_axis_text(ax, title=title)


def _maps(ax, slug: str, title: str, sample: int = 90000) -> None:
    rng = _rng(slug)
    if slug == "henon_map":
        n = _points(sample, 90000)
        a, b = 1.4, 0.3
        x = np.zeros(n)
        y = np.zeros(n)
        x[0] = y[0] = 0.1
        for k in range(1, n):
            x[k] = 1 - a * x[k - 1] ** 2 + y[k - 1]
            y[k] = b * x[k - 1]
        burn = min(1000, n // 8)
        ax.scatter(x[burn:], y[burn:], c=np.linspace(0, 1, n - burn), s=0.2, cmap=NEBULA, alpha=0.20, linewidths=0)
        _finish(ax, title)
    elif slug == "standard_map_islands":
        kpar = 1.15
        orbit_count = max(16, min(70, sample // 900))
        orbit_steps = max(180, min(650, sample // 35))
        for _ in range(orbit_count):
            x = 2 * np.pi * rng.random()
            p = 2 * np.pi * rng.random()
            xs, ps = [], []
            for _ in range(orbit_steps):
                p = (p + kpar * np.sin(x)) % (2 * np.pi)
                x = (x + p) % (2 * np.pi)
                xs.append(x)
                ps.append(p)
            ax.scatter(xs, ps, s=0.6, alpha=0.25, linewidths=0)
        ax.set_xlim(0, 2 * np.pi)
        ax.set_ylim(0, 2 * np.pi)
        _finish(ax, title, box=True)
    elif slug == "ikeda_map":
        n = _points(sample, 120000)
        u = 0.918
        x = y = 0.1
        pts = np.empty((n, 2))
        for k in range(n):
            t = 0.4 - 6 / (1 + x * x + y * y)
            x, y = 1 + u * (x * np.cos(t) - y * np.sin(t)), u * (x * np.sin(t) + y * np.cos(t))
            pts[k] = (x, y)
        ax.scatter(pts[:, 0], pts[:, 1], c=np.linspace(0, 1, n), s=0.2, cmap=NEON, alpha=0.12, linewidths=0)
        _finish(ax, title)
    elif slug == "logistic_bifurcation":
        r = np.linspace(2.6, 4.0, max(240, min(1800, sample // 12)))
        x = np.full_like(r, 0.5)
        for _ in range(400):
            x = r * x * (1 - x)
        r_values, x_values = [], []
        for _ in range(110):
            x = r * x * (1 - x)
            r_values.append(r.copy())
            x_values.append(x.copy())
        ax.plot(np.concatenate(r_values), np.concatenate(x_values), ".", markersize=0.55, color="#1f2937")
        _finish(ax, title, equal=False, box=True, grid=True)
        rr.set_axis_text(ax, xlabel="$r$", ylabel="$x$")
    elif slug == "circle_map_tongues":
        side = _side(sample, 230, 72)
        omega = np.linspace(0, 1, side)
        kvals = np.linspace(0, 2.2, max(64, int(side * 0.78)))
        rot = np.zeros((len(kvals), len(omega)))
        for i, kpar in enumerate(kvals):
            theta = np.zeros_like(omega)
            acc = np.zeros_like(omega)
            for step in range(260):
                next_theta = theta + omega - kpar / (2 * np.pi) * np.sin(2 * np.pi * theta)
                if step > 100:
                    acc += next_theta - theta
                theta = next_theta % 1
            rot[i] = acc / 160
        _image(ax, rot, title, NEON, extent=(0, 1, 0, 2.2))
        rr.set_axis_text(ax, xlabel="$\\Omega$", ylabel="$K$")
    elif slug == "lyapunov_carpet":
        side = _side(sample, 360)
        _lyapunov(ax, title, side, max(100, min(240, sample // 80)))
    else:
        raise ValueError(f"Unsupported CreativePlotStudio map renderer: {slug}.")


def _rk4(fun: Callable[[float, np.ndarray], np.ndarray], t: float, y: np.ndarray, dt: float) -> np.ndarray:
    k1 = fun(t, y)
    k2 = fun(t + dt / 2, y + dt * k1 / 2)
    k3 = fun(t + dt / 2, y + dt * k2 / 2)
    k4 = fun(t + dt, y + dt * k3)
    return y + dt * (k1 + 2 * k2 + 2 * k3 + k4) / 6


def _oscillator(ax, slug: str, title: str, sample: int = 90000) -> None:
    if slug == "duffing_poincare":
        delta, gamma, omega = 0.2, 0.3, 1.0
        period = 2 * np.pi / omega
        dt = period / 80
        y = np.array([0.1, 0.0])
        pts = []
        t = 0.0
        max_steps = _points(sample, 90000, 12000)
        for k in range(max_steps):
            y = _rk4(lambda tt, s: np.array([s[1], -delta * s[1] + s[0] - s[0] ** 3 + gamma * np.cos(omega * tt)]), t, y, dt)
            t += dt
            if k > min(10000, max_steps // 3) and k % 80 == 0:
                pts.append(y.copy())
                if len(pts) >= 1200:
                    break
        pts = np.array(pts)
        ax.scatter(pts[:, 0], pts[:, 1], c=np.linspace(0, 1, len(pts)), s=8, cmap=NEON, alpha=0.65, linewidths=0)
        _finish(ax, title, box=True, grid=True)
    elif slug == "duffing_sweep":
        gammas = np.linspace(0.18, 0.45, max(18, min(115, sample // 650)))
        gall, xall = [], []
        omega, delta, alpha, beta = 1.2, 0.2, -1.0, 1.0
        period = 2 * np.pi / omega
        dt = 0.045
        spp = max(1, round(period / dt))
        total_periods = max(70, min(190, sample // 250))
        sample_start = int(total_periods * 0.72)
        for gamma in gammas:
            x = y = 0.1
            t = 0.0
            for step in range(total_periods * spp):
                dy = -delta * y - alpha * x - beta * x**3 + gamma * np.cos(omega * t)
                x, y, t = x + dt * y, y + dt * dy, t + dt
                if step > sample_start * spp and step % spp == 0:
                    gall.append(gamma)
                    xall.append(x)
        ax.scatter(gall, xall, s=1.0, color="#111827", alpha=0.35)
        _finish(ax, title, equal=False, box=True, grid=True)
        rr.set_axis_text(ax, xlabel="$\\gamma$", ylabel="$\\mathrm{Stroboscopic}\\ x$")
    elif slug == "van_der_pol_phase":
        mu = 3.2
        for ic in np.linspace(-3, 3, 12):
            y = np.array([ic, -ic])
            pts = []
            t = 0.0
            dt = 0.02
            for _ in range(max(700, min(1800, sample // 30))):
                y = _rk4(lambda _, s: np.array([s[1], mu * (1 - s[0] ** 2) * s[1] - s[0]]), t, y, dt)
                t += dt
                pts.append(y.copy())
            pts = np.array(pts)
            ax.plot(pts[:, 0], pts[:, 1], linewidth=0.8)
        _finish(ax, title, box=True, grid=True)
    elif slug == "double_pendulum_trace":
        def rhs(y: np.ndarray) -> np.ndarray:
            g = 9.81
            th1, w1, th2, w2 = y
            d = th2 - th1
            den1 = 2 - np.cos(d) ** 2
            a1 = (w1**2 * np.sin(d) * np.cos(d) + g * np.sin(th2) * np.cos(d) + w2**2 * np.sin(d) - 2 * g * np.sin(th1)) / den1
            a2 = (-w2**2 * np.sin(d) * np.cos(d) + 2 * (g * np.sin(th1) * np.cos(d) - w1**2 * np.sin(d) - g * np.sin(th2))) / den1
            return np.array([w1, a1, w2, a2])

        y = np.array([np.pi / 2, 0.0, np.pi / 2 + 0.01, 0.0])
        pts = []
        for _ in range(max(900, min(4500, sample // 18))):
            y = _rk4(lambda _t, s: rhs(s), 0, y, 0.01)
            x1, y1 = np.sin(y[0]), -np.cos(y[0])
            x2, y2 = x1 + np.sin(y[2]), y1 - np.cos(y[2])
            pts.append((x2, y2))
        pts = np.array(pts)
        _colored_line(ax, pts[:, 0], pts[:, 1], NEON)
        _finish(ax, title, art_background="#050510")
    elif slug == "chladni_resonance":
        n = _side(sample, 560)
        x, y = np.meshgrid(np.linspace(-1, 1, n), np.linspace(-1, 1, n))
        z = np.cos(6 * np.pi * x) * np.cos(8 * np.pi * y) - np.cos(8 * np.pi * x) * np.cos(6 * np.pi * y)
        _image(ax, np.exp(-np.abs(z) * 22), title, NEON)
    elif slug == "lissajous_knot":
        t = np.linspace(0, 2 * np.pi, _points(sample, 6000))
        x = np.sin(4 * t)
        y = np.sin(5 * t + np.pi / 4)
        z = np.sin(6 * t + np.pi / 2)
        _colored_line3(ax, x, y, z, color="#a78bfa", lw=0.8)
        ax.view_init(elev=24, azim=-38)
        rr.set_axis_text(ax, title=title)
    else:
        raise ValueError(f"Unsupported CreativePlotStudio oscillator renderer: {slug}.")


def _reaction(ax, slug: str, title: str, sample: int = 90000, variant: ContentVariant | None = None) -> None:
    if slug == "fitzhugh_nagumo_spiral":
        n = _side(sample, 135, 72)
        u = -np.ones((n, n))
        v = np.zeros((n, n))
        c = n // 2
        u[c - 5:c + 6, c - 5:c + 6] = 1.2
        u[:12, :] = 1.0
        a, b, tau, du, dv, dt = 0.75, 0.06, 12.5, 1.0, 0.2, 0.02
        for _ in range(max(120, min(320, sample // 180))):
            lu = np.roll(u, 1, 0) + np.roll(u, -1, 0) + np.roll(u, 1, 1) + np.roll(u, -1, 1) - 4 * u
            lv = np.roll(v, 1, 0) + np.roll(v, -1, 0) + np.roll(v, 1, 1) + np.roll(v, -1, 1) - 4 * v
            u += dt * (u - u**3 / 3 - v + du * lu)
            v += dt * ((u + a - b * v) / tau + dv * lv)
        _image(ax, u, title, NEBULA)
    elif slug == "gray_scott_coral":
        side = _side(sample, 180)
        _gray_scott(ax, title, side, max(250, min(1000, sample // 60)), variant)
    else:
        raise ValueError(f"Unsupported CreativePlotStudio reaction renderer: {slug}.")


def _render_art(ax, category_folder: str, slug: str, title: str, params: dict[str, object], variant: ContentVariant) -> None:
    sample = _sample(params)
    if category_folder == "pixel_texture":
        _art_texture(ax, slug, title, sample)
    elif category_folder == "floral_botanical":
        _flower(ax, slug, title, sample, variant)
    elif category_folder == "scenes_objects":
        _scene(ax, slug, title, variant)
    elif category_folder == "generative_art":
        renderers = {
            "phyllotaxis_sunflower": lambda: _phyllotaxis(ax, sample),
            "superformula_bloom": lambda: _superformula(ax, sample),
            "plasma_clouds": lambda: _plasma(ax, sample),
        }
        try:
            renderers[slug]()
        except KeyError as exc:
            raise ValueError(f"Unsupported CreativePlotStudio art renderer: {slug}.") from exc
    else:
        raise ValueError(f"Unsupported CreativePlotStudio art category: {category_folder}.")


def _render_fractal(ax, category_folder: str, slug: str, title: str, params: dict[str, object], variant: ContentVariant) -> None:
    sample = _sample(params)
    side = _side(sample, 600)
    if category_folder == "escape_time_julia":
        _escape(ax, title, slug, side, variant)
    elif category_folder == "newton_orbit_traps":
        if slug == "newton_basin":
            _newton(ax, title, n=min(560, side), variant=variant)
        elif slug == "nova_cubic_basin":
            _newton(ax, title, nova=True, n=min(560, side), variant=variant)
        elif slug == "orbit_trap_pearls":
            _orbit_trap(ax, min(560, side))
        else:
            raise ValueError(f"Unsupported CreativePlotStudio Newton renderer: {slug}.")
    elif category_folder == "recursive_ifs":
        renderers = {
            "barnsley_fern": lambda: _barnsley(ax, sample),
            "sierpinski_carpet": lambda: _sierpinski(ax),
            "apollonian_gasket": lambda: _apollonian(ax),
            "dragon_curve": lambda: _dragon(ax),
            "koch_snowflake": lambda: _koch(ax),
            "levy_c_curve": lambda: _dragon(ax, levy=True),
            "pythagoras_tree": lambda: _pythagoras(ax),
            "vicsek_fractal": lambda: _vicsek(ax),
            "dla_cluster": lambda: _dla(ax, sample),
        }
        try:
            renderers[slug]()
        except KeyError as exc:
            raise ValueError(f"Unsupported CreativePlotStudio recursive renderer: {slug}.") from exc
    elif category_folder == "fractal_fields":
        if slug == "lyapunov_carpet":
            _lyapunov(ax, title, min(360, side), max(100, min(240, sample // 80)), variant)
        elif slug == "gray_scott_coral":
            _gray_scott(ax, title, min(180, side), max(250, min(1000, sample // 60)), variant)
        else:
            raise ValueError(f"Unsupported CreativePlotStudio fractal field renderer: {slug}.")
    else:
        raise ValueError(f"Unsupported CreativePlotStudio fractal category: {category_folder}.")


def _render_nonlinear(ax, category_folder: str, slug: str, title: str, params: dict[str, object], fig, variant: ContentVariant) -> None:
    sample = _sample(params)
    if category_folder == "strange_attractors" and slug not in {"clifford_attractor", "de_jong_attractor", "hopalong_attractor"}:
        fig.delaxes(ax)
        ax3 = fig.add_subplot(111, projection="3d")
        _attractor(ax3, slug, title, sample)
    elif category_folder == "strange_attractors":
        _attractor(ax, slug, title, sample)
    elif category_folder == "maps_bifurcations":
        _maps(ax, slug, title, sample)
    elif category_folder == "oscillators_vibration":
        if slug == "lissajous_knot":
            fig.delaxes(ax)
            ax3 = fig.add_subplot(111, projection="3d")
            _oscillator(ax3, slug, title, sample)
        else:
            _oscillator(ax, slug, title, sample)
    elif category_folder == "reaction_waves":
        _reaction(ax, slug, title, sample, variant)
    else:
        raise ValueError(f"Unsupported CreativePlotStudio nonlinear category: {category_folder}.")


def render_creative(params: dict[str, object]):
    domain = normalize_domain(params.get("domain", "art"))
    category, item = find_item(domain, str(params.get("category", "")), str(params.get("project", "")), strict=True)
    slug = slugify(item)
    variant = resolve_variant(domain, slug, params.get("style", "default"))
    _sample(params)
    title = _matlab_title(slug, item, variant)
    fig, axes = rr.new_figure(title, 1, 1, (8, 6.5))
    ax = axes[0, 0]
    if domain == "art":
        _render_art(ax, category.folder, slug, title, params, variant)
    elif domain == "fractals":
        _render_fractal(ax, category.folder, slug, title, params, variant)
    else:
        _render_nonlinear(ax, category.folder, slug, title, params, fig, variant)
    _apply_content_variant(fig, variant)
    rr.finish_figure(fig, left=0.08, right=0.96, bottom=0.08)
    return fig, f"{domain}/{category.folder}/{slug}"
