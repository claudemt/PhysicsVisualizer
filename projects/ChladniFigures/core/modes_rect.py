from __future__ import annotations

from dataclasses import dataclass

import numpy as np
from scipy import linalg, optimize, sparse, special

from .boundaries import rect_boundary_meta


@dataclass
class RectMode:
    x: np.ndarray
    y: np.ndarray
    u: np.ndarray
    lam_disp: float
    tag: str
    boundary: str
    omega: float | None = None
    solver: str = ""


def _plot_vectors(a: float, b: float, grid_n: int) -> tuple[np.ndarray, np.ndarray]:
    long_n = max(81, int(grid_n))
    if a >= b:
        nx = long_n
        ny = max(41, 2 * int(np.floor((b / a) * (nx - 1) / 2)) + 1)
    else:
        ny = long_n
        nx = max(41, 2 * int(np.floor((a / b) * (ny - 1) / 2)) + 1)
    return np.linspace(-a / 2, a / 2, nx), np.linspace(-b / 2, b / 2, ny)


def _canonicalize(u: np.ndarray) -> np.ndarray:
    out = np.asarray(u, dtype=float)
    idx = int(np.nanargmax(np.abs(out)))
    if out.ravel()[idx] < 0:
        out = -out
    amp = np.nanmax(np.abs(out))
    return out / amp if np.isfinite(amp) and amp > 0 else out


def _dynamic_frequency(lam_disp: float, d_rigidity: float, mass_per_area: float) -> float:
    if not np.isfinite(d_rigidity) or d_rigidity <= 0:
        raise ValueError("d_rigidity must be finite and positive for dynamic modes.")
    if not np.isfinite(mass_per_area) or mass_per_area <= 0:
        raise ValueError("mass_per_area must be finite and positive for dynamic modes.")
    return float(lam_disp * np.sqrt(d_rigidity / mass_per_area))


def _navier_ssss(
    count: int, grid_n: int, a: float, b: float, d_rigidity: float, mass_per_area: float,
) -> list[RectMode]:
    x, y = _plot_vectors(a, b, grid_n)
    xp = x + a / 2
    yp = y + b / 2
    max_order = max(12, int(np.ceil(np.sqrt(count))) + 8)
    entries: list[tuple[float, int, int]] = []
    for m in range(1, max_order + 1):
        for n in range(1, max_order + 1):
            lam = (m * np.pi / a) ** 2 + (n * np.pi / b) ** 2
            entries.append((float(lam), m, n))
    entries.sort(key=lambda item: item[0])
    modes: list[RectMode] = []
    for lam, m, n in entries[:count]:
        u = np.outer(np.sin(n * np.pi * yp / b), np.sin(m * np.pi * xp / a))
        u[[0, -1], :] = 0
        u[:, [0, -1]] = 0
        modes.append(RectMode(
            x=x, y=y, u=_canonicalize(u), lam_disp=lam, tag=f"mode{m},{n}", boundary="SSSS",
            omega=_dynamic_frequency(lam, d_rigidity, mass_per_area), solver="navier",
        ))
    return modes


def solve_rect_clamped_fd_highres(
    count: int = 10,
    grid_n: int = 80,
    a: float = 2.0,
    b: float = 1.0,
    d_rigidity: float = 1.0,
    mass_per_area: float = 1.0,
) -> list[RectMode]:
    """Solve a CCCC rectangle with the legacy clamped ghost-row FD stencil."""
    if int(count) < 1 or float(a) <= 0 or float(b) <= 0:
        raise ValueError("count, a, and b must be positive.")
    base_n = min(max(121, 3 * int(grid_n) + 31), 241)
    if a >= b:
        nx = base_n
        ny = max(9, round((b / a) * (nx - 1)) + 1)
    else:
        ny = base_n
        nx = max(9, round((a / b) * (ny - 1)) + 1)
    nx = max(9, 2 * ((nx - 1) // 2) + 1)
    ny = max(9, 2 * ((ny - 1) // 2) + 1)
    x = np.linspace(-a / 2, a / 2, nx)
    y = np.linspace(-b / 2, b / 2, ny)
    mx, my = nx - 2, ny - 2

    def clamped_operators(size: int, step: float) -> tuple[sparse.csr_matrix, sparse.csr_matrix]:
        d2 = sparse.diags((np.ones(size - 1), -2 * np.ones(size), np.ones(size - 1)), (-1, 0, 1), format="csr") / step**2
        d4 = sparse.diags(
            (np.ones(size - 2), -4 * np.ones(size - 1), 6 * np.ones(size), -4 * np.ones(size - 1), np.ones(size - 2)),
            (-2, -1, 0, 1, 2), format="lil",
        )
        # The clamped ghost values are reflected into the first/last interior row.
        d4[0, 0] += 1
        d4[-1, -1] += 1
        return d2.tocsr(), (d4 / step**4).tocsr()

    d2x, d4x = clamped_operators(mx, a / (nx - 1))
    d2y, d4y = clamped_operators(my, b / (ny - 1))
    matrix = sparse.kron(d4x, sparse.eye(my), format="csr") + 2 * sparse.kron(d2x, d2y, format="csr") + sparse.kron(sparse.eye(mx), d4y, format="csr")
    matrix = ((matrix + matrix.T) * 0.5).tocsr()
    search = min(int(count) + 12, matrix.shape[0] - 2)
    if search < 1:
        raise ValueError("Grid is too small for the clamped FD solver.")
    # This is MATLAB's near-zero eigs fallback expressed directly as SciPy shift-invert.
    values, vectors = sparse.linalg.eigsh(matrix, k=search, sigma=1e-8, which="LM", tol=1e-10, maxiter=4000)
    keep = np.flatnonzero(np.isfinite(values) & (values > -1e-10))
    values, vectors = values[keep], vectors[:, keep]
    order = np.argsort(values)
    modes: list[RectMode] = []
    for display_index, index in enumerate(order[:int(count)], start=1):
        interior = vectors[:, index].reshape((my, mx), order="F")
        u = np.zeros((ny, nx))
        u[1:-1, 1:-1] = _canonicalize(np.real(interior))
        u[np.abs(u) < 1e-12] = 0
        lam_disp = float(np.sqrt(max(values[index], 0)))
        modes.append(RectMode(x=x, y=y, u=u, lam_disp=lam_disp, tag=f"mode{display_index}", boundary="CCCC", omega=_dynamic_frequency(lam_disp, d_rigidity, mass_per_area), solver="clamped_fd"))
    if not modes:
        raise RuntimeError("Clamped FD solver produced no valid eigenvalues.")
    return modes


def _levy_matrix(lam: float, m: int, nu: float, a: float, b: float, bottom: str, top: str) -> np.ndarray:
    alpha = m * np.pi / a
    p, q = np.sqrt(alpha * alpha + lam), np.sqrt(lam - alpha * alpha)

    def rows(kind: str, y0: float) -> np.ndarray:
        w = np.array([np.cosh(p * y0), np.sinh(p * y0), np.cos(q * y0), np.sin(q * y0)])
        theta = np.array([p * np.sinh(p * y0), p * np.cosh(p * y0), -q * np.sin(q * y0), q * np.cos(q * y0)])
        moment = np.array([(p * p - nu * alpha * alpha) * np.cosh(p * y0), (p * p - nu * alpha * alpha) * np.sinh(p * y0), -(q * q + nu * alpha * alpha) * np.cos(q * y0), -(q * q + nu * alpha * alpha) * np.sin(q * y0)])
        shear_p, shear_q = p * (p * p - (2 - nu) * alpha * alpha), q * (q * q + (2 - nu) * alpha * alpha)
        shear = np.array([shear_p * np.sinh(p * y0), shear_p * np.cosh(p * y0), shear_q * np.sin(q * y0), -shear_q * np.cos(q * y0)])
        return np.vstack({"S": (w, moment), "C": (w, theta), "F": (moment, shear)}[kind])

    return np.vstack((rows(bottom, 0.0), rows(top, b)))


def solve_rect_levy_family(
    nu: float = 0.225,
    count: int = 10,
    grid_n: int = 120,
    boundary: str = "SSSS",
    a: float = 2.0,
    b: float = 1.0,
    d_rigidity: float = 1.0,
    mass_per_area: float = 1.0,
    scan_points: int | None = None,
) -> list[RectMode]:
    """Solve the MATLAB Levy family: left/right S, top/bottom C/S/F."""
    meta = rect_boundary_meta(boundary)
    if meta.left != "S" or meta.right != "S":
        raise ValueError("Levy modes require simply supported left and right edges (ULDR ?S?S).")
    x, y = _plot_vectors(a, b, grid_n)
    xp, yp = x + a / 2, y + b / 2
    entries: list[tuple[float, int, np.ndarray]] = []
    samples = int(scan_points or max(700, min(1800, 220 * int(count))))
    initial_mmax = max(18, int(np.ceil(np.sqrt(2 * count))) + 12)
    initial_limit = max(400.0, 40.0 * count) * (4.0 / min(a, b) ** 2)
    for attempt in range(3):
        limit = initial_limit * (1 + 0.75 * attempt)
        for m in range(1, initial_mmax + 6 * attempt + 1):
            alpha = m * np.pi / a
            lower = alpha * alpha + 1e-7
            if lower >= limit:
                continue
            grid = np.linspace(lower, limit, samples)

            def determinant(lam: float) -> float:
                try:
                    matrix = _levy_matrix(lam, m, nu, a, b, meta.bottom, meta.top)
                    norms = np.maximum(np.linalg.norm(matrix, axis=1), 1.0)
                    return float(np.linalg.det(matrix / norms[:, None]))
                except (FloatingPointError, ValueError, np.linalg.LinAlgError):
                    return np.nan

            values = np.array([determinant(value) for value in grid])
            roots: list[float] = []
            for index in range(1, grid.size - 1):
                left, middle, right = values[index - 1:index + 2]
                if not np.isfinite((left, middle, right)).all():
                    continue
                root: float | None = None
                if left * middle <= 0 or middle * right <= 0:
                    lo, hi = (grid[index - 1], grid[index]) if left * middle <= 0 else (grid[index], grid[index + 1])
                    try:
                        root = float(optimize.brentq(determinant, lo, hi, xtol=1e-10))
                    except ValueError:
                        pass
                elif abs(middle) <= abs(left) and abs(middle) <= abs(right):
                    candidate = optimize.minimize_scalar(lambda value: abs(determinant(value)), bounds=(grid[index - 1], grid[index + 1]), method="bounded")
                    if candidate.success and abs(determinant(float(candidate.x))) < 1e-7:
                        root = float(candidate.x)
                if root is not None and root > lower and abs(determinant(root)) < 1e-6:
                    if not roots or abs(root - roots[-1]) > 1e-7 * max(1.0, abs(roots[-1])):
                        roots.append(root)
            for lam in roots:
                matrix = _levy_matrix(lam, m, nu, a, b, meta.bottom, meta.top)
                coefficient = np.linalg.svd(matrix, full_matrices=False)[2][-1]
                if coefficient[np.argmax(np.abs(coefficient))] < 0:
                    coefficient = -coefficient
                entries.append((lam, m, coefficient))
        if len(entries) >= count:
            break
    entries.sort(key=lambda item: item[0])
    modes: list[RectMode] = []
    for display_index, (lam, m, coefficient) in enumerate(entries[:int(count)], start=1):
        alpha = m * np.pi / a
        p, q = np.sqrt(alpha * alpha + lam), np.sqrt(lam - alpha * alpha)
        y_terms = np.column_stack((np.cosh(p * yp), np.sinh(p * yp), np.cos(q * yp), np.sin(q * yp)))
        u = _canonicalize(np.real(np.outer(y_terms @ coefficient, np.sin(m * np.pi * xp / a))))
        if meta.bottom != "F":
            u[0, :] = 0
        if meta.top != "F":
            u[-1, :] = 0
        u[:, [0, -1]] = 0
        modes.append(RectMode(x=x, y=y, u=u, lam_disp=float(lam), tag=f"mode{m},{display_index}", boundary=meta.code, omega=_dynamic_frequency(float(lam), d_rigidity, mass_per_area), solver="levy"))
    if not modes:
        raise RuntimeError(f"Levy solver found no roots for {meta.code}.")
    return modes


def _legendre_family(order: int, x: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    values = np.empty((x.size, order + 1), dtype=float)
    first = np.empty_like(values)
    second = np.empty_like(values)
    for degree in range(order + 1):
        poly = np.polynomial.legendre.Legendre.basis(degree)
        values[:, degree] = poly(x)
        first[:, degree] = poly.deriv(1)(x)
        second[:, degree] = poly.deriv(2)(x)
    return values, first, second


def _essential_power(kind: str) -> int:
    return {"F": 0, "S": 1, "C": 2}[kind]


def _edge_factor(x: np.ndarray, minus: str, plus: str) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    pm, pp = _essential_power(minus), _essential_power(plus)
    left = (1 + x) ** pm
    right = (1 - x) ** pp
    d_left = pm * (1 + x) ** (pm - 1) if pm else np.zeros_like(x)
    d_right = -pp * (1 - x) ** (pp - 1) if pp else np.zeros_like(x)
    d2_left = pm * (pm - 1) * (1 + x) ** (pm - 2) if pm > 1 else np.zeros_like(x)
    d2_right = pp * (pp - 1) * (1 - x) ** (pp - 2) if pp > 1 else np.zeros_like(x)
    factor = left * right
    return factor, d_left * right + left * d_right, d2_left * right + 2 * d_left * d_right + left * d2_right


def _constrained_family(
    x: np.ndarray, values: np.ndarray, first: np.ndarray, second: np.ndarray, minus: str, plus: str,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    factor, d_factor, d2_factor = _edge_factor(x, minus, plus)
    return (
        factor[:, None] * values,
        d_factor[:, None] * values + factor[:, None] * first,
        d2_factor[:, None] * values + 2 * d_factor[:, None] * first + factor[:, None] * second,
    )


def _gram(left: np.ndarray, right: np.ndarray, weights: np.ndarray, symmetric: bool = False) -> np.ndarray:
    result = left.T @ (weights[:, None] * right)
    return (result + result.T) / 2 if symmetric else result


def _ritz_general(
    boundary: str, nu: float, count: int, grid_n: int, a: float, b: float,
    d_rigidity: float, mass_per_area: float,
) -> list[RectMode]:
    meta = rect_boundary_meta(boundary)
    # This is the MATLAB solve_rect_ritz_general trial space: S/C essential
    # constraints are embedded in the edge factor, while natural conditions
    # enter through the Kirchhoff-Love energy form.
    start = max(8, int(np.ceil(2 * np.sqrt(count))) + 4)
    stop = max(start, min(20, start + 6))
    x, y = _plot_vectors(a, b, grid_n)
    for order in range(start, stop + 1, 2):
        quad_order = max(2 * order + 2 * max(map(_essential_power, (meta.top, meta.left, meta.bottom, meta.right))) + 10, 40)
        qx, weights = special.roots_legendre(quad_order)
        basis, d_basis, d2_basis = _legendre_family(order, qx)
        fx, dfx, d2fx = _constrained_family(qx, basis, d_basis, d2_basis, meta.left, meta.right)
        fy, dfy, d2fy = _constrained_family(qx, basis, d_basis, d2_basis, meta.bottom, meta.top)
        ix00, ix11, ix22, ix20 = (_gram(fx, fx, weights, True), _gram(dfx, dfx, weights, True), _gram(d2fx, d2fx, weights, True), _gram(d2fx, fx, weights))
        iy00, iy11, iy22, iy20 = (
            _gram(fy, fy, weights, True), _gram(dfy, dfy, weights, True),
            _gram(d2fy, d2fy, weights, True), _gram(d2fy, fy, weights),
        )
        sx, sy, area = 2 / a, 2 / b, a * b / 4
        mass = area * np.kron(ix00, iy00)
        stiffness = area * (
            sx**4 * np.kron(ix22, iy00) + sy**4 * np.kron(ix00, iy22)
            + nu * sx**2 * sy**2 * (np.kron(ix20, iy20.T) + np.kron(ix20.T, iy20))
            + 2 * (1 - nu) * sx**2 * sy**2 * np.kron(ix11, iy11)
        )
        mass = (mass + mass.T) / 2
        stiffness = (stiffness + stiffness.T) / 2
        reg = 1e-13 * np.trace(mass) / max(mass.shape[0], 1)
        chol = linalg.cholesky(mass + reg * np.eye(mass.shape[0]), lower=True, check_finite=False)
        transformed = linalg.solve_triangular(chol, stiffness, lower=True, check_finite=False)
        transformed = linalg.solve_triangular(chol, transformed.T, lower=True, check_finite=False).T
        transformed = (transformed + transformed.T) / 2
        keep: np.ndarray | None = None
        if meta.is_all_free:
            n1 = order + 1
            rigid = np.zeros((n1 * n1, 3))
            rigid[0, 0], rigid[n1, 1], rigid[1, 2] = 1, 1, 1
            q_rigid, _ = linalg.qr(chol.T @ rigid, mode="economic", check_finite=False)
            keep = linalg.null_space(q_rigid.T, rcond=1e-11, check_finite=False)
            transformed = keep.T @ transformed @ keep
            transformed = (transformed + transformed.T) / 2
        eigvals, eigvecs = linalg.eigh(transformed, check_finite=False)
        valid = np.flatnonzero(np.isfinite(eigvals) & (eigvals > 1e-9))
        if valid.size < count and order < stop:
            continue
        valid = valid[:count]
        xi, eta = 2 * x / a, 2 * y / b
        px, dpx, d2px = _legendre_family(order, xi)
        py, dpy, d2py = _legendre_family(order, eta)
        fxg, _, _ = _constrained_family(xi, px, dpx, d2px, meta.left, meta.right)
        fyg, _, _ = _constrained_family(eta, py, dpy, d2py, meta.bottom, meta.top)
        modes: list[RectMode] = []
        for display_index, eig_index in enumerate(valid, start=1):
            vector = eigvecs[:, eig_index]
            if keep is not None:
                vector = keep @ vector
            coeffs = linalg.solve_triangular(chol.T, vector, lower=False, check_finite=False)
            coeffs = coeffs.reshape((order + 1, order + 1), order="F")
            u = _canonicalize(np.real(fyg @ coeffs @ fxg.T))
            u[np.abs(u) < 1e-12] = 0
            lam_disp = float(np.sqrt(eigvals[eig_index]))
            modes.append(RectMode(
                x=x, y=y, u=u, lam_disp=lam_disp, tag=f"mode{display_index}", boundary=meta.code,
                omega=_dynamic_frequency(lam_disp, d_rigidity, mass_per_area), solver="ritz",
            ))
        return modes
    raise RuntimeError(f"Rectangular Ritz solver produced no valid bending eigenvalues for {meta.code}.")


def solve_rect_free_ritz_general(
    nu: float = 0.225,
    count: int = 10,
    grid_n: int = 240,
    a: float = 2.0,
    b: float = 1.0,
    d_rigidity: float = 1.0,
    mass_per_area: float = 1.0,
) -> list[RectMode]:
    """Independent FFFF Ritz entry point with rigid translation/rotation removed."""
    modes = _ritz_general("FFFF", nu, count, grid_n, a, b, d_rigidity, mass_per_area)
    for mode in modes:
        mode.solver = "free_ritz"
    return modes


def solve_rect_free_sparse(
    nu: float = 0.225,
    count: int = 10,
    grid_n: int = 32,
    a: float = 2.0,
    b: float = 2.0,
    d_rigidity: float = 1.0,
    mass_per_area: float = 1.0,
) -> list[RectMode]:
    """Port the legacy FFFF sparse ghost-boundary formulation for its native square."""
    if not np.isclose(a, 2.0) or not np.isclose(b, 2.0):
        raise ValueError("The legacy free_sparse solver is defined only for its native a=b=2 square.")
    n = max(9, int(grid_n))
    labels = np.arange(n * n).reshape((n, n), order="F")
    rows, cols, data = [], [], []
    for col in range(n):
        for row in range(n):
            index = labels[row, col]
            rows.append(index); cols.append(index); data.append(4.0)
            for drow, dcol in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                rr, cc = row + drow, col + dcol
                if 0 <= rr < n and 0 <= cc < n:
                    rows.append(index); cols.append(labels[rr, cc]); data.append(-1.0)
    d = sparse.csr_matrix((data, (rows, cols)), shape=(n * n, n * n))
    left, right = labels[1:-1, 0], labels[1:-1, -1]
    top, bottom = labels[0, 1:-1], labels[-1, 1:-1]
    ghost = np.concatenate((left, right, top, bottom))
    physical = labels[1:-1, 1:-1].ravel(order="F")
    normal = d.tolil(copy=True)
    for edge in (labels[1:-1, 1], labels[1:-1, -2], labels[1, 1:-1], labels[-2, 1:-1]):
        normal[edge, edge] = normal[edge, edge] * 0.5
    closure = d.tolil(copy=True)
    closure[ghost, :] = 0.0
    correction = 0.5 * (nu - 1.0) * np.array(((1.0, -1.0, -1.0, 1.0), (-1.0, 1.0, 1.0, -1.0)))
    for edge, delta in ((left, 1), (right, -1)):
        for index in edge[:-1]:
            closure[np.ix_([index, index + 1], [index, index + 1, index + 2 * n * delta, index + 2 * n * delta + 1])] += correction
    for edge, delta in ((top, 1), (bottom, -1)):
        for index in edge[:-1]:
            closure[np.ix_([index, index + n], [index + n, index, index + n + 2 * delta, index + 2 * delta])] -= correction
    operator = (normal.tocsr() @ closure.tocsr()).tolil()
    operator[ghost, :] = 0.0
    for edge, direction in ((left, n), (right, -n)):
        for index in edge:
            operator[index, [index + direction, index, index + direction - 1, index + direction + 1, index + 2 * direction]] = [2 * (1 + nu), -1, -nu, -nu, -1]
    for edge, direction in ((top, 1), (bottom, -1)):
        for index in edge:
            operator[index, [index + direction, index, index + direction + n, index + direction - n, index + 2 * direction]] = [2 * (1 + nu), -1, -nu, -nu, -1]
    operator = operator.tocsr()
    agg = operator[ghost, :][:, ghost].tocsc()
    agp = operator[ghost, :][:, physical].toarray()
    app = operator[physical, :][:, physical].toarray()
    apg = operator[physical, :][:, ghost].toarray()
    reduced = app - apg @ sparse.linalg.splu(agg).solve(agp)
    mass = normal.tocsr()[physical, :][:, physical].toarray()
    h = 2.0 / (n - 3)
    values, vectors = linalg.eig(reduced / h**4, mass, check_finite=False)
    real = np.flatnonzero(np.isfinite(values) & (np.abs(values.imag) < 1e-7) & (values.real > -1e-7))
    order = real[np.argsort(values.real[real])]
    modes: list[RectMode] = []
    x = y = np.linspace(-1.0, 1.0, n - 2)
    for display_index, index in enumerate(order[:int(count)], start=1):
        lam_disp = float(np.sqrt(max(values.real[index], 0.0)))
        if display_index <= 3:
            lam_disp = 0.0
        u = _canonicalize(np.real(vectors[:, index]).reshape((n - 2, n - 2), order="F"))
        modes.append(RectMode(x=x, y=y, u=u, lam_disp=lam_disp, tag=f"mode{display_index}", boundary="FFFF", omega=_dynamic_frequency(lam_disp, d_rigidity, mass_per_area), solver="free_sparse"))
    if not modes:
        raise RuntimeError("Legacy free_sparse solver produced no real eigenmodes.")
    return modes


def compute_rect_modes(
    boundary: str = "FFFF",
    nu: float = 0.225,
    count: int = 10,
    grid_n: int = 240,
    a: float = 2.0,
    b: float = 1.0,
    d_rigidity: float = 1.0,
    mass_per_area: float = 1.0,
    solver: str = "auto",
) -> list[RectMode]:
    if not (0 < float(nu) < 0.5):
        raise ValueError("nu must be in (0, 0.5).")
    if int(count) < 1 or a <= 0 or b <= 0:
        raise ValueError("count, a, and b must be positive.")
    meta = rect_boundary_meta(boundary)
    key = str(solver).strip().lower().replace("-", "_")
    aliases = {"fd": "clamped_fd", "clamped": "clamped_fd", "free": "free_ritz", "general": "ritz"}
    key = aliases.get(key, key)
    if key not in {"auto", "navier", "clamped_fd", "levy", "free_ritz", "free_sparse", "ritz"}:
        raise ValueError("solver must be auto, navier, clamped_fd, levy, free_ritz, free_sparse, or ritz.")
    if key == "auto":
        if meta.is_all_simply:
            key = "navier"
        elif meta.is_all_clamped:
            key = "clamped_fd"
        elif meta.left == "S" and meta.right == "S":
            key = "levy"
        elif meta.is_all_free:
            key = "free_ritz"
        else:
            key = "ritz"
    if key == "navier":
        if not meta.is_all_simply:
            raise ValueError("The Navier solver requires SSSS boundary conditions.")
        return _navier_ssss(int(count), int(grid_n), float(a), float(b), d_rigidity, mass_per_area)
    if key == "clamped_fd":
        if not meta.is_all_clamped:
            raise ValueError("The clamped_fd solver requires CCCC boundary conditions.")
        return solve_rect_clamped_fd_highres(int(count), int(grid_n), float(a), float(b), d_rigidity, mass_per_area)
    if key == "levy":
        return solve_rect_levy_family(float(nu), int(count), int(grid_n), meta.code, float(a), float(b), d_rigidity, mass_per_area)
    if key == "free_ritz":
        if not meta.is_all_free:
            raise ValueError("The free_ritz solver requires FFFF boundary conditions.")
        return solve_rect_free_ritz_general(float(nu), int(count), int(grid_n), float(a), float(b), d_rigidity, mass_per_area)
    if key == "free_sparse":
        if not meta.is_all_free:
            raise ValueError("The free_sparse solver requires FFFF boundary conditions.")
        return solve_rect_free_sparse(float(nu), int(count), int(grid_n), float(a), float(b), d_rigidity, mass_per_area)
    return _ritz_general(meta.code, float(nu), int(count), int(grid_n), float(a), float(b), d_rigidity, mass_per_area)
