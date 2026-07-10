# Special Functions Studio — formulas and interpretation

## What this project visualizes

This project plots special functions that appear in separation of variables, wave propagation, quantum mechanics, diffusion, probability, and approximation theory.  The GUI selects a family, a variant, parameter tuples, and a display mode.  Outputs may be 1D curves, 3D surfaces, or vector-field-style visualizations.

## Symbols

| Symbol | Meaning |
|---|---|
| \(x\) | scalar argument |
| \(n,\ell,m,\nu\) | order or degree parameters |
| \(J_\nu,Y_\nu\) | Bessel functions |
| \(P_\ell\) | Legendre polynomial |
| \(Y_\ell^m\) | spherical harmonic |
| \(H_n\) | Hermite polynomial |
| \(L_n^\alpha\) | generalized Laguerre polynomial |

## Bessel functions

Bessel functions solve
\[
x^2y''+xy'+(x^2-\nu^2)y=0.
\]
The first-kind function \(J_\nu(x)\) is finite at the origin for nonnegative integer \(\nu\), while \(Y_\nu(x)\) is singular.  They occur in cylindrical waveguides, circular membranes, scattering, and radial diffusion.  Zeros of \(J_\nu\) or \(J_\nu'\) set many boundary-condition eigenvalues.

## Legendre functions and spherical harmonics

Legendre polynomials solve
\[
\frac{d}{dx}\left[(1-x^2)\frac{dP_\ell}{dx}\right]+\ell(\ell+1)P_\ell=0.
\]
Associated Legendre functions extend this to azimuthal order \(m\).  Spherical harmonics are
\[
Y_\ell^m(\theta,\phi)=N_{\ell m}P_\ell^m(\cos\theta)e^{im\phi},
\]
and form an orthonormal basis on the sphere:
\[
\int_0^{2\pi}\int_0^\pi
Y_\ell^m(\theta,\phi)^*Y_{\ell'}^{m'}(\theta,\phi)
\sin\theta\,d\theta\,d\phi
=\delta_{\ell\ell'}\delta_{mm'}.
\]

## Hermite functions

Hermite polynomials satisfy
\[
H_n''(x)-2xH_n'(x)+2nH_n(x)=0.
\]
They are central in the quantum harmonic oscillator.  The normalized Hermite functions are
\[
\psi_n(x)=
\frac{1}{\sqrt{2^n n!\sqrt{\pi}}}H_n(x)e^{-x^2/2}.
\]

## Laguerre functions

Generalized Laguerre polynomials satisfy
\[
xy''+(\alpha+1-x)y'+ny=0.
\]
They appear in radial hydrogenic wavefunctions, paraxial optical modes, and weighted approximation problems.  Their weight on \([0,\infty)\) is
\[
w(x)=x^\alpha e^{-x}.
\]

## Orthogonality and zeros

Many families are useful because of orthogonality:
\[
\int_a^b w(x)y_m(x)y_n(x)\,dx=0,\qquad m\ne n.
\]
Zeros of special functions often define modal frequencies or quadrature nodes.  For example, circular membrane modes use zeros of Bessel functions, while spherical problems use \(\ell,m\) angular indices.

## How the previews are generated

The tab builds a result structure describing curves or surfaces, then passes it to the shared renderer.  For 1D plots the x-range and legend controls determine the displayed curves.  For 3D plots the selected preview list and layout field determine the exported composite.  Filenames describe the function family/variant and image order; parameter tuples are recorded in `parameters.txt`.

## MATLAB parity families

The Python core includes the MATLAB result families used by the original tab: Bessel \(J,Y,I,K\), spherical Bessel \(j_n,y_n\), Airy \(Ai,Bi\) and derivatives, complete/incomplete elliptic integrals, Jacobi elliptic functions, Gauss \({}_2F_1\), Lane-Emden curves, scalar spherical harmonics, and the three vector spherical harmonic views \(X_{\ell m}\), \(\Psi_{\ell m}\), and \(\hat rY_{\ell m}\).  Lane-Emden integration follows the MATLAB event rule and terminates at the first zero.  The hypergeometric branch uses the same power-series recurrence in the visualization interval.

Vector spherical harmonic previews are constructed from the spherical surface gradient:
\[
\Psi_{\ell m}=\nabla_S Y_{\ell m},\qquad
X_{\ell m}=\hat r\times\nabla_S Y_{\ell m},\qquad
R_{\ell m}=\hat rY_{\ell m}.
\]
The plotted surface is a compact visual embedding of those vector components rather than a certified vector-field quadrature.

## Numerical notes

Special functions can grow, oscillate, or become singular.  Automatic cropping is used to keep curves readable, but manual y-ranges are useful when comparing orders.  Very high orders may require specialized asymptotic methods for high precision; the GUI is intended for visualization and teaching rather than certified numerical analysis.
