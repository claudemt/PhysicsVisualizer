from __future__ import annotations

import numpy as np
from scipy import integrate, special


def compute_1d_curves(variant_key: str, x: np.ndarray, args: np.ndarray) -> list[dict]:
    key = str(variant_key)
    if args.size == 0:
        args = np.zeros((1, 0))
    curves: list[dict] = []
    for row in np.atleast_2d(args):
        y, label = _evaluate(key, x, row)
        curves.append({"x": x, "y": np.asarray(y, dtype=float), "label": label})
    return curves


def _evaluate(key: str, x: np.ndarray, row: np.ndarray):
    if key == "j":
        nu = row[0] if row.size else 0
        return special.jv(nu, x), rf"$J_{{{nu:g}}}(x)$"
    if key == "y":
        nu = row[0] if row.size else 0
        return special.yv(nu, x), rf"$Y_{{{nu:g}}}(x)$"
    if key == "i":
        nu = row[0] if row.size else 0
        return special.iv(nu, x), rf"$I_{{{nu:g}}}(x)$"
    if key == "k":
        nu = row[0] if row.size else 0
        return special.kv(nu, np.maximum(x, 1e-8)), rf"$K_{{{nu:g}}}(x)$"
    if key == "spherical_j":
        n = int(round(row[0] if row.size else 0))
        return special.spherical_jn(n, x), rf"$j_{{{n}}}(x)$"
    if key == "spherical_y":
        n = int(round(row[0] if row.size else 0))
        return special.spherical_yn(n, x), rf"$y_{{{n}}}(x)$"
    if key in {"ai", "bi", "aip", "bip"}:
        ai, aip, bi, bip = special.airy(x)
        values = {"ai": ai, "bi": bi, "aip": aip, "bip": bip}
        labels = {"ai": "Ai(x)", "bi": "Bi(x)", "aip": "Ai'(x)", "bip": "Bi'(x)"}
        return values[key], labels[key]
    if key == "lane_emden":
        n = row[0] if row.size else 3
        return _lane_emden(x, n), rf"$\theta_{{n={n:g}}}$"
    if key == "ellipk":
        return special.ellipk(np.clip(x, 0.0, 0.999999)), "$K(m)$"
    if key == "ellipe":
        return special.ellipe(np.clip(x, 0.0, 0.999999)), "$E(m)$"
    if key == "ellipf_inc":
        m = row[0] if row.size else 0.5
        return special.ellipkinc(x, m), rf"$F(\phi|m={m:g})$"
    if key == "ellipe_inc":
        m = row[0] if row.size else 0.5
        return special.ellipeinc(x, m), rf"$E(\phi|m={m:g})$"
    if key == "ellippi_inc":
        characteristic = row[0] if row.size else 0.2
        m = row[1] if row.size > 1 else 0.5
        return _ellippi_inc(characteristic, x, m), rf"$\Pi({characteristic:g};\phi|{m:g})$"
    if key in {"sn", "cn", "dn"}:
        m = row[0] if row.size else 0.5
        sn, cn, dn, _ = special.ellipj(x, m)
        return {"sn": sn, "cn": cn, "dn": dn}[key], rf"${key}(u|m={m:g})$"
    if key == "hyp2f1":
        a = row[0] if row.size else 0.5
        b = row[1] if row.size > 1 else 1.0
        c = row[2] if row.size > 2 else 2.0
        return _hyp2f1_series(a, b, c, x), rf"$_2F_1({a:g},{b:g};{c:g};x)$"
    return special.jv(0, x), "$J_0(x)$"


def _lane_emden(x: np.ndarray, n: float) -> np.ndarray:
    xmax = max(float(np.max(x)), 1e-6)

    def ode(xi, state):
        theta, dtheta = state
        if xi == 0:
            dd = 0.0
        else:
            source = theta**n if theta >= 0 else 0.0
            dd = -source - 2.0 / xi * dtheta
        return [dtheta, dd]

    def stop_at_zero(xi, state):
        if xi < 1e-5:
            return 1.0
        return state[0]

    stop_at_zero.terminal = True
    stop_at_zero.direction = -1
    xi0 = 1e-5
    theta0 = 1.0 - xi0**2 / 6.0
    dtheta0 = -xi0 / 3.0
    sol = integrate.solve_ivp(ode, (xi0, xmax), [theta0, dtheta0], events=stop_at_zero, rtol=1e-8, atol=1e-10, dense_output=True)
    out = np.empty_like(x, dtype=float)
    zero_at = sol.t_events[0][0] if sol.t_events and sol.t_events[0].size else np.inf
    eval_x = np.clip(np.maximum(x, xi0), xi0, min(xmax, zero_at))
    out[:] = sol.sol(eval_x)[0] if sol.sol is not None else np.interp(eval_x, sol.t, sol.y[0])
    out[x >= zero_at] = 0.0
    out[x <= xi0] = 1.0
    return out


def _hyp2f1_series(a: float, b: float, c: float, z: np.ndarray, max_terms: int = 700) -> np.ndarray:
    if c == round(c) and c <= 0:
        return np.full_like(z, np.nan, dtype=float)
    y = np.ones_like(z, dtype=float)
    term = np.ones_like(z, dtype=float)
    for k in range(1, max_terms + 1):
        denom = (c + k - 1) * k
        if abs(denom) < np.finfo(float).eps:
            return np.full_like(z, np.nan, dtype=float)
        term = term * ((a + k - 1) * (b + k - 1) / denom) * z
        y_new = y + term
        if np.nanmax(np.abs(term)) < 1e-12 * max(1.0, float(np.nanmax(np.abs(y_new)))):
            return y_new
        y = y_new
    return y


def _ellippi_inc(characteristic: float, phi: np.ndarray, m: float) -> np.ndarray:
    values = []
    for upper in np.ravel(phi):
        val, _ = integrate.quad(
            lambda t: 1.0 / ((1.0 - characteristic * np.sin(t) ** 2) * np.sqrt(1.0 - m * np.sin(t) ** 2)),
            0.0,
            float(upper),
            limit=120,
        )
        values.append(val)
    return np.asarray(values).reshape(phi.shape)
