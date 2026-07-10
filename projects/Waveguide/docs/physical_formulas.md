# Waveguide Studio — formulas and interpretation

## What this project visualizes

This project compares metallic and dielectric waveguides: rectangular, circular, and annular PEC guides, planar dielectric slabs, and cylindrical dielectric fibers. Outputs show field profiles, dispersion, cutoff behavior, and mode existence.

## Symbols

| Symbol | Meaning |
|---|---|
| \(a,b\) | rectangular guide dimensions |
| \(R_i,R_o\) | inner and outer annular-guide radii |
| \(R\) | circular-guide or fiber radius |
| \(k_0=\omega/c\) | free-space wavenumber |
| \(k_c\) | cutoff wavenumber |
| \(\beta\) | propagation constant |
| \(n_1,n_2\) | core and cladding refractive indices |
| \(m,n\) | mode indices |
| \(J_m,K_m\) | Bessel and modified Bessel functions |

## Rectangular metallic waveguides

For a rectangular PEC guide with dimensions \(a\times b\), the cutoff wavenumber is
\[
k_c^2=\left(\frac{m\pi}{a}\right)^2+\left(\frac{n\pi}{b}\right)^2.
\]
The propagation constant is
\[
\beta=\sqrt{k_0^2-k_c^2}.
\]
A mode propagates when \(k_0>k_c\); below cutoff, \(\beta\) is imaginary and the field decays.

The cutoff frequency is
\[
f_c=\frac{c}{2}
\sqrt{\left(\frac{m}{a}\right)^2+\left(\frac{n}{b}\right)^2}.
\]
TE modes allow one index to be zero, but TM modes require both indices nonzero.

## Circular metallic waveguides

Circular PEC guides use Bessel functions.  Cutoff is determined by zeros of \(J_m\) or its derivative:
\[
k_c=\frac{x_{mn}}{R}
\quad\text{(TM)},\qquad
k_c=\frac{x'_{mn}}{R}
\quad\text{(TE)}.
\]
The angular part contributes \(\cos(m\phi)\) or \(\sin(m\phi)\), producing lobed field patterns.

## Annular metallic waveguides and TEM

Let \(\xi_0=R_i/R_o\) and \(x=k_cR_o\). Unlike a circular guide, an annular guide must satisfy the PEC condition at both radii. The TM roots obey
\[
J_m(\xi_0x)Y_m(x)-Y_m(\xi_0x)J_m(x)=0,
\]
and the TE roots obey
\[
J_m'(\xi_0x)Y_m'(x)-Y_m'(\xi_0x)J_m'(x)=0.
\]
The corresponding longitudinal field is the matching \(J_m+Y_m\) combination, not a circular-guide field with its center hidden.

Because the annulus has two conductors, it also supports a TEM mode:
\[
f_c=0,\qquad \beta=k_0,\qquad E_r\propto\frac{1}{r},\qquad H_\phi=\frac{E_r}{Z_0}.
\]
TEM is therefore exposed only by the annular/coaxial workflow.

## Planar dielectric slab

A symmetric slab waveguide has a high-index core and lower-index cladding.  Guided modes satisfy
\[
n_2k_0<\beta<n_1k_0.
\]
Define transverse quantities
\[
u^2=n_1^2k_0^2-\beta^2,\qquad
w^2=\beta^2-n_2^2k_0^2.
\]
For a slab half-thickness \(d\), TE mode equations can be written schematically as
\[
u\tan(ud)=w
\]
for even modes and
\[
-u\cot(ud)=w
\]
for odd modes.  TM modes have analogous equations with permittivity weighting.

## Cylindrical dielectric fiber

For a step-index fiber, the normalized frequency is
\[
V=k_0a\sqrt{n_1^2-n_2^2}.
\]
The transverse parameters satisfy
\[
u^2+w^2=V^2.
\]
The cylindrical-dielectric dispersion preview uses the same characteristic equation as the MATLAB contour workflow.  With
\[
\eta=\left(\frac{n_2}{n_1}\right)^2,
\]
define
\[
F=\frac{J_m'(u)}{uJ_m(u)},\qquad
G=\frac{K_m'(w)}{wK_m(w)}.
\]
For \(m=0\), TE and TM modes are separate factors:
\[
F+G=0\quad(\mathrm{TE}_{0n}),\qquad
F+\eta G=0\quad(\mathrm{TM}_{0n}).
\]
For \(m>0\), the vector characteristic equation is
\[
(F+G)(F+\eta G)
=m^2
\left(\frac{1}{u^2}+\frac{1}{w^2}\right)
\left(\frac{1}{u^2}+\frac{\eta}{w^2}\right).
\]
For \(m>0\), each root is classified as HE or EH from the null vector of the tangential-field boundary matrix. The mode-field workflow fixes \(V\), locates the requested family root in \(0<u<V\), and reconstructs all six cylindrical components
\[
(E_r,E_\phi,E_z,H_r,H_\phi,H_z).
\]
The longitudinal profiles are oscillatory in the core and evanescent in the cladding:
\[
E_\mathrm{core}\sim J_m(ur/a),\qquad
E_\mathrm{clad}\sim K_m(wr/a).
\]
Core and cladding amplitudes satisfy continuity of \(E_z,H_z,E_\phi,H_\phi\) at \(r=a\); transverse components then follow directly from Maxwell's curl equations. The effective index follows
\[
b=\frac{w^2}{V^2},\qquad
n_\mathrm{eff}^2=n_2^2+b(n_1^2-n_2^2).
\]

## Dispersion and group behavior

For any mode,
\[
\beta(\omega)
\]
determines phase and group velocities:
\[
v_p=\frac{\omega}{\beta},\qquad
v_g=\frac{d\omega}{d\beta}.
\]
Near cutoff, dispersion is strong; far above cutoff, propagation becomes less sensitive to frequency.

## How the previews are generated

The core solvers compute mode constants and field samples.  The app then renders selected plots into the shared preview list.  Exported images use semantic names such as field profile, dispersion, or cutoff plot, while exact guide dimensions and material parameters are saved to `parameters.txt`.

## Numerical notes

Root finding is the most important numerical step for dielectric guides and circular Bessel modes.  Roots can be missed if the search grid is too coarse, especially near cutoff or near degeneracies.  Field plots are normalized for visualization; absolute power normalization is a separate calculation.
