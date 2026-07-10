from __future__ import annotations

import numpy as np
from scipy import special


def sph_harmonic(l: int, m: int, theta: np.ndarray, phi: np.ndarray) -> np.ndarray:
    if hasattr(special, "sph_harm_y"):
        return special.sph_harm_y(l, m, theta, phi)
    return special.sph_harm(m, l, phi, theta)


def valid_lm_pairs(args: np.ndarray, *, minimum_l: int = 0) -> np.ndarray:
    pairs = np.rint(np.atleast_2d(args)).astype(int)
    if pairs.shape[1] < 2:
        pairs = np.column_stack([pairs[:, 0], np.zeros(pairs.shape[0], dtype=int)])
    if minimum_l == 0:
        pairs[:, 0] = np.maximum(pairs[:, 0], 0)
    pairs = pairs[(pairs[:, 0] >= minimum_l) & (np.abs(pairs[:, 1]) <= pairs[:, 0])]
    if pairs.size == 0:
        pairs = np.array([[3, 1]], dtype=int)
    pairs = np.unique(pairs, axis=0)
    order = np.lexsort((pairs[:, 0], pairs[:, 1]))
    return pairs[order]


def compute_spherical_items(variant_key: str, args: np.ndarray) -> list[dict]:
    theta_values = np.linspace(0.0, np.pi, 100)
    phi_values = np.linspace(0.0, 2 * np.pi, 180)
    if variant_key in {"xlm", "psilm", "radial"}:
        theta_values = np.linspace(0.03, np.pi - 0.03, 56)
        phi_values = np.linspace(0.0, 2 * np.pi, 112)
    theta, phi = np.meshgrid(theta_values, phi_values)
    items: list[dict] = []
    minimum_l = 1 if variant_key in {"xlm", "psilm", "radial"} else 0
    for l, m in valid_lm_pairs(args, minimum_l=minimum_l):
        ylm = sph_harmonic(int(l), int(m), theta, phi)
        rhat = _rhat(theta, phi)
        if variant_key == "ylm":
            amp = np.abs(ylm)
            amp = 0.25 + 0.95 * amp / max(float(np.max(amp)), np.finfo(float).eps)
            x = amp * rhat[..., 0]
            y = amp * rhat[..., 1]
            z = amp * rhat[..., 2]
            c = np.real(ylm)
            items.append({
                "kind": "surface",
                "x": x,
                "y": y,
                "z": z,
                "c": c,
                "title": rf"$l={l},\ m={m}$",
                "filename": f"spherical_harmonics_l{l}_m{m}.png",
            })
            continue

        vector = _vector_spherical_components(variant_key, int(l), int(m), ylm, theta_values, phi_values, theta, phi)
        idx_phi = slice(0, theta.shape[0], 6)
        idx_theta = slice(0, theta.shape[1], 9)
        sphere_x, sphere_y, sphere_z = rhat[..., 0], rhat[..., 1], rhat[..., 2]
        item = {
            "kind": "vectorfield",
            "x": sphere_x,
            "y": sphere_y,
            "z": sphere_z,
            "sphere_x": sphere_x,
            "sphere_y": sphere_y,
            "sphere_z": sphere_z,
            "c": vector["c"],
            "xq": sphere_x[idx_phi, idx_theta],
            "yq": sphere_y[idx_phi, idx_theta],
            "zq": sphere_z[idx_phi, idx_theta],
            "uq": vector["u"][idx_phi, idx_theta],
            "vq": vector["v"][idx_phi, idx_theta],
            "wq": vector["w"][idx_phi, idx_theta],
            "title": rf"${vector['symbol']}:\ l={l},\ m={m}$",
            "filename": f"vector_spherical_harmonics_{vector['file_token']}_l{l}_m{m}.png",
        }
        items.append(item)
    return items


def _rhat(theta: np.ndarray, phi: np.ndarray) -> np.ndarray:
    return np.stack([np.sin(theta) * np.cos(phi), np.sin(theta) * np.sin(phi), np.cos(theta)], axis=2)


def _surface_gradient(ylm: np.ndarray, theta_values: np.ndarray, phi_values: np.ndarray, theta: np.ndarray, phi: np.ndarray) -> np.ndarray:
    dphi, dtheta = np.gradient(ylm, phi_values, theta_values, edge_order=2)
    theta_hat = np.stack([np.cos(theta) * np.cos(phi), np.cos(theta) * np.sin(phi), -np.sin(theta)], axis=2)
    phi_hat = np.stack([-np.sin(phi), np.cos(phi), np.zeros_like(phi)], axis=2)
    sin_theta = np.maximum(np.sin(theta), 1e-8)
    return dtheta[..., None] * theta_hat + (dphi / sin_theta)[..., None] * phi_hat


def _vector_spherical_components(
    variant_key: str,
    l: int,
    m: int,
    ylm: np.ndarray,
    theta_values: np.ndarray,
    phi_values: np.ndarray,
    theta: np.ndarray,
    phi: np.ndarray,
) -> dict[str, np.ndarray | str]:
    dphi, dtheta = np.gradient(ylm, phi_values, theta_values, edge_order=2)
    safe_sin = np.maximum(np.abs(np.sin(theta)), 1e-8)
    nrm = np.sqrt(max(l * (l + 1), np.finfo(float).eps))
    if variant_key == "xlm":
        atheta = 1j * m * ylm / safe_sin / nrm
        aphi = -dtheta / nrm
        symbol = r"\mathrm{X}"
        file_token = "x"
    elif variant_key == "psilm":
        atheta = dtheta / nrm
        aphi = 1j * m * ylm / safe_sin / nrm
        symbol = r"\Psi"
        file_token = "psi"
    else:
        atheta = np.zeros_like(ylm)
        aphi = np.zeros_like(ylm)
        symbol = r"\hat r Y"
        file_token = "radial"

    if variant_key == "radial":
        ar = np.real(ylm)
        c = ar
    else:
        ar = np.zeros_like(ylm)
        c = np.real(np.sqrt(np.abs(atheta) ** 2 + np.abs(aphi) ** 2))

    ex = np.sin(theta) * np.cos(phi)
    ey = np.sin(theta) * np.sin(phi)
    ez = np.cos(theta)
    etx = np.cos(theta) * np.cos(phi)
    ety = np.cos(theta) * np.sin(phi)
    etz = -np.sin(theta)
    epx = -np.sin(phi)
    epy = np.cos(phi)
    epz = np.zeros_like(phi)

    u = np.real(ar * ex + atheta * etx + aphi * epx)
    v = np.real(ar * ey + atheta * ety + aphi * epy)
    w = np.real(ar * ez + atheta * etz + aphi * epz)
    return {"u": u, "v": v, "w": w, "c": c, "symbol": symbol, "file_token": file_token}
