# Mie Scattering — formulas and interpretation

## What this project visualizes

This project visualizes electromagnetic scattering by spheres and related cylindrical setups.  It compares scattered fields, total fields, angular structure, and selected field components as size, material constants, and polarization change.  The central mathematical idea is expansion of electromagnetic fields in separable basis functions.

## Symbols

| Symbol | Meaning |
|---|---|
| \(a\) or \(R\) | particle radius |
| \(\lambda\) | wavelength in the surrounding medium |
| \(x=2\pi a/\lambda\) | size parameter |
| \(m=n_\mathrm{particle}/n_\mathrm{medium}\) | relative refractive index |
| \(a_n,b_n\) | electric and magnetic Mie coefficients |
| \(\theta\) | scattering angle |
| \(\epsilon_r,\mu_r\) | relative permittivity and permeability |

## Size parameter

The size parameter
\[
x=\frac{2\pi a}{\lambda}
\]
controls the scattering regime.  When \(x\ll1\), Rayleigh-like dipole scattering dominates.  When \(x\sim1\), resonances and multipoles become important.  When \(x\gg1\), geometric-optics intuition becomes more relevant but interference remains visible.

## Riccati--Bessel functions

The spherical Mie coefficients are written using Riccati--Bessel functions
\[
\psi_n(z)=zj_n(z),\qquad \xi_n(z)=zh_n^{(1)}(z),
\]
where \(j_n\) is a spherical Bessel function and \(h_n^{(1)}\) is a spherical Hankel function.

For a sphere, one standard form of the coefficients is
\[
a_n=
\frac{m\psi_n(mx)\psi_n'(x)-\psi_n(x)\psi_n'(mx)}
{m\psi_n(mx)\xi_n'(x)-\xi_n(x)\psi_n'(mx)},
\]
\[
b_n=
\frac{\psi_n(mx)\psi_n'(x)-m\psi_n(x)\psi_n'(mx)}
{\psi_n(mx)\xi_n'(x)-m\xi_n(x)\psi_n'(mx)}.
\]
The \(a_n\) sequence corresponds to electric multipoles and \(b_n\) to magnetic multipoles.

## Scattering amplitudes and intensity

Angular scattering can be described through amplitude functions \(S_1(\theta)\) and \(S_2(\theta)\).  A schematic intensity is
\[
I(\theta)\propto |S_1(\theta)|^2+|S_2(\theta)|^2.
\]
Polarization settings change how these amplitudes combine in the displayed field components.

## Near fields

The near-field plots evaluate components of the total, incident, or scattered field on a spatial grid.  Depending on the selected view mode, the preview may include components such as
\[
E_x,\ E_y,\ E_z,\ |E|,\ H_x,\ H_y,\ H_z,\ |H|.
\]
Signed components use a diverging/symmetric color scale; magnitudes use a positive scale.

## Cylinder option

For cylindrical scattering, the separable basis changes from spherical harmonics to cylindrical Bessel/Hankel functions.  The conceptual role of boundary matching is the same: tangential electric and magnetic fields are continuous at the material boundary, producing coefficient sequences for each angular order.

## Numerical notes

The expansion must be truncated.  A common rule is to include terms up to roughly
\[
n_\mathrm{max}\approx x+4x^{1/3}+2,
\]
with extra margin for high contrast or complex materials.  Very small denominators in the coefficient formulas indicate resonant behavior and can amplify numerical error.  The GUI writes parameter values to `parameters.txt`; filenames therefore describe the field category rather than repeating all material parameters.
