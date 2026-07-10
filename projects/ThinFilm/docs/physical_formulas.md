# ThinFilm transfer-matrix models — formulas and interpretation

## What this project computes

The ThinFilm project contains two related solvers that use the same transfer-matrix workflow:

1. **Elastic waves** in layered isotropic solids, with coupled in-plane P/SV motion and an independent SH channel.
2. **Optical waves** in layered dielectric or magnetic media, with independent s and p polarizations.

Both solvers treat a stack between an incident half-space **a** and a substrate half-space **g**.  The in-plane wave number is fixed by the incident field, each layer contributes a matrix that propagates the substrate-side state back to the incident-side state, and the total stack matrix is matched to reflected and transmitted waves at the two outer half-spaces.

---

## Shared notation and transfer-matrix pattern

| Symbol | Meaning |
|---|---|
| a | incident half-space |
| g | substrate / exit half-space |
| m | layer index, counted from a to g |
| N | number of inserted layers |
| h_m | thickness of layer m |
| \(\omega\) | angular frequency |
| \(k_x\) | in-plane wave number, common to all media |
| \(\theta\) | propagation angle measured from the layer normal |
| \(\varphi_m\) | vertical phase accumulated across layer m |
| \(M_m\) | transfer matrix of layer m |
| \(M\) | product of all layer matrices |

The assumed harmonic dependence is
\[
\exp\{i(k_x x-\omega t)\}.
\]
For a homogeneous layer, the solver builds a state vector \(\mathbf{s}\) from tangential field quantities.  With \(z_m\) at the top of layer m and \(z_m+h_m\) at its bottom, the implemented matrices satisfy
\[
\mathbf{s}(z_m)=M_m\,\mathbf{s}(z_m+h_m).
\]
For a stack ordered from the incident side to the substrate side,
\[
M=M_1M_2\cdots M_N,
\qquad
\mathbf{s}_a=M\,\mathbf{s}_g.
\]
The amplitudes of the incident, reflected, and transmitted waves are then obtained by matching the state on side **a** to the state propagated back from side **g**.

The reported power quantities \(R\) and \(T\) are flux-normalized versions of the complex amplitude coefficients \(r\) and \(t\).  For lossless media with propagating incident and transmitted waves, the corresponding energy sums should be close to one.  With evanescent waves, complex material parameters, or lossy media, the same algebra is still useful, but the energy-sum line should be interpreted as a diagnostic rather than a strict conservation law.

The Python core also exposes the MATLAB facade workflows for optical stacks: resolving `coeff*lambda` thickness strings, applying quarter-wave thicknesses, constructing alternating high/low quarter-wave stacks, sweeping incidence angle, and sweeping a selected layer thickness.  Text reports include the total transfer matrices (`P`, `Q`, `Ptot`, `Psh`) so saved results can be compared against MATLAB report bundles beyond scalar energy sums.

---

## Elastic-wave tab

### Model and material parameters

The elastic tab models isotropic linear elastic media.  Each medium is defined by
\[
(\lambda,\mu,\eta),
\]
where \(\lambda\) and \(\mu\) are Lamé parameters and \(\eta\) is the density-like parameter used by the code.  The bulk P and S speeds are
\[
c_P=\sqrt{\frac{\lambda+2\mu}{\eta}},
\qquad
c_S=\sqrt{\frac{\mu}{\eta}},
\]
and the corresponding wave numbers are
\[
k_P=\frac{\omega}{c_P}=\omega\sqrt{\frac{\eta}{\lambda+2\mu}},
\qquad
k_S=\frac{\omega}{c_S}=\omega\sqrt{\frac{\eta}{\mu}}.
\]
The common in-plane wave number sets the P and S angles through
\[
k_x=k_P\sin\theta_P=k_S
