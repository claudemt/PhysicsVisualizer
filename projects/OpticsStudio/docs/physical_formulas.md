# Unified Optics Studio — formulas and interpretation

## What this project visualizes

This project combines scalar wave optics, Fourier optics, imaging, interference, ray optics, and tomography.  The GUI controls are intentionally compact; this document explains the formulas behind the preview panels.  Across modules, complex scalar fields are represented as
\[
U(x,y)=A(x,y)e^{i\phi(x,y)}
\]
and intensity is
\[
I(x,y)=|U(x,y)|^2.
\]

## Shared display conventions

Many panels show normalized quantities so structure is visible even when absolute units vary.  **Fixed scaling** keeps a prescribed color range for comparability.  **Auto scaling** stretches each panel independently, which is useful for detecting structure but less useful for quantitative comparison.

## Fourier studio and 4f systems

A thin lens performs a Fourier transform relationship between its front and back focal planes.  In a simplified scalar 4f system,
\[
U_f(f_x,f_y)=\mathcal F\{U_0(x,y)\},
\]
\[
U_\mathrm{out}(x,y)=\mathcal F^{-1}\{H(f_x,f_y)U_f(f_x,f_y)\}.
\]
Here \(H(f_x,f_y)\) is the Fourier-plane filter.  The GUI's object plane, phase plane, spectrum, filter, and output panels are stages of this pipeline.

A phase mask applies
\[
U(x,y)\mapsto U(x,y)e^{i\Phi(x,y)}.
\]
A vortex phase plate uses a phase of the form
\[
\Phi(\theta)=\ell\theta,
\]
where \(\ell\) is the topological charge.  Zernike-like aberrations alter the phase over a finite pupil.

## Free-space scalar propagation

The Fresnel propagation integral over distance \(z\) is
\[
U(x,y;z)=
\frac{e^{ikz}}{i\lambda z}
\iint U_0(x',y')
\exp\left[
\frac{ik}{2z}\big((x-x')^2+(y-y')^2\big)
\right]dx'dy'.
\]
The angular-spectrum method writes the same idea in frequency space:
\[
U(x,y;z)=
\mathcal F^{-1}\left\{
\mathcal F\{U_0\}
\exp\left[i z\sqrt{k^2-k_x^2-k_y^2}\right]
\right\}.
\]
The Fraunhofer limit is the far-field approximation where the observed intensity is proportional to the squared magnitude of a Fourier transform.

## Imaging: pupil, PSF, and OTF

A coherent pupil function can be written
\[
P(\rho,\theta)=A(\rho,\theta)e^{i\Phi(\rho,\theta)}.
\]
The point-spread function is related to the Fourier transform of the pupil:
\[
h(x,y)=\mathcal F\{P\},
\qquad
\mathrm{PSF}(x,y)=|h(x,y)|^2.
\]
The optical transfer function is the Fourier transform of the incoherent PSF:
\[
\mathrm{OTF}(f_x,f_y)=\mathcal F\{\mathrm{PSF}(x,y)\}.
\]
Aberration coefficients in waves modify the pupil phase by \(2\pi\) times the specified wave error.

For confocal imaging, the effective PSF is often approximated as a product of illumination and detection responses:
\[
\mathrm{PSF}_\mathrm{confocal}\approx \mathrm{PSF}_\mathrm{illum}\,\mathrm{PSF}_\mathrm{detect}.
\]
A pinhole parameter controls how much of the detection PSF contributes.  STED-style depletion can be modeled as a saturation factor such as
\[
I_\mathrm{eff}(r)=I_\mathrm{exc}(r)\exp[-\alpha I_\mathrm{dep}(r)].
\]

## Interference and coherence

For two scalar fields,
\[
U=U_1+U_2,
\]
the intensity is
\[
I=|U_1|^2+|U_2|^2+2\Re(U_1U_2^*).
\]
If the two waves have phase difference \(\Delta\phi\), equal amplitudes give
\[
I=2I_0(1+\cos\Delta\phi).
\]
Optical path difference connects phase and geometry:
\[
\Delta\phi=\frac{2\pi}{\lambda}\Delta L.
\]
Moire patterns arise when two fringe frequencies are close:
\[
\cos(k_1x)+\cos(k_2x)
=2\cos\left(\frac{k_1-k_2}{2}x\right)
\cos\left(\frac{k_1+k_2}{2}x\right).
\]

A Fabry--Perot-like response contains repeated reflections:
\[
T=\frac{1}{1+F\sin^2(\delta/2)}.
\]

## Ray optics and ABCD matrices

Paraxial rays are represented by height and angle:
\[
\mathbf r=\begin{bmatrix}y\\\theta\end{bmatrix}.
\]
Propagation over distance \(d\) is
\[
\begin{bmatrix}1&d\\0&1\end{bmatrix},
\]
and a thin lens of focal length \(f\) is
\[
\begin{bmatrix}1&0\\-1/f&1\end{bmatrix}.
\]
The thin-lens imaging equation is
\[
\frac{1}{s}+\frac{1}{s'}=\frac{1}{f}.
\]
For a periodic optical system, stability is often expressed through an ABCD matrix \(M\):
\[
\left|\frac{\operatorname{tr}M}{2}\right|<1.
\]

## Tomography

The Radon transform of an object \(f(x,y)\) is
\[
p_\theta(s)=\iint f(x,y)\delta(s-x\cos\theta-y\sin\theta)\,dx\,dy.
\]
The Fourier-slice theorem states that the 1D Fourier transform of a projection equals a slice through the 2D Fourier transform of the object:
\[
\mathcal F_s\{p_\theta(s)\}(\omega)
=F(\omega\cos\theta,\omega\sin\theta).
\]
Filtered backprojection reconstructs
\[
f(x,y)=\int_0^\pi
\left[p_\theta * h\right](x\cos\theta+y\sin\theta)\,d\theta,
\]
where \(h\) is a ramp-like reconstruction filter.  Windowed filters trade spatial resolution for reduced ringing/noise.

## Numerical notes

FFT-based optics assumes finite sampling windows.  Aliasing can appear if the field expands beyond the computational window or if phase varies faster than the grid can resolve.  Tomography quality depends on angular sampling and filter choice.  The shared export tools keep panel naming semantic; detailed parameter values are stored in `parameters.txt`.
