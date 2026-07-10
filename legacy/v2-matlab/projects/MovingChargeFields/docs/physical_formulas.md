# Moving Charge Fields — formulas and interpretation

## What this project visualizes

This project visualizes electric fields, magnetic fields, Poynting flow, and retarded-time structure from a moving point charge.  The charge can move in circular or harmonic motion, and the observation plane can be an \(xy\), \(xz\), or \(yz\) slice.  The preview may show scalar magnitudes, signed normal components, or streamlines.

## Symbols

| Symbol | Meaning |
|---|---|
| \(\mathbf r\) | observation point |
| \(t\) | observation time |
| \(\mathbf r_q(t_r)\) | charge position at retarded time |
| \(t_r\) | retarded time |
| \(\mathbf R=\mathbf r-\mathbf r_q(t_r)\) | retarded separation vector |
| \(\mathbf n=\mathbf R/R\) | unit vector from retarded charge to observer |
| \(\boldsymbol\beta=\mathbf v/c\) | normalized velocity |
| \(\dot{\boldsymbol\beta}\) | normalized acceleration divided by \(c\) |
| \(\mathbf S\) | Poynting vector |

## Retarded time

Electromagnetic information propagates at finite speed.  The fields at \((\mathbf r,t)\) depend on the charge at \(t_r\), where
\[
t-t_r=\frac{|\mathbf r-\mathbf r_q(t_r)|}{c}.
\]
This implicit equation is the core of the visualization.  The charge marker in the plot indicates the source geometry, but the field is determined by the retarded position rather than only the instantaneous position.

## Lienard--Wiechert field

A standard form of the electric field of a moving point charge is
\[
\mathbf E(\mathbf r,t)
=\frac{q}{4\pi\epsilon_0}
\left[
\frac{(1-\beta^2)(\mathbf n-\boldsymbol\beta)}
{(1-\mathbf n\cdot\boldsymbol\beta)^3R^2}
+
\frac{\mathbf n\times\{(\mathbf n-\boldsymbol\beta)\times\dot{\boldsymbol\beta}\}}
{c(1-\mathbf n\cdot\boldsymbol\beta)^3R}
\right]_{t_r}.
\]
The first term is often called the velocity or near-field term and decays like \(1/R^2\).  The second term is the acceleration or radiation term and decays like \(1/R\).

The magnetic field is
\[
\mathbf B=\frac{1}{c}\mathbf n\times\mathbf E.
\]

## Field parts

The GUI can display different parts of the field:

- **total**: full field.
- **velocity**: near-field component.
- **radiation**: acceleration component.
- **normal component**: signed component perpendicular to the chosen slice.
- **in-plane magnitude**: magnitude of the component lying in the slice.
- **streamlines**: direction field using in-plane vector components.

## Energy flow

The Poynting vector is
\[
\mathbf S=\frac{1}{\mu_0}\mathbf E\times\mathbf B.
\]
Streamline views of \(\mathbf S\) show the local direction of electromagnetic energy transport.  Strong beaming can appear when \(\beta\) is close to 1 because factors of \(1-\mathbf n\cdot\boldsymbol\beta\) compress the field angularly.

## Motion presets

For circular motion, a representative trajectory is
\[
\mathbf r_q(t)=a(\cos\omega t,\sin\omega t,0),
\qquad
\beta_\mathrm{max}=\frac{a\omega}{c}.
\]
For harmonic motion, a representative coordinate is
\[
x_q(t)=a\cos\omega t.
\]
The phase control chooses the observation time within one period.

## Numerical notes

Retarded time is solved on a grid, so high \(\beta\), large domains, and streamline views are more expensive.  The display uses logarithmic compression for large dynamic range.  The physical singularity at the charge is regularized visually by masking/normalization so the surrounding field structure remains visible.  Video export sweeps phase and normalizes frame size through the shared export utility.
