from __future__ import annotations

import numpy as np


def normalize_quat(q):
    q = np.asarray(q, dtype=float)
    return q / max(np.linalg.norm(q), 1e-15)


def normalize_quat_array(q):
    q = np.asarray(q, dtype=float)
    n = np.linalg.norm(q, axis=1)
    n[n == 0] = 1
    return q / n[:, None]


def omega_matrix(w):
    w1, w2, w3 = w
    return np.array([
        [0, -w1, -w2, -w3],
        [w1, 0, w3, -w2],
        [w2, -w3, 0, w1],
        [w3, w2, -w1, 0],
    ], dtype=float)


def axis_angle(axis, angle):
    axis = np.asarray(axis, dtype=float)
    axis = axis / max(np.linalg.norm(axis), 1e-15)
    x, y, z = axis
    c = np.cos(angle)
    s = np.sin(angle)
    C = 1 - c
    return np.array([
        [c + x * x * C, x * y * C - z * s, x * z * C + y * s],
        [y * x * C + z * s, c + y * y * C, y * z * C - x * s],
        [z * x * C - y * s, z * y * C + x * s, c + z * z * C],
    ])


def rotation_map(a, b):
    a = np.asarray(a, dtype=float)
    b = np.asarray(b, dtype=float)
    a = a / max(np.linalg.norm(a), 1e-15)
    b = b / max(np.linalg.norm(b), 1e-15)
    v = np.cross(a, b)
    s = np.linalg.norm(v)
    c = np.dot(a, b)
    if s < 1e-12:
        if c > 0:
            return np.eye(3)
        axis = np.array([1.0, 0.0, 0.0])
        if abs(a[0]) > 0.8:
            axis = np.array([0.0, 1.0, 0.0])
        return axis_angle(np.cross(a, axis), np.pi)
    vx = np.array([[0, -v[2], v[1]], [v[2], 0, -v[0]], [-v[1], v[0], 0]])
    return np.eye(3) + vx + vx @ vx * ((1 - c) / (s * s))


def rotm_to_quat(R):
    R = np.asarray(R, dtype=float)
    tr = np.trace(R)
    if tr > 0:
        s = np.sqrt(tr + 1.0) * 2
        q = np.array([0.25 * s, (R[2, 1] - R[1, 2]) / s, (R[0, 2] - R[2, 0]) / s, (R[1, 0] - R[0, 1]) / s])
    else:
        idx = int(np.argmax(np.diag(R)))
        if idx == 0:
            s = np.sqrt(1 + R[0, 0] - R[1, 1] - R[2, 2]) * 2
            q = np.array([(R[2, 1] - R[1, 2]) / s, 0.25 * s, (R[0, 1] + R[1, 0]) / s, (R[0, 2] + R[2, 0]) / s])
        elif idx == 1:
            s = np.sqrt(1 + R[1, 1] - R[0, 0] - R[2, 2]) * 2
            q = np.array([(R[0, 2] - R[2, 0]) / s, (R[0, 1] + R[1, 0]) / s, 0.25 * s, (R[1, 2] + R[2, 1]) / s])
        else:
            s = np.sqrt(1 + R[2, 2] - R[0, 0] - R[1, 1]) * 2
            q = np.array([(R[1, 0] - R[0, 1]) / s, (R[0, 2] + R[2, 0]) / s, (R[1, 2] + R[2, 1]) / s, 0.25 * s])
    return normalize_quat(q)


def quat_to_rotm(q):
    q0, q1, q2, q3 = normalize_quat(q)
    return np.array([
        [1 - 2 * (q2 * q2 + q3 * q3), 2 * (q1 * q2 - q0 * q3), 2 * (q1 * q3 + q0 * q2)],
        [2 * (q1 * q2 + q0 * q3), 1 - 2 * (q1 * q1 + q3 * q3), 2 * (q2 * q3 - q0 * q1)],
        [2 * (q1 * q3 - q0 * q2), 2 * (q2 * q3 + q0 * q1), 1 - 2 * (q1 * q1 + q2 * q2)],
    ])


def euler313_to_quat(euler):
    phi, theta, psi = np.asarray(euler, dtype=float)
    R = axis_angle([0, 0, 1], phi) @ axis_angle([1, 0, 0], theta) @ axis_angle([0, 0, 1], psi)
    return rotm_to_quat(R)
