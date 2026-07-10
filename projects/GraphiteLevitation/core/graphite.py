from __future__ import annotations

import numpy as np

from .params import GraphiteParams


def graphite_extent(params: GraphiteParams) -> float:
    return params.radius if params.shape == "circle" else np.sqrt(2) * params.side / 2


def graphite_area(params: GraphiteParams) -> float:
    return np.pi * params.radius**2 if params.shape == "circle" else params.side**2


def sample_mask(X, Y, params: GraphiteParams):
    if params.shape == "circle":
        return X * X + Y * Y <= params.radius**2
    phi = np.deg2rad(params.rotation_deg)
    Xl = np.cos(phi) * X + np.sin(phi) * Y
    Yl = -np.sin(phi) * X + np.cos(phi) * Y
    return (np.abs(Xl) <= params.side / 2) & (np.abs(Yl) <= params.side / 2)


def build_chi_image(params: GraphiteParams):
    e = graphite_extent(params) * 1.08
    x = np.linspace(-e, e, params.chi_grid_n)
    y = np.linspace(-e, e, params.chi_grid_n)
    X, Y = np.meshgrid(x, y)
    mask = sample_mask(X, Y, params)
    weight = np.ones_like(X)
    if params.laser_enabled:
        sigma = max(params.spot_diameter / 2.355, 1e-9)
        g = np.exp(-((X - params.spot_x) ** 2 + (Y - params.spot_y) ** 2) / (2 * sigma * sigma))
        weight = np.maximum(0.02, 1 - params.laser_alpha * g)
    weight[~mask] = np.nan
    return x, y, weight


def chi_kernel(params: GraphiteParams, dx: float, dy: float):
    e = graphite_extent(params) * 1.08
    x = np.arange(-e, e + dx, dx)
    y = np.arange(-e, e + dy, dy)
    X, Y = np.meshgrid(x, y)
    mask = sample_mask(X, Y, params)
    weight = np.ones_like(X)
    if params.laser_enabled:
        sigma = max(params.spot_diameter / 2.355, 1e-9)
        weight *= np.maximum(0.02, 1 - params.laser_alpha * np.exp(-((X - params.spot_x) ** 2 + (Y - params.spot_y) ** 2) / (2 * sigma * sigma)))
    weight[~mask] = 0
    return weight, mask
