from __future__ import annotations

import numpy as np

from .motion import motion_state


def _cross(ax, ay, az, bx, by, bz):
    return ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx


def _stabilize_kappa(kappa):
    out = np.real(kappa)
    sign = np.sign(out)
    sign[sign == 0] = 1
    small = np.abs(out) < 1e-10
    out[small] = sign[small] * 1e-10
    return out


def moving_charge_formula(X, Y, Z, t_obs: float, motion: str, a: float, omega: float, lambda_ref: float = 1.0):
    rx0, ry0, rz0, *_ = motion_state(t_obs, motion, a, omega)
    rq_now = np.array([float(rx0), float(ry0), float(rz0)])
    tr = t_obs - np.sqrt((X - rx0) ** 2 + (Y - ry0) ** 2 + (Z - rz0) ** 2)
    for _ in range(4):
        rx, ry, rz, *_ = motion_state(tr, motion, a, omega)
        tr = t_obs - np.sqrt(np.maximum((X - rx) ** 2 + (Y - ry) ** 2 + (Z - rz) ** 2, 0))
    prev = tr.copy()
    converged = np.zeros_like(tr, dtype=bool)
    # Keep the same 4 Picard + 24 Newton retarded-time solve used by the
    # MATLAB reference.  The final iterations matter near the charge mask.
    for _ in range(24):
        rx, ry, rz, vx, vy, vz, *_ = motion_state(tr, motion, a, omega)
        Rx = X - rx
        Ry = Y - ry
        Rz = Z - rz
        R = np.maximum(np.sqrt(Rx * Rx + Ry * Ry + Rz * Rz), 1e-13)
        nx, ny, nz = Rx / R, Ry / R, Rz / R
        kappa = _stabilize_kappa(1 - (nx * vx + ny * vy + nz * vz))
        step = (t_obs - tr - R) / kappa
        step[~np.isfinite(step)] = 0
        update = (np.abs(step) < np.abs(tr - prev)) | (~converged)
        prev = tr.copy()
        tr[update] += step[update]
        converged |= np.abs(step) < 5e-12
        if bool(np.all(converged)):
            break

    rx, ry, rz, vx, vy, vz, ax, ay, az = motion_state(tr, motion, a, omega)
    Rx = X - rx
    Ry = Y - ry
    Rz = Z - rz
    R = np.maximum(np.sqrt(Rx * Rx + Ry * Ry + Rz * Rz), 1e-13)
    nx, ny, nz = Rx / R, Ry / R, Rz / R
    beta2 = vx * vx + vy * vy + vz * vz
    inv_gamma2 = np.maximum(1 - beta2, 0)
    kappa = _stabilize_kappa(1 - (nx * vx + ny * vy + nz * vz))

    E1x = inv_gamma2 * (nx - vx) / (kappa**3 * R**2)
    E1y = inv_gamma2 * (ny - vy) / (kappa**3 * R**2)
    E1z = inv_gamma2 * (nz - vz) / (kappa**3 * R**2)
    c1x, c1y, c1z = _cross(nx - vx, ny - vy, nz - vz, ax, ay, az)
    E2x, E2y, E2z = _cross(nx, ny, nz, c1x, c1y, c1z)
    E2x = E2x / (kappa**3 * R)
    E2y = E2y / (kappa**3 * R)
    E2z = E2z / (kappa**3 * R)
    Etx, Ety, Etz = E1x + E2x, E1y + E2y, E1z + E2z
    B1x, B1y, B1z = _cross(nx, ny, nz, E1x, E1y, E1z)
    B2x, B2y, B2z = _cross(nx, ny, nz, E2x, E2y, E2z)
    Btx, Bty, Btz = _cross(nx, ny, nz, Etx, Ety, Etz)
    mask_radius = max(0.03 * lambda_ref, 0.06 * a)
    bad_base = ~np.isfinite(R) | ~np.isfinite(kappa) | ~np.isfinite(inv_gamma2) | (beta2 >= 1)
    mask = (R < mask_radius) | bad_base | (np.abs(kappa) < 1e-7)
    data = {
        "vel": {"Ex": E1x, "Ey": E1y, "Ez": E1z, "Bx": B1x, "By": B1y, "Bz": B1z},
        "rad": {"Ex": E2x, "Ey": E2y, "Ez": E2z, "Bx": B2x, "By": B2y, "Bz": B2z},
        "tot": {"Ex": Etx, "Ey": Ety, "Ez": Etz, "Bx": Btx, "By": Bty, "Bz": Btz},
        "tr": tr,
        "mask": mask,
    }
    for block_name in ("vel", "rad", "tot"):
        for key, value in data[block_name].items():
            arr = np.real(value).copy()
            arr[mask] = np.nan
            data[block_name][key] = arr
    data["tr"] = np.where(mask, np.nan, np.real(tr))
    return data, rq_now
