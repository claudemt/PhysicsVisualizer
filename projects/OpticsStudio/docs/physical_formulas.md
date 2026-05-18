# OpticsStudio — formulas and interpretation

## What this project computes

The OpticsStudio project contains two independent simulation modules:

1. **CT Tomography** — Filtered backprojection (FBP) reconstruction from parallel-beam projections, using analytic 2D phantoms.
2. **Wave Optics** — Scalar wave propagation via the angular-spectrum method, and 4f Fourier-plane filtering.

---

## CT Tomography

### Radon transform (parallel beam)

For a 2D object \(f(x,y)\), the parallel-beam Radon transform at angle \(\theta\) and detector offset \(s\) is:

\[
p(\theta, s) = \int_{-\infty}^{\infty} \int_{-\infty}^{\infty} f(x,y) \, \delta(x\cos\theta + y\sin\theta - s) \, dx \, dy
\]

In practice, the projection is computed by rotating the phantom grid and summing along one axis.

### Filtered backprojection

The reconstruction \(\hat{f}\) is obtained by:

\[
\hat{f}(x,y) = \int_0^\pi \left[ p(\theta, s) * h(s) \right]_{s = x\cos\theta + y\sin\theta} d\theta
\]

where \(h(s)\) is the ramp filter kernel (Ram–Lak) optionally multiplied by a window (Shepp–Logan, etc.):

\[
H(\omega) = |\omega| \cdot W(\omega)
\]

- **Ram–Lak**: \(W(\omega) = 1\)
- **Shepp–Logan**: \(W(\omega) = \mathrm{sinc}(\pi \omega / (2\omega_\mathrm{max}))\)

### Error metrics

\[
\mathrm{RMSE} = \sqrt{\frac{1}{N}\sum (f - \hat{f})^2}, \qquad
\mathrm{MaxError} = \max |f - \hat{f}|
\]

---

## Scalar Wave Optics

### Angular-spectrum propagation

A scalar field \(U_0(x,y)\) at plane \(z=0\) propagates to plane \(z\) via:

\[
U_z(x,y) = \mathcal{F}^{-1}\!\left\{ \mathcal{F}\{U_0\} \cdot H(f_x, f_y) \right\}
\]

where the transfer function is:

\[
H(f_x, f_y) = \exp\!\left( i 2\pi \frac{z}{\lambda} \sqrt{1 - (\lambda f_x)^2 - (\lambda f_y)^2} \right)
\]

with \(\lambda\) the wavelength and \((f_x, f_y)\) spatial frequencies.

For evanescent waves where \((\lambda f_x)^2 + (\lambda f_y)^2 > 1\), the square root becomes imaginary and the amplitude decays exponentially. Band-limiting truncates the transfer function beyond:

\[
f_\mathrm{limit} = \frac{1}{\lambda \sqrt{1 + (2z / L)^2}}
\]

where \(L\) is the side length of the computational domain.

### 4f Fourier filtering

In a 4f imaging system, the object \(U_0\) is Fourier-transformed at the back focal plane of the first lens, multiplied by a mask \(M(f_x, f_y)\), then inverse-transformed by the second lens:

\[
U_\mathrm{out} = \mathcal{F}^{-1}\!\left\{ \mathcal{F}\{U_0\} \cdot M(f_x, f_y) \right\}
\]

Common masks: pinhole (low-pass), ring (band-pass), horizontal/vertical slits (directional filtering).

---

## Imaging PSF and OTF

### Point spread function

For a diffraction-limited system with circular pupil of radius \(a\), the PSF is:

\[
\mathrm{PSF}(r) = \left| \mathcal{F}\{P(\rho)\, e^{i 2\pi W(\rho,\phi)}\} \right|^2
\]

where \(P(\rho)\) is the pupil function (1 inside, 0 outside) and \(W(\rho,\phi)\) is the wavefront aberration in wavelengths.

### Zernike aberration modes

Low-order optical path differences are modelled with Zernike-like polynomials (\(\rho \le 1\)):

| Mode | \(W(\rho,\phi)\) | Meaning |
|------|------------------|---------|
| None | 0 | Perfect wavefront |
| Tilt x | \(\rho\cos\phi\) | Wavefront tilt in x |
| Defocus | \(2\rho^2 - 1\) | Focal shift |
| Astigmatism | \(\rho^2\cos 2\phi\) | Cylindrical focus |
| Coma | \(\rho(3\rho^2 - 2)\cos\phi\) | Off-axis aberration |
| Spherical | \(6\rho^4 - 6\rho^2 + 1\) | Aperture-uniform aberration |

### Optical transfer function

The OTF is the normalized Fourier transform of the PSF:

\[
\mathrm{OTF}(f_x, f_y) = \frac{\mathcal{F}\{\mathrm{PSF}\}}{\mathcal{F}\{\mathrm{PSF}\}|_{f=0}}
\]

and its magnitude \(|\mathrm{OTF}|\) describes the contrast transfer as a function of spatial frequency.

---

## References

1. Kak, A. C. & Slaney, M. *Principles of Computerized Tomographic Imaging*. IEEE Press, 1988.
2. Goodman, J. W. *Introduction to Fourier Optics*. 4th ed., Freeman, 2017.
3. Born, M. & Wolf, E. *Principles of Optics*. 7th ed., Cambridge University Press, 1999.
