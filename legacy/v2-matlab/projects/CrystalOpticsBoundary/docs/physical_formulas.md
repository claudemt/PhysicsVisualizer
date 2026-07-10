# Crystal Boundary Optics — formulas and interpretation

## What this project visualizes

This project studies reflection, transmission, and polarization at an interface between an incident isotropic medium and an anisotropic crystal.  The output is a text report rather than an image bundle because the important result is the set of physically admissible transmitted/reflected waves, their polarizations, and their energy-flow directions.

## Symbols

| Symbol | Meaning |
|---|---|
| \(\mathbf k_i\) | incident wave vector |
| \(n_i\) | incident refractive index |
| \(\mathbf E\) | electric-field polarization |
| \(\mathbf H\) | magnetic field |
| \(\boldsymbol\varepsilon\) | dielectric tensor |
| \(\omega\) | angular frequency |
| \(\mathbf S\) | Poynting vector |
| \(\hat{\mathbf n}\) | interface normal |

## Boundary wave-vector matching

For a flat interface, phase continuity requires the tangential component of the wave vector to match across the interface:
\[
\mathbf k_{t,\parallel}=\mathbf k_{i,\parallel}.
\]
In isotropic media this reduces to Snell's law,
\[
n_i\sin\theta_i=n_t\sin\theta_t.
\]
In an anisotropic crystal, however, the normal component of \(\mathbf k_t\) must be found by solving the crystal dispersion relation, not by a single scalar refractive index.

## Dielectric tensor and orientation

In the crystal principal frame,
\[
\boldsymbol\varepsilon_\mathrm{principal}
=\begin{bmatrix}
\varepsilon_1&0&0\\
0&\varepsilon_2&0\\
0&0&\varepsilon_3
\end{bmatrix}.
\]
If the crystal is rotated by \(R\), the lab-frame tensor is
\[
\boldsymbol\varepsilon_\mathrm{lab}
=R\boldsymbol\varepsilon_\mathrm{principal}R^T.
\]
The GUI supports direct tensor input or principal values plus orientation.  The orientation controls change the physical relation between the interface normal, optic axis, and incident plane.

## Anisotropic wave equation

For a plane wave in a nonmagnetic anisotropic medium,
\[
\mathbf E(\mathbf r,t)=\mathbf E_0 e^{i(\mathbf k\cdot\mathbf r-\omega t)}.
\]
Maxwell's equations lead to
\[
\mathbf k\times(\mathbf k\times\mathbf E_0)
+k_0^2\boldsymbol\varepsilon\,\mathbf E_0=0,
\]
where \(k_0=\omega/c\).  Nontrivial solutions require the determinant of this system to vanish.  This produces the allowed crystal modes for the given tangential wave-vector component.

## Polarization and energy flow

In anisotropic media the wave normal and energy flow need not point in the same direction.  The time-averaged Poynting vector is
\[
\mathbf S=\frac12\Re(\mathbf E\times\mathbf H^*).
\]
The report distinguishes phase propagation from energy propagation.  This is why ordinary and extraordinary waves can appear with different directions and polarization properties.

## Boundary conditions for fields

At an interface with no free surface charge or current,
\[
\mathbf E_{\parallel}^{(1)}=\mathbf E_{\parallel}^{(2)},\qquad
\mathbf H_{\parallel}^{(1)}=\mathbf H_{\parallel}^{(2)}.
\]
The solver uses these continuity conditions to determine reflection/transmission amplitudes after finding the allowed wave branches.

## How to read the report

The report lists the incident setup, tensor/orientation information, computed wave branches, polarization information, and amplitude coefficients.  Sweeping polarization or orientation is useful for identifying cases where ordinary/extraordinary splitting is strong.  Complex dielectric entries model absorption; in that case transmitted amplitudes and energy-flow interpretation should be read with attenuation in mind.

## Numerical notes

The most delicate step is solving for the normal component of the transmitted wave vector.  Multiple roots can appear, and physical selection must reject waves that transport energy away from the interface in the wrong direction.  The GUI controls are intentionally compact; detailed tensor and wave-equation explanations live here so the tab stays readable.
