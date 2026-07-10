from __future__ import annotations

import numpy as np


def _snell_refraction(direction: np.ndarray, normal: np.ndarray, n1: float, n2: float):
    incident = np.asarray(direction, dtype=float)
    incident /= max(float(np.linalg.norm(incident)), np.finfo(float).eps)
    normal_12 = np.asarray(normal, dtype=float)
    normal_12 /= max(float(np.linalg.norm(normal_12)), np.finfo(float).eps)
    cos_i = -float(np.dot(normal_12, incident))
    eta = float(n1) / float(n2)
    kappa = 1.0 - eta**2 * (1.0 - cos_i**2)
    if kappa < 0:
        reflected = incident + 2.0 * cos_i * normal_12
        return reflected / max(float(np.linalg.norm(reflected)), np.finfo(float).eps), True
    transmitted = eta * incident + (eta * cos_i - np.sqrt(kappa)) * normal_12
    return transmitted / max(float(np.linalg.norm(transmitted)), np.finfo(float).eps), False


def snell_refraction(direction: np.ndarray, normal: np.ndarray, n1: float, n2: float) -> np.ndarray:
    return _snell_refraction(direction, normal, n1, n2)[0]


def fresnel_coefficients(theta_i: np.ndarray | float, n1: float, n2: float):
    ti = np.asarray(theta_i, dtype=float)
    sin_t = float(n1) / float(n2) * np.sin(ti)
    valid = np.abs(sin_t) <= 1.0
    tt = np.zeros_like(ti)
    tt[valid] = np.arcsin(sin_t[valid])
    ci = np.cos(ti)
    ct = np.cos(tt)
    eps = np.finfo(float).eps
    rs = (n1 * ci - n2 * ct) / (n1 * ci + n2 * ct + eps)
    rp = (n2 * ci - n1 * ct) / (n2 * ci + n1 * ct + eps)
    rs = np.where(valid, rs, 1.0)
    rp = np.where(valid, rp, 1.0)
    reflectance_s = np.abs(rs) ** 2
    reflectance_p = np.abs(rp) ** 2
    return {
        "rs": rs,
        "rp": rp,
        "ts": 1.0 - reflectance_s,
        "tp": 1.0 - reflectance_p,
        "Rs": reflectance_s,
        "Rp": reflectance_p,
        "theta_t": tt,
        "total_internal_reflection": ~valid,
    }


def trace_thin_lens_bundle(
    object_distance: float,
    focal_length: float,
    height: float,
    aperture: float,
    ray_count: int = 13,
):
    object_distance = float(object_distance)
    focal_length = float(focal_length)
    height = float(height)
    ray_heights = np.linspace(-abs(float(aperture)), abs(float(aperture)), int(ray_count))
    denominator = 1.0 / focal_length - 1.0 / object_distance
    image_distance = np.copysign(1e12, denominator if denominator else 1.0) if abs(denominator) < 1e-12 else 1.0 / denominator
    image_height = -image_distance / object_distance * height
    segments_in = np.column_stack((
        np.full_like(ray_heights, -object_distance),
        np.full_like(ray_heights, height),
        np.zeros_like(ray_heights),
        ray_heights,
    ))
    segments_out = np.column_stack((
        np.zeros_like(ray_heights),
        ray_heights,
        np.full_like(ray_heights, image_distance),
        np.full_like(ray_heights, image_height),
    ))
    rays = [np.array([[a, b], [c, d], [e, f]]) for (a, b, c, d), (_, _, e, f) in zip(segments_in, segments_out)]
    return {
        "rays": rays,
        "segments_in": segments_in,
        "segments_out": segments_out,
        "image_distance": image_distance,
        "image_height": image_height,
        "magnification": image_height / height if height else -image_distance / object_distance,
    }


def trace_spherical_interface_bundle(
    n1: float,
    n2: float,
    radius: float,
    aperture: float,
    screen_z: float,
    ray_count: int = 13,
):
    radius = float(radius)
    screen_z = float(screen_z)
    ray_count = int(ray_count)
    ray_y = np.linspace(-abs(float(aperture)), abs(float(aperture)), ray_count)
    z0 = -max(2.0 * abs(radius), 20.0)
    center = np.array([radius, 0.0])
    pre_segments = np.zeros((ray_count, 4), dtype=float)
    post_segments = np.zeros((ray_count, 4), dtype=float)
    intersections = np.full((ray_count, 2), np.nan)
    directions = np.full((ray_count, 2), np.nan)
    incident_angle = np.full(ray_count, np.nan)
    tir_mask = np.zeros(ray_count, dtype=bool)
    rays = []
    for k, y0 in enumerate(ray_y):
        if abs(y0) >= abs(radius):
            continue
        z_surface = radius - np.sign(radius) * np.sqrt(max(radius**2 - y0**2, 0.0))
        point = np.array([z_surface, y0])
        normal_12 = -(point - center) / max(float(np.linalg.norm(point - center)), np.finfo(float).eps)
        incident = np.array([1.0, 0.0])
        incident_angle[k] = np.arccos(np.clip(-np.dot(normal_12, incident), -1.0, 1.0))
        outgoing, tir = _snell_refraction(incident, normal_12, n1, n2)
        tir_mask[k] = tir
        pre_segments[k] = [z0, y0, point[0], point[1]]
        if abs(outgoing[0]) <= np.finfo(float).eps:
            continue
        t_screen = (screen_z - point[0]) / outgoing[0]
        screen_point = point + t_screen * outgoing
        post_segments[k] = [point[0], point[1], screen_point[0], screen_point[1]]
        intersections[k] = point
        directions[k] = outgoing
        rays.append(np.array([[z0, y0], point, screen_point]))
    return {
        "rays": rays,
        "pre_segments": pre_segments,
        "post_segments": post_segments,
        "intersection": intersections,
        "directions": directions,
        "tir_mask": tir_mask,
        "incident_angle": incident_angle,
        "vertex": np.array([0.0, 0.0]),
        "screen_z": screen_z,
        "radius": radius,
    }
