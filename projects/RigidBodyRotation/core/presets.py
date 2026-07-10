from __future__ import annotations


_FREE_COMPARE_VARIATIONS = (
    ((1.0, 1.0, 1.0), 0.0),
    ((1.55, 0.72, 2.60), 0.35),
    ((0.55, 1.34, -1.80), -0.32),
)

_FIXED_COMPARE_VARIATIONS = (
    ((0.0, 0.0, 0.0), (0.0, 0.0, 0.0)),
    ((0.22, 0.14, -0.28), (0.65, -0.45, -0.90)),
    ((-0.38, -0.17, 0.22), (-0.55, 0.36, 0.90)),
)


def _number(value: float) -> str:
    return f"{value:.12g}"


def free_compare_rows(w0, phi0: float) -> str:
    values = []
    for scale, phi_offset in _FREE_COMPARE_VARIATIONS:
        row = [float(w0[index]) * scale[index] for index in range(3)]
        row.append(float(phi0) + phi_offset)
        values.append("[" + " ".join(_number(value) for value in row) + "]")
    return "\n".join(values)


def fixed_compare_rows(euler0, w0) -> str:
    values = []
    for euler_offset, omega_offset in _FIXED_COMPARE_VARIATIONS:
        row = [float(euler0[index]) + euler_offset[index] for index in range(3)]
        row.extend(float(w0[index]) + omega_offset[index] for index in range(3))
        values.append("[" + " ".join(_number(value) for value in row) + "]")
    return "\n".join(values)


def _free_preset(I, w0, phi0, t_end, samples):
    return {
        "I": " ".join(_number(value) for value in I),
        "w0": " ".join(_number(value) for value in w0),
        "phi0": phi0,
        "tEnd": t_end,
        "nSamples": samples,
        "compare_rows": free_compare_rows(w0, phi0),
    }


def _fixed_preset(I, a_body, mass, gravity, euler0, w0, t_end, samples):
    return {
        "I": " ".join(_number(value) for value in I),
        "aBody": " ".join(_number(value) for value in a_body),
        "mass": mass,
        "g": gravity,
        "Euler0": " ".join(_number(value) for value in euler0),
        "w0": " ".join(_number(value) for value in w0),
        "tEnd": t_end,
        "nSamples": samples,
        "compare_rows": fixed_compare_rows(euler0, w0),
    }


FREE_PRESETS = {
    "Tennis-racket flip": _free_preset((1, 2, 3), (0.18, 2.2, 0.04), 0.0, 18, 2200),
    "Near axis-1 rotation": _free_preset((1, 2, 3), (2.4, 0.12, 0.06), 0.3, 18, 2200),
    "Near axis-3 rotation": _free_preset((1, 2, 3), (0.08, 0.14, 2.0), 0.6, 18, 2200),
}

FIXED_PRESETS = {
    "Regular-precession-like": _fixed_preset((1, 1.4, 2), (0, 0, 1), 1, 9.81, (0, 0.55, 0), (0, 0, 15), 8, 2000),
    "General top with nutation": _fixed_preset((1, 1.8, 2.2), (0, 0, 1), 1, 9.81, (0.2, 0.95, 0.1), (0.8, 0.1, 10), 10, 2400),
    "General heavy body": _fixed_preset((0.9, 1.3, 1.8), (0.22, 0.10, 0.92), 1, 9.81, (0.35, 1.00, 0.25), (1.6, -0.5, 8.5), 12, 2600),
}


MODE_PRESETS = {
    "free rotation": {"free_preset": "Tennis-racket flip", "compare": False, **FREE_PRESETS["Tennis-racket flip"]},
    "fixed point": {"fixed_preset": "Regular-precession-like", "compare": False, **FIXED_PRESETS["Regular-precession-like"]},
}
