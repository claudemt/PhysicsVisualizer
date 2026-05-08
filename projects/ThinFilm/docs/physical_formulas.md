# Thin Film Elastic Waves — formulas and interpretation

## What this project visualizes

This project computes a text report for elastic waves interacting with a layered film stack.  The input describes an incident wave, boundary media, and optional film layers.  The output reports transfer-matrix quantities and reflection/transmission behavior for coupled P/SV elastic potentials.

## Symbols

| Symbol | Meaning |
|---|---|
| \(\lambda,\mu\) | Lamé elastic parameters |
| \(\eta\) or \(\rho\) | density-like material parameter used by the model |
| \(h\) | layer thickness |
| \(\omega\) | angular frequency |
| \(k_x\) | in-plane wave number |
| \(\phi,\psi\) | P and SV wave potentials |
| \(c_L,c_T\) | longitudinal and transverse bulk speeds |

## Elastic potentials

For 2D P/SV motion, displacement can be represented using scalar potentials:
\[
u_x=\frac{\partial\phi}{\partial x}+\frac{\partial\psi}{\partial z},
\qquad
u_z=\frac{\partial\phi}{\partial z}-\frac{\partial\psi}{\partial x}.
\]
The P potential \(\phi\) and SV potential \(\psi\) satisfy wave equations with speeds
\[
c_L=\sqrt{\frac{\lambda+2\mu}{\rho}},
\qquad
c_T=\sqrt{\frac{\mu}{\rho}}.
\]

## Layer wave numbers

For a harmonic dependence \(e^{i(k_xx-\omega t)}\), vertical wave numbers are
\[
p^2=\frac{\omega^2}{c_L^2}-k_x^2,
\qquad
q^2=\frac{\omega^2}{c_T^2}-k_x^2.
\]
Real \(p,q\) correspond to propagating vertical components; imaginary values correspond to evanescent decay.

## Boundary conditions

At each interface, displacement and traction must be continuous:
\[
u_x^{(1)}=u_x^{(2)},\qquad u_z^{(1)}=u_z^{(2)},
\]
\[
\sigma_{xz}^{(1)}=\sigma_{xz}^{(2)},\qquad
\sigma_{zz}^{(1)}=\sigma_{zz}^{(2)}.
\]
These four conditions couple P and SV components and produce the transfer matrix across each layer.

## Transfer-matrix idea

A state vector can be written schematically as
\[
\mathbf s(z)=
\begin{bmatrix}
u_x\\u_z\\\sigma_{xz}\\\sigma_{zz}
\end{bmatrix}.
\]
For a homogeneous layer,
\[
\mathbf s(z+h)=T(h)\mathbf s(z).
\]
A stack multiplies layer matrices:
\[
T_\mathrm{stack}=T_NT_{N-1}\cdots T_1.
\]
Reflection and transmission are obtained by matching the incident, reflected, and transmitted wave amplitudes to the stack boundary state.

## Relation to Lamb waves

For a free plate, symmetric and antisymmetric Lamb-wave dispersion is often written with
\[
p^2=\frac{\omega^2}{c_L^2}-k^2,\qquad
q^2=\frac{\omega^2}{c_T^2}-k^2.
\]
Representative Rayleigh--Lamb equations are
\[
\frac{\tan(qh)}{\tan(ph)}
=-\frac{4k^2pq}{(q^2-k^2)^2}
\]
and
\[
\frac{\tan(qh)}{\tan(ph)}
=-\frac{(q^2-k^2)^2}{4k^2pq},
\]
depending on symmetry convention.  The layered transfer-matrix model generalizes the same boundary-matching idea to multiple layers and surrounding media.

## How to read the report

The report is text because the output is primarily algebraic/numerical: material states, interface matrices, and resulting amplitudes.  Parameters are stored in `parameters.txt` on export.  A blank film-layer table means the boundary media interact without inserted layers.
