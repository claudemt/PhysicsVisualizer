from __future__ import annotations

import numpy as np
from scipy import special

from .coefficients import cylinder_mie_all_coefficients, sphere_internal_coefficients, sphere_mie_coefficients


def make_slice_grid(n: int, half_width: float, slice_type: str, slice_pos: float):
    u = np.linspace(-half_width, half_width, int(n))
    v = np.linspace(-half_width, half_width, int(n))
    U, V = np.meshgrid(u, v)
    if slice_type == "xy":
        return U, V, U, V, np.full_like(U, slice_pos)
    if slice_type == "yz":
        return U, V, np.full_like(U, slice_pos), U, V
    return U, V, U, np.full_like(U, slice_pos), V


def incident_polarization(nu: float, psi: float, geometry: str) -> tuple[complex, complex, complex]:
    a_plus = 1 / np.sqrt(1 + nu * nu)
    a_minus = (nu / np.sqrt(1 + nu * nu)) * np.exp(1j * psi)
    if geometry == "cylinder":
        return 0j, (a_plus + a_minus) / np.sqrt(2), 1j * (a_plus - a_minus) / np.sqrt(2)
    return (a_plus + a_minus) / np.sqrt(2), 1j * (a_plus - a_minus) / np.sqrt(2), 0j


def compute_fields(cfg: dict) -> dict[str, np.ndarray]:
    k = 2 * np.pi
    radius = cfg["radius"]
    size = k * radius
    U, V, X, Y, Z = make_slice_grid(cfg["resolution"], cfg["grid_half_width"], cfg["slice"], cfg["slice_position"])
    ex0, ey0, ez0 = incident_polarization(cfg["nu"], cfg["psi"], cfg["geometry"])
    if cfg["geometry"] == "cylinder":
        esc, etot = _cylinder_fields(cfg, k, size, X, Y, ey0, ez0)
    else:
        esc, etot = _sphere_fields(cfg, k, size, X, Y, Z, ex0, ey0)
    r_inside = np.hypot(X, Y) < radius if cfg["geometry"] == "cylinder" else np.sqrt(X * X + Y * Y + Z * Z) < radius
    if cfg["mask_inside"]:
        esc = tuple(np.where(r_inside, np.nan + 0j, comp) for comp in esc)
    return {
        "U": U,
        "V": V,
        "X": X,
        "Y": Y,
        "Z": Z,
        "inside": r_inside,
        "Esca_x": esc[0],
        "Esca_y": esc[1],
        "Esca_z": esc[2],
        "Etot_x": etot[0],
        "Etot_y": etot[1],
        "Etot_z": etot[2],
    }


def _sphere_fields(cfg, k, size, X, Y, Z, ex0, ey0):
    an, bn = sphere_mie_coefficients(cfg["eps1"], cfg["mu1"], size, cfg["nmax_extra"])
    cn, dn = sphere_internal_coefficients(cfg["eps1"], cfg["mu1"], size, cfg["nmax_extra"])
    r = np.sqrt(X * X + Y * Y + Z * Z)
    theta = np.arccos(np.clip(np.divide(Z, np.maximum(r, 1e-12)), -1.0, 1.0))
    phi = np.arctan2(Y, X)
    inside = r < cfg["radius"]
    outside = ~inside
    u = np.cos(theta)
    sinth = np.sin(theta)
    costh = np.cos(theta)
    cosphi = np.cos(phi)
    sinphi = np.sin(phi)
    rho_out = k * np.maximum(r, 1e-9)
    nrel = np.sqrt(cfg["eps1"] * cfg["mu1"])
    rho_in = nrel * k * np.maximum(r, 1e-9)
    scat_basis = _sphere_basis(rho_out, u, sinth, costh, cosphi, sinphi, an, bn, internal=False)
    int_basis = _sphere_basis(rho_in, u, sinth, costh, cosphi, sinphi, cn, dn, internal=True)

    esc = (
        ex0 * scat_basis[0] + ey0 * scat_basis[3],
        ex0 * scat_basis[1] + ey0 * scat_basis[4],
        ex0 * scat_basis[2] + ey0 * scat_basis[5],
    )
    esc = tuple(np.where(outside, comp, 0.0 + 0.0j) for comp in esc)
    phase = np.exp(1j * k * Z)
    inc = (ex0 * phase, ey0 * phase, np.zeros_like(phase, dtype=complex))
    outside_total = tuple(inc[i] + esc[i] for i in range(3))
    inside_total = (
        ex0 * int_basis[0] + ey0 * int_basis[3],
        ex0 * int_basis[1] + ey0 * int_basis[4],
        ex0 * int_basis[2] + ey0 * int_basis[5],
    )
    etot = tuple(np.where(inside, inside_total[i], outside_total[i]) for i in range(3))
    return esc, etot


def _sphere_basis(rho, u, sinth, costh, cosphi, sinphi, first_coeffs, second_coeffs, internal: bool):
    er_x = np.zeros_like(rho, dtype=complex)
    eth_x = np.zeros_like(rho, dtype=complex)
    eph_x = np.zeros_like(rho, dtype=complex)
    er_y = np.zeros_like(rho, dtype=complex)
    eth_y = np.zeros_like(rho, dtype=complex)
    eph_y = np.zeros_like(rho, dtype=complex)
    pi_nm2 = np.zeros_like(u)
    pi_nm1 = np.ones_like(u)
    for n, (coef_e, coef_m) in enumerate(zip(first_coeffs, second_coeffs), start=1):
        if n == 1:
            pi_n = pi_nm1
            tau_n = u
        else:
            pi_n = ((2 * n - 1) / (n - 1)) * u * pi_nm1 - (n / (n - 1)) * pi_nm2
            tau_n = n * u * pi_n - (n + 1) * pi_nm1
            pi_nm2, pi_nm1 = pi_nm1, pi_n

        coef = (2 * n + 1) / (n * (n + 1))
        radial = special.spherical_jn(n, rho) if internal else special.spherical_jn(n, rho) + 1j * special.spherical_yn(n, rho)
        radial_nm1 = special.spherical_jn(n - 1, rho) if internal else special.spherical_jn(n - 1, rho) + 1j * special.spherical_yn(n - 1, rho)
        riccati_p = rho * radial_nm1 - n * radial
        den = np.maximum(rho, 1e-12)
        fac = riccati_p / den

        nr_e = cosphi * n * (n + 1) * sinth * pi_n * radial / den
        nth_e = cosphi * tau_n * fac
        nph_e = -sinphi * pi_n * fac
        mth_o = cosphi * pi_n * radial
        mph_o = -sinphi * tau_n * radial

        nr_o = -sinphi * n * (n + 1) * sinth * pi_n * radial / den
        nth_o = -sinphi * tau_n * fac
        nph_o = -cosphi * pi_n * fac
        mth_e = -sinphi * pi_n * radial
        mph_e = -cosphi * tau_n * radial

        if internal:
            er_x += coef * (-coef_m) * nr_e
            eth_x += coef * (coef_e * mth_o - coef_m * nth_e)
            eph_x += coef * (coef_e * mph_o - coef_m * nph_e)
            er_y += coef * (-coef_m) * nr_o
            eth_y += coef * (coef_e * mth_e - coef_m * nth_o)
            eph_y += coef * (coef_e * mph_e - coef_m * nph_o)
        else:
            er_x += coef * coef_e * nr_e
            eth_x += coef * (coef_e * nth_e - coef_m * mth_o)
            eph_x += coef * (coef_e * nph_e - coef_m * mph_o)
            er_y += coef * coef_e * nr_o
            eth_y += coef * (coef_e * nth_o - coef_m * mth_e)
            eph_y += coef * (coef_e * nph_o - coef_m * mph_e)

    ex_x = er_x * sinth * cosphi + eth_x * costh * cosphi - eph_x * sinphi
    ey_x = er_x * sinth * sinphi + eth_x * costh * sinphi + eph_x * cosphi
    ez_x = er_x * costh - eth_x * sinth
    ex_y = er_y * sinth * cosphi + eth_y * costh * cosphi - eph_y * sinphi
    ey_y = er_y * sinth * sinphi + eth_y * costh * sinphi + eph_y * cosphi
    ez_y = er_y * costh - eth_y * sinth
    return ex_x, ey_x, ez_x, ex_y, ey_y, ez_y


def _cylinder_fields(cfg, k, size, X, Y, ey0, ez0):
    a_e, a_m, b_e, b_m = cylinder_mie_all_coefficients(cfg["eps1"], cfg["mu1"], size, cfg["nmax_extra"])
    rho_raw = np.hypot(X, Y)
    inside = rho_raw < cfg["radius"]
    outside = ~inside
    rho = np.maximum(rho_raw, 1e-9)
    phi = np.arctan2(Y, X)
    kr = k * rho
    nrel = np.sqrt(cfg["eps1"] * cfg["mu1"])
    kr_in = nrel * k * rho
    ez_s = np.zeros_like(kr, dtype=complex)
    ephi_s = np.zeros_like(kr, dtype=complex)
    erho_s = np.zeros_like(kr, dtype=complex)
    ez_i = np.zeros_like(kr, dtype=complex)
    ephi_i = np.zeros_like(kr, dtype=complex)
    erho_i = np.zeros_like(kr, dtype=complex)
    mmax = len(a_e) - 1
    for m in range(-mmax, mmax + 1):
        mm = abs(m)
        pref = (1j ** m) * np.exp(1j * m * phi)
        h = special.hankel1(m, kr)
        hp = special.h1vp(m, kr)
        ez_s += pref * a_e[mm] * ez0 * h
        ephi_s += pref * (-1j) * a_m[mm] * ey0 * hp
        erho_s += pref * (-(m / np.maximum(kr, 1e-9))) * a_m[mm] * ey0 * h

        j = special.jv(m, kr_in)
        jp = special.jvp(m, kr_in)
        ez_i += pref * b_e[mm] * ez0 * j
        ephi_i += pref * (-1j) * (nrel / cfg["eps1"]) * b_m[mm] * ey0 * jp
        erho_i += pref * (-(m / np.maximum(kr, 1e-9))) * (1 / cfg["eps1"]) * b_m[mm] * ey0 * j

    cosphi = np.cos(phi)
    sinphi = np.sin(phi)
    esc = (
        erho_s * cosphi - ephi_s * sinphi,
        erho_s * sinphi + ephi_s * cosphi,
        ez_s,
    )
    esc = tuple(np.where(outside, comp, 0.0 + 0.0j) for comp in esc)
    phase = np.exp(1j * k * X)
    outside_total = (esc[0], ey0 * phase + esc[1], ez0 * phase + esc[2])
    inside_total = (
        erho_i * cosphi - ephi_i * sinphi,
        erho_i * sinphi + ephi_i * cosphi,
        ez_i,
    )
    etot = tuple(np.where(inside, inside_total[i], outside_total[i]) for i in range(3))
    return esc, etot


def evaluate_field(code: str, fields: dict[str, np.ndarray]) -> tuple[np.ndarray, str, bool]:
    family, kind = code.split("_", 1)
    prefix = "Esca" if family == "sca" else "Etot"
    ex = fields[f"{prefix}_x"]
    ey = fields[f"{prefix}_y"]
    ez = fields[f"{prefix}_z"]
    long = "scattered" if family == "sca" else "total"
    if kind == "rex":
        return np.real(ex), f"{long} $\\Re E_x$", True
    if kind == "rey":
        return np.real(ey), f"{long} $\\Re E_y$", True
    if kind == "rez":
        return np.real(ez), f"{long} $\\Re E_z$", True
    if kind == "aex":
        return np.abs(ex), f"{long} $|E_x|$", False
    if kind == "aey":
        return np.abs(ey), f"{long} $|E_y|$", False
    if kind == "aez":
        return np.abs(ez), f"{long} $|E_z|$", False
    return np.sqrt(np.abs(ex) ** 2 + np.abs(ey) ** 2 + np.abs(ez) ** 2), f"{long} $E_{{mag}}$", False
