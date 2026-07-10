from __future__ import annotations

import numpy as np
from scipy import special


def _psi(n: np.ndarray, z: complex) -> np.ndarray:
    return z * special.spherical_jn(n, z)


def _psi_p(n: np.ndarray, z: complex) -> np.ndarray:
    return special.spherical_jn(n, z) + z * special.spherical_jn(n, z, derivative=True)


def _xi(n: np.ndarray, z: complex) -> np.ndarray:
    return z * (special.spherical_jn(n, z) + 1j * special.spherical_yn(n, z))


def _xi_p(n: np.ndarray, z: complex) -> np.ndarray:
    h = special.spherical_jn(n, z) + 1j * special.spherical_yn(n, z)
    hp = special.spherical_jn(n, z, derivative=True) + 1j * special.spherical_yn(n, z, derivative=True)
    return h + z * hp


def sphere_mie_coefficients(epsr: complex, mur: complex, size_parameter: float, extra: int = 10) -> tuple[np.ndarray, np.ndarray]:
    x = complex(size_parameter)
    m = np.sqrt(epsr * mur)
    zrel = np.sqrt(mur / epsr)
    nmax = max(1, int(np.ceil(size_parameter + 4 * size_parameter ** (1 / 3) + 2 + extra)))
    n = np.arange(1, nmax + 1)
    z = m * x
    nstart = int(round(max(nmax, abs(z)) + 16))
    d_log = np.zeros(nmax, dtype=complex)
    d_next = 0.0j
    for order in range(nstart, 0, -1):
        d_cur = (order / z) - 1 / (d_next + (order / z))
        if order <= nmax:
            d_log[order - 1] = d_cur
        d_next = d_cur

    psi = _psi(n, x)
    xi = _xi(n, x)
    psi_m1 = np.concatenate(([np.sin(x)], psi[:-1]))
    xi_m1 = np.concatenate(([-1j * np.exp(1j * x)], xi[:-1]))
    psi_p = psi_m1 - (n * psi) / x
    xi_p = xi_m1 - (n * xi) / x

    an = ((d_log / zrel) * psi - psi_p) / ((d_log / zrel) * xi - xi_p)
    bn = ((zrel * d_log) * psi - psi_p) / ((zrel * d_log) * xi - xi_p)
    return an, bn


def sphere_internal_coefficients(epsr: complex, mur: complex, size_parameter: float, extra: int = 10) -> tuple[np.ndarray, np.ndarray]:
    x = complex(size_parameter)
    m = np.sqrt(epsr * mur)
    nmax = max(1, int(np.ceil(size_parameter + 4 * size_parameter ** (1 / 3) + 2 + extra)))
    n = np.arange(1, nmax + 1)
    jx = special.spherical_jn(n, x)
    hx = special.spherical_jn(n, x) + 1j * special.spherical_yn(n, x)
    xjx_p = x * special.spherical_jn(n - 1, x) - n * special.spherical_jn(n, x)
    xhx_p = x * (special.spherical_jn(n - 1, x) + 1j * special.spherical_yn(n - 1, x)) - n * hx
    mx = m * x
    jmx = special.spherical_jn(n, mx)
    mxjmx_p = mx * special.spherical_jn(n - 1, mx) - n * special.spherical_jn(n, mx)
    common = jx * xhx_p - hx * xjx_p
    cn = mur * common / (mur * jmx * xhx_p - hx * mxjmx_p)
    dn = m * common / (epsr * jmx * xhx_p - hx * mxjmx_p)
    return cn, dn


def cylinder_mie_coefficients(epsr: complex, mur: complex, size_parameter: float, extra: int = 10) -> tuple[np.ndarray, np.ndarray]:
    a_e, a_m, _, _ = cylinder_mie_all_coefficients(epsr, mur, size_parameter, extra)
    return a_e, a_m


def cylinder_mie_all_coefficients(epsr: complex, mur: complex, size_parameter: float, extra: int = 10) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    x = float(size_parameter)
    nrel = np.sqrt(epsr * mur)
    zrel = np.sqrt(mur / epsr)
    mmax = max(1, int(np.ceil(x + 4 * x ** (1 / 3) + 2 + extra)))
    orders = np.arange(0, mmax + 1)
    jx = special.jv(orders, x)
    hx = special.hankel1(orders, x)
    jxp = special.jvp(orders, x)
    hxp = special.h1vp(orders, x)
    jnx = special.jv(orders, nrel * x)
    jnxp = special.jvp(orders, nrel * x)
    den_e = zrel * jnx * hxp - hx * jnxp
    den_m = jnx * hxp - zrel * hx * jnxp
    a_e = -(zrel * jnx * jxp - jx * jnxp) / den_e
    a_m = -(jnx * jxp - zrel * jx * jnxp) / den_m
    b_e = (2j / (np.pi * x)) * (zrel / den_e)
    b_m = (2j / (np.pi * x)) * (1 / den_m)
    return a_e, a_m, b_e, b_m
