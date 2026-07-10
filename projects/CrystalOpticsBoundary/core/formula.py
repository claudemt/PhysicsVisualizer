from __future__ import annotations

import numpy as np


def _rot_x(a: float) -> np.ndarray:
    return np.array([[1, 0, 0], [0, np.cos(a), -np.sin(a)], [0, np.sin(a), np.cos(a)]], dtype=float)


def _rot_y(a: float) -> np.ndarray:
    return np.array([[np.cos(a), 0, np.sin(a)], [0, 1, 0], [-np.sin(a), 0, np.cos(a)]], dtype=float)


def _rot_z(a: float) -> np.ndarray:
    return np.array([[np.cos(a), -np.sin(a), 0], [np.sin(a), np.cos(a), 0], [0, 0, 1]], dtype=float)


def _triad_from_axis(axis: np.ndarray) -> np.ndarray:
    u3 = np.asarray(axis, dtype=float).ravel()
    u3 = u3 / np.linalg.norm(u3)
    ref = np.array([0.0, 0.0, 1.0])
    if abs(float(np.dot(u3, ref))) > 0.9:
        ref = np.array([1.0, 0.0, 0.0])
    u1 = np.cross(ref, u3)
    u1 = u1 / np.linalg.norm(u1)
    u2 = np.cross(u3, u1)
    return np.column_stack([u1, u2, u3])


def build_epsilon_lab(cfg: dict[str, object]) -> np.ndarray:
    if "eps_lab" in cfg:
        eps = np.asarray(cfg["eps_lab"], dtype=float)
    else:
        eps_diag = np.asarray(cfg.get("eps_diag", [2.25, 2.56, 3.24]), dtype=float).ravel()
        orientation = cfg.get("orientation", {}) or {}
        mode = str(orientation.get("mode", "none")).lower().strip()
        if mode == "none":
            rot = np.eye(3)
        elif mode == "matrix":
            rot = np.asarray(orientation.get("R"), dtype=float)
        elif mode == "euler_zyx":
            a, b, c = np.deg2rad(np.asarray(orientation.get("euler_deg", [0, 0, 0]), dtype=float).ravel())
            rot = _rot_z(a) @ _rot_y(b) @ _rot_x(c)
        elif mode == "axis":
            diffs = [abs(eps_diag[0] - eps_diag[1]), abs(eps_diag[1] - eps_diag[2]), abs(eps_diag[0] - eps_diag[2])]
            if min(diffs) > 1e-10:
                raise ValueError("orientation.mode='axis' requires a uniaxial eps_diag.")
            r0 = _triad_from_axis(np.asarray(orientation.get("optic_axis", [0, 0, 1]), dtype=float))
            if diffs[0] <= diffs[1] and diffs[0] <= diffs[2]:
                rot = r0
            elif diffs[1] <= diffs[0] and diffs[1] <= diffs[2]:
                rot = np.column_stack([r0[:, 2], r0[:, 0], r0[:, 1]])
            else:
                rot = np.column_stack([r0[:, 0], r0[:, 2], r0[:, 1]])
        else:
            raise ValueError(f"Unknown orientation mode: {mode}")
        eps = rot @ np.diag(eps_diag) @ rot.T
    return (eps + eps.T) / 2


def principal_system(eps_lab: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray, str]:
    values, vectors = np.linalg.eigh((eps_lab + eps_lab.T) / 2)
    idx = np.argsort(values)
    values = np.real(values[idx])
    vectors = np.real(vectors[:, idx])

    # Match MATLAB's displayed eigenframe convention: choose positive dominant
    # components for the last two axes, then use the first axis for handedness.
    for column in range(1, vectors.shape[1]):
        pivot = int(np.argmax(np.abs(vectors[:, column])))
        if vectors[pivot, column] < 0:
            vectors[:, column] *= -1
    if np.linalg.det(vectors) < 0:
        vectors[:, 0] *= -1
    rel12 = abs(values[0] - values[1]) / max(1.0, abs(values[1]))
    rel23 = abs(values[1] - values[2]) / max(1.0, abs(values[2]))
    if rel12 < 1e-10 and rel23 < 1e-10:
        return values, vectors, np.empty((0, 3)), "isotropic"
    if rel12 < 1e-10:
        return values, vectors, vectors[:, 2:3], "uniaxial"
    if rel23 < 1e-10:
        return values, vectors, vectors[:, 0:1], "uniaxial"
    inv = 1.0 / values
    xi = np.arctan(np.sqrt((inv[0] - inv[1]) / (inv[1] - inv[2])))
    dirs = np.column_stack([[np.sin(xi), 0, np.cos(xi)], [-np.sin(xi), 0, np.cos(xi)]])
    return values, vectors, vectors @ dirs, "biaxial"


def _build_sp_basis(k_inc_hat: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    zhat = np.array([0.0, 0.0, 1.0])
    s_hat = np.cross(zhat, k_inc_hat)
    if np.linalg.norm(s_hat) < 1e-12:
        trial = np.array([1.0, 0.0, 0.0])
        s_hat = trial - k_inc_hat * np.dot(k_inc_hat, trial)
    s_hat = s_hat / np.linalg.norm(s_hat)
    p_hat_inc = np.cross(s_hat, k_inc_hat)
    p_hat_inc = p_hat_inc / np.linalg.norm(p_hat_inc)
    k_ref_hat = np.array([k_inc_hat[0], k_inc_hat[1], -k_inc_hat[2]], dtype=float)
    k_ref_hat = k_ref_hat / np.linalg.norm(k_ref_hat)
    p_hat_ref = np.cross(s_hat, k_ref_hat)
    return s_hat, p_hat_inc, p_hat_ref / np.linalg.norm(p_hat_ref)


def _qz_polynomial(eps: np.ndarray, qx: complex, qy: complex) -> np.ndarray:
    p = [[None] * 3 for _ in range(3)]
    p[0][0] = np.array([-1, 0, eps[0, 0] - qy**2], dtype=complex)
    p[0][1] = np.array([eps[0, 1] + qx * qy], dtype=complex)
    p[0][2] = np.array([qx, eps[0, 2]], dtype=complex)
    p[1][0] = np.array([eps[1, 0] + qx * qy], dtype=complex)
    p[1][1] = np.array([-1, 0, eps[1, 1] - qx**2], dtype=complex)
    p[1][2] = np.array([qy, eps[1, 2]], dtype=complex)
    p[2][0] = np.array([qx, eps[2, 0]], dtype=complex)
    p[2][1] = np.array([qy, eps[2, 1]], dtype=complex)
    p[2][2] = np.array([eps[2, 2] - qx**2 - qy**2], dtype=complex)

    def add(a, b):
        n = max(len(a), len(b))
        return np.pad(a, (n - len(a), 0)) + np.pad(b, (n - len(b), 0))

    poly = add(add(np.convolve(np.convolve(p[0][0], p[1][1]), p[2][2]),
                   np.convolve(np.convolve(p[0][1], p[1][2]), p[2][0])),
               np.convolve(np.convolve(p[0][2], p[1][0]), p[2][1]))
    poly = add(poly, -np.convolve(np.convolve(p[0][2], p[1][1]), p[2][0]))
    poly = add(poly, -np.convolve(np.convolve(p[0][0], p[1][2]), p[2][1]))
    poly = add(poly, -np.convolve(np.convolve(p[0][1], p[1][0]), p[2][2]))
    while len(poly) > 1 and abs(poly[0]) < 1e-14:
        poly = poly[1:]
    return poly


def _nullspace(matrix: np.ndarray, tol: float = 1e-8) -> np.ndarray:
    _, s, vh = np.linalg.svd(matrix)
    threshold = tol * max(1.0, s[0] if len(s) else 1.0)
    idx = np.where(s <= threshold)[0]
    if len(idx) == 0:
        idx = [int(np.argmin(s))]
    return vh.conj().T[:, idx]


def _fix_phase(v: np.ndarray) -> np.ndarray:
    out = np.array(v, dtype=complex)
    nz = np.flatnonzero(np.abs(out) > 1e-12)
    if len(nz):
        out *= np.exp(-1j * np.angle(out[nz[0]]))
        j = int(np.argmax(np.abs(out)))
        if np.real(out[j]) < 0:
            out *= -1
    return out


def _safe_dir(v: np.ndarray) -> np.ndarray:
    real = np.real(v).ravel()
    norm = np.linalg.norm(real)
    return real / norm if norm > 1e-14 else np.full(3, np.nan)


def _linear_dir(v: np.ndarray, tol: float = 1e-8) -> np.ndarray:
    fixed = _fix_phase(np.asarray(v).ravel())
    if np.linalg.norm(np.imag(fixed)) <= tol * max(1.0, np.linalg.norm(np.real(fixed))):
        real = np.real(fixed)
        norm = np.linalg.norm(real)
        if norm > 1e-14:
            return real / norm
    return np.full(3, np.nan)


def _physical_transmitted_basis(eps: np.ndarray, qx: complex, qy: complex) -> list[dict[str, np.ndarray]]:
    roots = np.roots(_qz_polynomial(eps, qx, qy))
    candidates: list[dict[str, np.ndarray]] = []
    for qz in roots:
        q = np.array([qx, qy, qz], dtype=complex)
        m = eps.astype(complex) - np.dot(q, q) * np.eye(3) + np.outer(q, q)
        basis = _nullspace(m)
        for j in range(basis.shape[1]):
            e = _fix_phase(basis[:, j] / np.linalg.norm(basis[:, j]))
            h = np.cross(q, e)
            s = np.real(np.cross(e, np.conj(h)))
            physical = (abs(np.imag(qz)) <= 1e-9 and np.real(s[2]) < -1e-10) or (np.imag(qz) < 0)
            if physical:
                candidates.append({"q": q, "E": e, "H": h, "D": eps @ e, "S": s, "iface": np.r_[e[:2], h[:2]]})
    candidates.sort(key=lambda item: (float(np.real(item["q"][2])), float(np.imag(item["q"][2]))))
    picked: list[dict[str, np.ndarray]] = []
    columns = np.empty((4, 0), dtype=complex)
    rank = 0
    for candidate in candidates:
        trial = np.column_stack([columns, candidate["iface"]])
        new_rank = np.linalg.matrix_rank(trial, tol=1e-8)
        if new_rank > rank:
            picked.append(candidate)
            columns = trial
            rank = new_rank
        if len(picked) == 2:
            return picked
    raise ValueError("Could not build two independent transmitted basis states.")


def _polarization_type(value: object) -> int:
    if isinstance(value, (int, float)):
        return int(round(float(value)))
    text = str(value).lower().strip()
    if text in {"1", "vector", "raw", "arbitrary"}:
        return 1
    if text in {"3", "natural", "sweep", "unpolarized"}:
        return 3
    return 2


def _normalize_incident_vector(vector: np.ndarray, k_inc_hat: np.ndarray) -> np.ndarray:
    out = np.asarray(vector, dtype=float).ravel()
    out = out - k_inc_hat * np.dot(k_inc_hat, out)
    norm = np.linalg.norm(out)
    if norm < 1e-12:
        raise ValueError("Incident polarization became zero after projection onto the plane transverse to k_inc.")
    return out / norm


def _solve_single(
    *,
    eps_lab: np.ndarray,
    n_inc: float,
    q_inc: np.ndarray,
    q_ref: np.ndarray,
    q_ref_hat: np.ndarray,
    k_inc_hat: np.ndarray,
    s_hat: np.ndarray,
    p_hat_ref: np.ndarray,
    e_inc: np.ndarray,
    basis: list[dict[str, np.ndarray]],
) -> dict[str, object]:
    e_inc = _normalize_incident_vector(e_inc, k_inc_hat)
    h_inc = np.cross(q_inc, e_inc)
    s_inc = np.real(np.cross(e_inc, np.conj(h_inc)))
    pin = -float(np.real(s_inc[2]))
    if pin <= 0:
        raise ValueError("Incident normal power is non-positive. Check k_inc and polarization.")

    ers, erp = s_hat, p_hat_ref
    hrs, hrp = np.cross(q_ref, ers), np.cross(q_ref, erp)
    a = np.array([
        [ers[0], erp[0], -basis[0]["E"][0], -basis[1]["E"][0]],
        [ers[1], erp[1], -basis[0]["E"][1], -basis[1]["E"][1]],
        [hrs[0], hrp[0], -basis[0]["H"][0], -basis[1]["H"][0]],
        [hrs[1], hrp[1], -basis[0]["H"][1], -basis[1]["H"][1]],
    ], dtype=complex)
    rhs = -np.array([e_inc[0], e_inc[1], h_inc[0], h_inc[1]], dtype=complex)
    coeff = np.linalg.pinv(a) @ rhs if np.linalg.cond(a) > 1e12 else np.linalg.solve(a, rhs)
    rs, rp, t0, t1 = coeff
    e_ref = rs * ers + rp * erp
    h_ref = np.cross(q_ref, e_ref)
    s_ref = np.real(np.cross(e_ref, np.conj(h_ref)))
    r_power = max(0.0, float(np.real(s_ref[2]) / pin))

    qz_same = abs(basis[0]["q"][2] - basis[1]["q"][2]) <= 1e-7 * max(1.0, abs(basis[0]["q"][2]), abs(basis[1]["q"][2]))
    if qz_same:
        q = basis[0]["q"]
        e = t0 * basis[0]["E"] + t1 * basis[1]["E"]
        h = np.cross(q, e)
        d = eps_lab @ e
        s = np.real(np.cross(e, np.conj(h)))
        branches: dict | list = {
            "q": q,
            "E": e,
            "H": h,
            "D": d,
            "S": s,
            "S_hat": _safe_dir(s),
            "E_linear_dir": _linear_dir(e),
            "power_ratio": max(0.0, float(-np.real(s[2]) / pin)),
        }
        t_total = branches["power_ratio"]
    else:
        branch_list = []
        for coeff_t, mode in zip([t0, t1], basis):
            e = coeff_t * mode["E"]
            h = coeff_t * mode["H"]
            s = abs(coeff_t) ** 2 * mode["S"]
            branch_list.append({
                "q": mode["q"],
                "E": e,
                "H": h,
                "D": coeff_t * mode["D"],
                "S": s,
                "S_hat": _safe_dir(s),
                "E_linear_dir": _linear_dir(e),
                "power_ratio": max(0.0, float(-np.real(s[2]) / pin)),
            })
        branches = branch_list
        t_total = sum(branch["power_ratio"] for branch in branch_list)
    return {
        "incident": {"E": e_inc, "H": h_inc, "S": s_inc, "S_hat": _safe_dir(s_inc), "E_linear_dir": _linear_dir(e_inc), "power_z_in": pin},
        "reflection": {"q": q_ref, "q_hat": q_ref_hat, "jones_sp": np.array([rs, rp]), "E": e_ref, "H": h_ref, "S": s_ref, "S_hat": _safe_dir(s_ref), "E_linear_dir": _linear_dir(e_ref), "power_ratio": r_power},
        "transmission": {"isDegenerate": qz_same, "basis": basis, "coefficients": np.array([t0, t1]), "branch": branches},
        "energy": {"R": r_power, "T_total": t_total, "balance": r_power + t_total - 1.0},
    }


def crystal_boundary_formula(cfg: dict[str, object]) -> dict[str, object]:
    n_inc = float(cfg.get("n_inc", 1.0))
    if not np.isfinite(n_inc) or n_inc <= 0:
        raise ValueError("n_inc must be a positive finite refractive index.")
    eps_lab = build_epsilon_lab(cfg)
    eps_principal, axes, optic_axes, crystal_type = principal_system(eps_lab)
    k_inc = np.asarray(cfg.get("k_inc", [0.6, 0.64, -0.48]), dtype=float).ravel()
    if k_inc.size != 3 or not np.all(np.isfinite(k_inc)) or np.linalg.norm(k_inc) < 1e-12:
        raise ValueError("k_inc must contain three finite values and be nonzero.")
    k_inc_hat = k_inc / np.linalg.norm(k_inc)
    if k_inc_hat[2] >= 0:
        raise ValueError("k_inc must point from z>0 to z<0.")
    q_inc = n_inc * k_inc_hat
    q_ref = np.array([q_inc[0], q_inc[1], -q_inc[2]], dtype=complex)
    q_ref_hat = np.real(q_ref / np.linalg.norm(q_ref))
    s_hat, p_hat_inc, p_hat_ref = _build_sp_basis(k_inc_hat)
    basis = _physical_transmitted_basis(eps_lab, q_inc[0], q_inc[1])
    common = {
        "n_inc": n_inc,
        "eps_lab": eps_lab,
        "eps_principal": eps_principal,
        "principal_axes_lab": axes,
        "optic_axes_lab": optic_axes,
        "crystal_type": crystal_type,
        "k_inc_hat": k_inc_hat,
        "q_inc": q_inc,
        "q_ref": q_ref,
        "q_ref_hat": q_ref_hat,
        "sHat": s_hat,
        "pHatInc": p_hat_inc,
        "pHatRef": p_hat_ref,
    }
    solver_args = {
        "eps_lab": eps_lab,
        "n_inc": n_inc,
        "q_inc": q_inc,
        "q_ref": q_ref,
        "q_ref_hat": q_ref_hat,
        "k_inc_hat": k_inc_hat,
        "s_hat": s_hat,
        "p_hat_ref": p_hat_ref,
        "basis": basis,
    }
    pol = cfg.get("pol", {}) or {}
    pol_type = _polarization_type(pol.get("type", "angle"))
    if pol_type == 1:
        vector = np.asarray(pol.get("vector", [1, 0, 0]), dtype=float).ravel()
        if vector.size != 3 or not np.all(np.isfinite(vector)):
            raise ValueError("Polarization vector must contain three finite values.")
        single = _solve_single(e_inc=vector, **solver_args)
        return {
            "case_type": "single",
            "polarization": {"type": "vector", "vector": vector},
            "common": common,
            "single": single,
        }
    if pol_type == 3:
        if "angle_list_deg" in pol:
            alpha_deg = np.asarray(pol["angle_list_deg"], dtype=float).ravel()
        else:
            n_samples = int(pol.get("num_samples", 181))
            if n_samples < 3 or n_samples > 5001:
                raise ValueError("Polarization sweep samples must be between 3 and 5001.")
            alpha_deg = np.linspace(0.0, 180.0, n_samples + 1)[:-1]
        if alpha_deg.size == 0 or alpha_deg.size > 5001 or not np.all(np.isfinite(alpha_deg)):
            raise ValueError("Polarization sweep angles must contain finite values.")
        samples = []
        for angle in alpha_deg:
            alpha = np.deg2rad(float(angle))
            samples.append(_solve_single(e_inc=np.cos(alpha) * s_hat + np.sin(alpha) * p_hat_inc, **solver_args))
        return {
            "case_type": "sweep",
            "polarization": {"type": "sweep", "num_samples": int(alpha_deg.size)},
            "common": common,
            "sweep": {"alpha_deg": alpha_deg, "alpha_rad": np.deg2rad(alpha_deg), "sample": samples},
            "single": samples[0],
        }
    angle_deg = float(pol.get("angle_deg", 0.0))
    if not np.isfinite(angle_deg):
        raise ValueError("Polarization angle must be finite.")
    alpha = np.deg2rad(angle_deg)
    single = _solve_single(e_inc=np.cos(alpha) * s_hat + np.sin(alpha) * p_hat_inc, **solver_args)
    return {
        "case_type": "single",
        "polarization": {"type": "angle", "angle_deg": angle_deg},
        "common": common,
        "single": single,
    }
