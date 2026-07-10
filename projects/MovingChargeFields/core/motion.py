from __future__ import annotations

import numpy as np


def motion_state(t, motion: str, a: float, omega: float):
    t = np.asarray(t)
    if str(motion).lower().startswith("circ"):
        rx = a * np.cos(omega * t)
        ry = a * np.sin(omega * t)
        rz = np.zeros_like(t)
        vx = -a * omega * np.sin(omega * t)
        vy = a * omega * np.cos(omega * t)
        vz = np.zeros_like(t)
        ax = -a * omega**2 * np.cos(omega * t)
        ay = -a * omega**2 * np.sin(omega * t)
        az = np.zeros_like(t)
    else:
        rx = np.zeros_like(t)
        ry = np.zeros_like(t)
        rz = a * np.cos(omega * t)
        vx = np.zeros_like(t)
        vy = np.zeros_like(t)
        vz = -a * omega * np.sin(omega * t)
        ax = np.zeros_like(t)
        ay = np.zeros_like(t)
        az = -a * omega**2 * np.cos(omega * t)
    return rx, ry, rz, vx, vy, vz, ax, ay, az
