from __future__ import annotations

from dataclasses import replace

import numpy as np
from scipy import optimize, signal

from .graphite import build_chi_image, graphite_area, graphite_extent, sample_mask
from .magnetics import build_compact_checkerboard_magnets, evaluate_dipole_field_map
from .params import GraphiteParams


def _norm_positive(value):
    finite = np.isfinite(value)
    if not np.any(finite):
        return value
    vmin = np.nanmin(value)
    vmax = np.nanmax(value)
    return (value - vmin) / max(vmax - vmin, 1e-15)


def _norm_signed(value):
    finite = np.isfinite(value)
    if not np.any(finite):
        return value
    vmax = np.nanmax(np.abs(value))
    return value / max(vmax, 1e-15)


def _mass_and_weight(params: GraphiteParams) -> tuple[float, float]:
    mass = params.rho * graphite_area(params) * params.thickness
    return mass, mass * 9.80665


def _energy_from_field(field: dict, kernel: np.ndarray, dx: float, dy: float, params: GraphiteParams) -> np.ndarray:
    b2 = field["Bx"] ** 2 + field["By"] ** 2 + field["Bz"] ** 2
    coefficient = params.thickness * params.chi_abs / (2 * params.mu0)
    return signal.fftconvolve(b2, np.rot90(kernel, 2), mode="same") * dx * dy * coefficient


def _compute_single_maps(params: GraphiteParams) -> dict:
    magnets = build_compact_checkerboard_magnets(params)
    extent = max(params.array_nx * params.magnet_a, params.array_ny * params.magnet_b) * 0.65 + graphite_extent(params)
    x = np.linspace(-extent, extent, params.grid_n)
    y = np.linspace(-extent, extent, params.grid_n)
    X, Y = np.meshgrid(x, y)
    dz = max(params.force_dz, 5e-6)
    B0 = evaluate_dipole_field_map(X, Y, params.z0, magnets, params)
    Bp = evaluate_dipole_field_map(X, Y, params.z0 + dz, magnets, params)
    Bm = evaluate_dipole_field_map(X, Y, max(params.z0 - dz, 1e-6), magnets, params)
    B2 = B0["Bx"] ** 2 + B0["By"] ** 2 + B0["Bz"] ** 2
    dx = float(np.mean(np.diff(x)))
    dy = float(np.mean(np.diff(y)))
    kernel, _ = _kernel_on_grid(params, dx, dy)
    U = _energy_from_field(B0, kernel, dx, dy, params)
    Up = _energy_from_field(Bp, kernel, dx, dy, params)
    Um = _energy_from_field(Bm, kernel, dx, dy, params)
    Fz = -(Up - Um) / (2 * dz)
    Gy, Gx = np.gradient(U, y, x)
    chi_x, chi_y, chi = build_chi_image(params)
    return {
        "params": params,
        "magnets": magnets,
        "x": x,
        "y": y,
        "B": B0,
        "B2": B2,
        "B2_norm": _norm_positive(B2),
        "U": U,
        "U_norm": _norm_positive(U),
        "Fx": -Gx,
        "Fy": -Gy,
        "Fz": Fz,
        "Fx_norm": _norm_signed(-Gx),
        "Fy_norm": _norm_signed(-Gy),
        "Fz_norm": _norm_signed(Fz),
        "chi": {"x": chi_x, "y": chi_y, "weight": chi},
    }


def _kernel_on_grid(params: GraphiteParams, dx: float, dy: float) -> tuple[np.ndarray, np.ndarray]:
    extent = graphite_extent(params) * 1.08
    x = np.arange(-extent, extent + dx, dx)
    y = np.arange(-extent, extent + dy, dy)
    X, Y = np.meshgrid(x, y)
    mask = sample_mask(X, Y, params)
    weight = _susceptibility_weight(X, Y, params)
    weight[~mask] = 0.0
    return weight, mask


def _susceptibility_weight(X: np.ndarray, Y: np.ndarray, params: GraphiteParams) -> np.ndarray:
    weight = np.ones_like(X, dtype=float)
    if params.laser_enabled:
        sigma = max(params.spot_diameter / 2.355, 1e-9)
        gaussian = np.exp(-((X - params.spot_x) ** 2 + (Y - params.spot_y) ** 2) / (2 * sigma * sigma))
        weight *= np.maximum(0.02, 1 - params.laser_alpha * gaussian)
    return weight


def _interior_mask(x: np.ndarray, y: np.ndarray, U: np.ndarray, params: GraphiteParams) -> np.ndarray:
    X, Y = np.meshgrid(x, y)
    half_x = max(params.array_nx * params.magnet_a / 2 - params.magnet_a / 2, np.max(np.abs(x)) * 0.5)
    half_y = max(params.array_ny * params.magnet_b / 2 - params.magnet_b / 2, np.max(np.abs(y)) * 0.5)
    inner = (np.abs(X) <= half_x) & (np.abs(Y) <= half_y) & np.isfinite(U)
    return inner if np.any(inner) else np.isfinite(U)


def _stable_points(x: np.ndarray, y: np.ndarray, U: np.ndarray, inner: np.ndarray) -> dict:
    empty = {"x": np.array([]), "y": np.array([]), "U": np.array([]), "ix": np.array([], dtype=int), "iy": np.array([], dtype=int), "count": 0}
    if U.shape[0] < 3 or U.shape[1] < 3:
        return empty
    center = U[1:-1, 1:-1]
    is_min = inner[1:-1, 1:-1] & np.isfinite(center)
    for row_offset in (-1, 0, 1):
        for col_offset in (-1, 0, 1):
            if row_offset or col_offset:
                is_min &= center <= U[1 + row_offset:U.shape[0] - 1 + row_offset, 1 + col_offset:U.shape[1] - 1 + col_offset]
    iy, ix = np.nonzero(is_min)
    ix = ix + 1
    iy = iy + 1
    if ix.size == 0:
        return empty
    order = np.argsort(U[iy, ix])
    ix, iy = ix[order], iy[order]
    kept_ix: list[int] = []
    kept_iy: list[int] = []
    for candidate_x, candidate_y in zip(ix, iy):
        if all(abs(candidate_x - prior_x) > 1 or abs(candidate_y - prior_y) > 1 for prior_x, prior_y in zip(kept_ix, kept_iy)):
            kept_ix.append(int(candidate_x))
            kept_iy.append(int(candidate_y))
    ix = np.asarray(kept_ix, dtype=int)
    iy = np.asarray(kept_iy, dtype=int)
    return {"x": x[ix], "y": y[iy], "U": U[iy, ix], "ix": ix, "iy": iy, "count": int(ix.size)}


def _planar_metrics(data: dict) -> dict:
    x, y, U, B2, params = data["x"], data["y"], data["U"], data["B2"], data["params"]
    inner = _interior_mask(x, y, U, params)
    stable = _stable_points(x, y, U, inner)
    if stable["count"]:
        ix, iy = int(stable["ix"][0]), int(stable["iy"][0])
    else:
        search = np.where(inner, U, np.nan)
        iy, ix = np.unravel_index(np.nanargmin(search), U.shape)
    dx, dy = x[1] - x[0], y[1] - y[0]
    kx = (U[iy, ix + 1] - 2 * U[iy, ix] + U[iy, ix - 1]) / dx**2 if 0 < ix < len(x) - 1 else np.nan
    ky = (U[iy + 1, ix] - 2 * U[iy, ix] + U[iy - 1, ix]) / dy**2 if 0 < iy < len(y) - 1 else np.nan
    return {
        "x_min": float(x[ix]), "y_min": float(y[iy]), "u_min": float(U[iy, ix]), "b2_at_min": float(B2[iy, ix]),
        "stable": stable, "stable_count": stable["count"], "kx": float(kx), "ky": float(ky),
    }


def _force_distribution(params: GraphiteParams, x0: float, y0: float, z: float) -> dict:
    count = max(25, int(params.force_kernel_n))
    if count % 2 == 0:
        count += 1
    extent = graphite_extent(params) * 1.08
    sample_x = np.linspace(-extent, extent, count)
    sample_y = np.linspace(-extent, extent, count)
    Xrel, Yrel = np.meshgrid(sample_x, sample_y)
    mask = sample_mask(Xrel, Yrel, params)
    weight = _susceptibility_weight(Xrel, Yrel, params)
    dx = sample_x[1] - sample_x[0]
    dy = sample_y[1] - sample_y[0]
    magnets = build_compact_checkerboard_magnets(params)
    dz = max(params.force_dz, 5e-6)
    X, Y = x0 + Xrel, y0 + Yrel
    B0 = evaluate_dipole_field_map(X, Y, z, magnets, params)
    Bp = evaluate_dipole_field_map(X, Y, z + dz, magnets, params)
    Bm = evaluate_dipole_field_map(X, Y, max(z - dz, 1e-6), magnets, params)
    b20 = B0["Bx"] ** 2 + B0["By"] ** 2 + B0["Bz"] ** 2
    b2p = Bp["Bx"] ** 2 + Bp["By"] ** 2 + Bp["Bz"] ** 2
    b2m = Bm["Bx"] ** 2 + Bm["By"] ** 2 + Bm["Bz"] ** 2
    coefficient = params.thickness * params.chi_abs / (2 * params.mu0)
    dB2dz = (b2p - b2m) / (2 * dz)
    d2B2dz2 = (b2p - 2 * b20 + b2m) / dz**2
    area = dx * dy
    fz = -coefficient * weight * dB2dz * area
    dfdz = -coefficient * weight * d2B2dz2 * area
    fz[~mask] = 0.0
    dfdz[~mask] = 0.0
    potential = float(np.sum((coefficient * weight * b20 * area)[mask]))
    return {"Xrel": Xrel, "Yrel": Yrel, "valid": mask, "fz": fz, "dfdz": dfdz, "potential": potential}


def _vertical_force_at_position(params: GraphiteParams, x0: float, y0: float, z: float) -> float:
    return float(np.sum(_force_distribution(params, x0, y0, z)["fz"]))


def _solve_vertical_equilibrium(params: GraphiteParams, x0: float, y0: float) -> tuple[float, dict]:
    _, weight = _mass_and_weight(params)
    z_low = min(max(0.08e-3, 0.08 * params.magnet_c), 0.20e-3)
    z_high = max(8e-3, 1.2 * params.magnet_c)
    force = lambda z: _vertical_force_at_position(params, x0, y0, z)
    info = {"z_solve_converged": False, "z_solve_message": "not solved", "fz_eq": np.nan}
    try:
        low_value, high_value = force(z_low) - weight, force(z_high) - weight
        for _ in range(3):
            if high_value <= 0:
                break
            z_high *= 1.6
            high_value = force(z_high) - weight
        if low_value < 0:
            z_eq = params.z0
            info["z_solve_message"] = "magnetic force is below weight near the magnet surface; using input height"
        elif high_value > 0:
            z_eq = params.z0
            info["z_solve_message"] = "magnetic force remains above weight at the search ceiling; using input height"
        else:
            z_eq = float(optimize.brentq(lambda z: force(z) - weight, z_low, z_high))
            info["z_solve_converged"] = True
            info["z_solve_message"] = "Fz = mg solved"
        info["fz_eq"] = force(z_eq)
        return z_eq, info
    except (ArithmeticError, ValueError) as exc:
        info["z_solve_message"] = f"vertical solver failed: {exc}"
        return params.z0, info


def _estimate_magnetic_tilt(params: GraphiteParams, x0: float, y0: float, z: float) -> dict:
    force = _force_distribution(params, x0, y0, z)
    X, Y, fz, dfdz, valid = force["Xrel"], force["Yrel"], force["fz"], force["dfdz"], force["valid"]
    tau_x = float(np.sum(Y[valid] * fz[valid]))
    tau_y = float(-np.sum(X[valid] * fz[valid]))
    k_theta_x = float(-np.sum(Y[valid] ** 2 * dfdz[valid]))
    k_theta_y = float(-np.sum(X[valid] ** 2 * dfdz[valid]))
    if not np.isfinite(k_theta_x) or k_theta_x <= 0:
        k_theta_x = params.torsional_stiffness
    if not np.isfinite(k_theta_y) or k_theta_y <= 0:
        k_theta_y = params.torsional_stiffness
    theta_x, theta_y = tau_x / k_theta_x, tau_y / k_theta_y
    return {
        "theta_x": float(theta_x), "theta_y": float(theta_y), "theta_mag": float(np.hypot(theta_x, theta_y)),
        "tau_x": tau_x, "tau_y": tau_y, "k_theta_x": k_theta_x, "k_theta_y": k_theta_y,
    }


def _pose_list(params: GraphiteParams, stable: dict, z: float, include_tilt: bool) -> dict:
    count = stable["count"]
    poses = {
        "x": np.asarray(stable["x"]), "y": np.asarray(stable["y"]), "z": np.full(count, z), "U": np.asarray(stable["U"]),
        "theta_x": np.zeros(count), "theta_y": np.zeros(count), "theta_mag": np.zeros(count), "count": count,
    }
    if include_tilt:
        for index in range(count):
            tilt = _estimate_magnetic_tilt(params, poses["x"][index], poses["y"][index], z)
            poses["theta_x"][index] = tilt["theta_x"]
            poses["theta_y"][index] = tilt["theta_y"]
            poses["theta_mag"][index] = tilt["theta_mag"]
    poses.update({"thetaX": poses["theta_x"], "thetaY": poses["theta_y"], "thetaMag": poses["theta_mag"]})
    return poses


def scan_equilibrium_metrics(params: GraphiteParams, samples: int = 9, x0: float = 0.0, y0: float = 0.0) -> dict:
    """Return a low-resolution vertical-force diagnostic at a specified planar well."""
    z_values = np.linspace(max(params.z0 * 0.55, 1e-6), params.z0 * 1.65, int(samples))
    _, weight = _mass_and_weight(params)
    distributions = [_force_distribution(params, x0, y0, float(z)) for z in z_values]
    forces = np.asarray([np.sum(distribution["fz"]) for distribution in distributions])
    potentials = np.asarray([distribution["potential"] for distribution in distributions])
    index = int(np.nanargmin(np.abs(forces - weight))) if np.isfinite(forces).any() else 0
    stiffness = np.gradient(forces, z_values)
    return {
        "z_scan": z_values, "f_scan": forces, "u_scan": potentials,
        "z_balance": float(z_values[index]), "force_over_weight": float(forces[index] / max(weight, 1e-30)),
        "vertical_stiffness": float(stiffness[index]),
    }


def _case_metrics(base_maps: dict, active_maps: dict, z_eq: float, z_info: dict, input_z: float) -> tuple[dict, dict]:
    base_planar, active_planar = _planar_metrics(base_maps), _planar_metrics(active_maps)
    params = active_maps["params"]
    mass, weight = _mass_and_weight(params)
    z_on, on_info = _solve_vertical_equilibrium(params, active_planar["x_min"], active_planar["y_min"])
    base_force = _vertical_force_at_position(base_maps["params"], base_planar["x_min"], base_planar["y_min"], z_eq)
    active_force = _vertical_force_at_position(params, active_planar["x_min"], active_planar["y_min"], z_eq)
    tilt = _estimate_magnetic_tilt(params, active_planar["x_min"], active_planar["y_min"], z_eq) if params.laser_enabled else {
        "theta_x": 0.0, "theta_y": 0.0, "theta_mag": 0.0,
        "tau_x": 0.0, "tau_y": 0.0, "k_theta_x": np.nan, "k_theta_y": np.nan,
    }
    poses_off = _pose_list(base_maps["params"], base_planar["stable"], z_eq, False)
    poses_on = _pose_list(params, active_planar["stable"], z_eq, params.laser_enabled)
    dx_laser, dy_laser = active_planar["x_min"] - base_planar["x_min"], active_planar["y_min"] - base_planar["y_min"]
    equilibrium = scan_equilibrium_metrics(base_maps["params"], x0=base_planar["x_min"], y0=base_planar["y_min"])
    base_metrics = {
        **base_planar, "mass": mass, "weight": weight, **equilibrium, "z_balance": z_eq,
        "force_over_weight": base_force / max(weight, 1e-30), "fz_at_min": base_force,
        "theta_x": 0.0, "theta_y": 0.0, "theta_mag": 0.0, "poses": poses_off,
    }
    active_metrics = {
        **active_planar, "mass": mass, "weight": weight, **equilibrium, "z_balance": z_eq,
        "force_over_weight": active_force / max(weight, 1e-30), "fz_at_min": active_force,
        "x_min_off": base_planar["x_min"], "y_min_off": base_planar["y_min"], "x_min_on": active_planar["x_min"], "y_min_on": active_planar["y_min"],
        "dx_laser": dx_laser, "dy_laser": dy_laser, "displacement": float(np.hypot(dx_laser, dy_laser)),
        "z_input": input_z, "z_eq_off": z_eq, "z_eq_on": z_on, **z_info, "fz_on_eq": on_info["fz_eq"],
        "fz_off_at_min": base_force, "fz_on_at_min": active_force, "fz_off_over_weight": base_force / max(weight, 1e-30), "fz_on_over_weight": active_force / max(weight, 1e-30),
        "fx_laser_proxy": base_planar["kx"] * dx_laser, "fy_laser_proxy": base_planar["ky"] * dy_laser,
        **tilt, "stable_off": base_planar["stable"], "stable_on": active_planar["stable"], "poses_off": poses_off, "poses_on": poses_on,
    }
    active_metrics["f_laser_proxy"] = float(np.hypot(active_metrics["fx_laser_proxy"], active_metrics["fy_laser_proxy"]))
    active_metrics["f_laser_over_weight"] = active_metrics["f_laser_proxy"] / max(weight, 1e-30)
    active_metrics.update({
        "xMinOff": active_metrics["x_min_off"], "yMinOff": active_metrics["y_min_off"], "xMinOn": active_metrics["x_min_on"], "yMinOn": active_metrics["y_min_on"],
        "dxLaser": dx_laser, "dyLaser": dy_laser, "zEqOff": z_eq, "zEqOn": z_on,
        "thetaX": tilt["theta_x"], "thetaY": tilt["theta_y"], "thetaMag": tilt["theta_mag"],
        "tauX": tilt["tau_x"], "tauY": tilt["tau_y"], "KthetaX": tilt["k_theta_x"], "KthetaY": tilt["k_theta_y"],
        "stableOff": base_planar["stable"], "stableOn": active_planar["stable"], "posesOff": poses_off, "posesOn": poses_on,
    })
    return base_metrics, active_metrics


def compute_visualization_maps(params: GraphiteParams):
    """Compute no-laser/laser maps at the no-laser mechanical equilibrium height."""
    input_z = params.z0
    params_off = replace(params, laser_enabled=False, laser_alpha=0.0)
    initial_planar = _planar_metrics(_compute_single_maps(params_off))
    z_eq, z_info = _solve_vertical_equilibrium(params_off, initial_planar["x_min"], initial_planar["y_min"])
    base_params = replace(params_off, z0=z_eq)
    active_params = replace(params, z0=z_eq)
    base_maps = _compute_single_maps(base_params)
    active_maps = _compute_single_maps(active_params)
    base_metrics, active_metrics = _case_metrics(base_maps, active_maps, z_eq, z_info, input_z)
    base_maps["metrics"] = base_metrics
    active_maps["metrics"] = active_metrics
    active_maps["base"] = base_maps
    active_maps["active"] = active_maps
    active_maps["input_params"] = params
    return active_maps
