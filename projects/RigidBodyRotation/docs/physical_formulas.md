# Rigid Body Rotation — formulas and interpretation

## What this project visualizes

This project visualizes attitude dynamics of a rigid body.  It supports torque-free rotation and fixed-point rotation under gravity.  Static previews show angular velocity components, phase trajectories, angular momentum, and body-axis paths.  Video export animates the orientation for single-case runs.

## Symbols

| Symbol | Meaning |
|---|---|
| \(I_1,I_2,I_3\) | principal moments of inertia |
| \(\boldsymbol\omega=(\omega_1,\omega_2,\omega_3)\) | angular velocity in the body frame |
| \(\mathbf L\) | angular momentum |
| \(T\) | rotational kinetic energy |
| \(R(t)\) | rotation matrix from body to lab |
| \(\boldsymbol\tau\) | external torque |
| \(\mathbf a\) | center-of-mass vector in body coordinates |

## Euler equations

In principal axes, angular momentum is
\[
\mathbf L=I\boldsymbol\omega
=\begin{bmatrix}I_1\omega_1\\I_2\omega_2\\I_3\omega_3\end{bmatrix}.
\]
Euler's equations are
\[
I_1\dot\omega_1=(I_2-I_3)\omega_2\omega_3+\tau_1,
\]
\[
I_2\dot\omega_2=(I_3-I_1)\omega_3\omega_1+\tau_2,
\]
\[
I_3\dot\omega_3=(I_1-I_2)\omega_1\omega_2+\tau_3.
\]
Torque-free motion sets \(\boldsymbol\tau=0\).

## Conservation laws for free rotation

For torque-free motion,
\[
T=\frac12(I_1\omega_1^2+I_2\omega_2^2+I_3\omega_3^2)
\]
is conserved, and
\[
|\mathbf L|^2=I_1^2\omega_1^2+I_2^2\omega_2^2+I_3^2\omega_3^2
\]
is conserved.  The intersection of the energy ellipsoid and angular-momentum ellipsoid explains the phase trajectories.  Rotation about the largest or smallest principal moment is stable, while rotation about the intermediate principal moment is unstable.

## Fixed-point body under gravity

For a body with one point fixed and center of mass at body vector \(\mathbf a\), the torque in lab coordinates is
\[
\boldsymbol\tau_\mathrm{lab}=m\,\mathbf r_\mathrm{cm}\times\mathbf g.
\]
With \(\mathbf r_\mathrm{cm}=R(t)\mathbf a\), this torque is transformed into the body frame before being used in Euler's equations.  Gravity breaks the torque-free conservation of \(\mathbf L\), but total mechanical energy is still the guiding invariant for ideal motion:
\[
E=T+mg\,z_\mathrm{cm}.
\]

## Attitude kinematics

The attitude matrix evolves as
\[
\dot R=R\,\widehat{\boldsymbol\omega},
\]
where \(\widehat{\boldsymbol\omega}\) is the skew-symmetric matrix representing cross product by \(\boldsymbol\omega\).  Quaternion or rotation-matrix integration avoids singularities associated with Euler angles.

## How to read the previews

- \( \omega(t) \) plots show how angular velocity components evolve.
- Phase plots show trajectories in component space.
- \( \mathbf L \) plots show angular-momentum geometry.
- Axis-tip plots show how body axes move in the lab frame.
- Comparison mode overlays several initial conditions to reveal sensitivity.

## Numerical notes

The ODE solver integrates angular velocity and attitude.  Long runs may accumulate small numerical drift in invariants, so plots should be interpreted qualitatively unless high tolerances are used.  Multi-IC comparison disables video export because a single animation would not represent one unique body orientation.
