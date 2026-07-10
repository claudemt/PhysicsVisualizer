# Waveguide Theory Notes

This document summarizes the physical quantities used by Waveguide Studio and the models behind each plot.

## 1. Common definitions

All implemented guides are uniform in the propagation direction `z`. A field component is written as

```text
F(x,y,z,t) = f(x,y) exp(j omega t - j beta z).
```

The most important quantities are:

```text
omega = 2 pi f                         angular frequency
k_0   = omega/c = 2 pi/lambda_0        free-space wavenumber
beta  = phase constant along z         rad/m
n_eff = beta/k_0                       effective index
```

For dielectric guided modes, the effective index measures the propagation constant as if the guided mode were a plane wave in a material with index `n_eff`. A bound dielectric mode has

```text
n_cl < n_eff < n_co.
```

Here `n_co` is the core refractive index and `n_cl` is the cladding refractive index. Subscripts such as `co`, `cl`, `eff`, `max`, `c`, and `g` are labels, so plot text uses roman subscripts: `n_{\mathrm{cl}}`, `n_{\mathrm{eff}}`, `V_{\mathrm{max}}`, `f_{\mathrm{c}}`, and `v_{\mathrm{g}}`.

## 2. Rectangular PEC waveguide

A rectangular perfectly conducting waveguide has width `a` and height `b`. The transverse cutoff wavenumber is

```text
k_c = pi sqrt((m/a)^2 + (n/b)^2).
```

The cutoff frequency is

```text
f_c = c k_c / (2 pi) = (c/2) sqrt((m/a)^2 + (n/b)^2).
```

Mode-index rules:

```text
TE_mn: m and n may be zero, but not both zero.
TM_mn: m >= 1 and n >= 1.
```

For frequencies above cutoff, `f > f_c`, the propagation constant and group velocity are

```text
beta  = sqrt(k_0^2 - k_c^2)
v_g/c = sqrt(1 - (f_c/f)^2).
```

The dispersion plot uses frequency on the horizontal axis, `beta` on the left vertical axis, and `v_g/c` on the right vertical axis. Each mode starts at its own cutoff frequency `f_c`. The GUI parameter `f max (GHz)` only sets the plotted upper frequency; it does not change the physics.

## 3. Circular PEC waveguide

A circular PEC waveguide with radius `r` uses Bessel functions. TM modes use roots of `J_m`; TE modes use roots of the derivative `J_m'`:

```text
TM: J_m(chi_mn) = 0
TE: J_m'(chi'_mn) = 0
```

The cutoff frequency is

```text
f_c = c chi / (2 pi r),
```

where `chi` is the appropriate TM or TE root. The same above-cutoff relation applies:

```text
beta^2 = k_0^2 - k_c^2.
```

## 4. Symmetric planar dielectric slab

The planar dielectric slab has a core index `n_co`, cladding index `n_cl`, and core thickness `d`. Guided modes require

```text
n_co > n_cl.
```

The transverse equations are

```text
X'' + h^2 X = 0       in the core,
X'' - gamma^2 X = 0   in the cladding.
```

The normalized variables used by the dispersion curve are

```text
U = h d/2
W = gamma d/2
V = k_0 d sqrt(n_co^2 - n_cl^2)/2
V^2 = U^2 + W^2
```

The normalized propagation parameter is

```text
b = W^2/V^2 = (n_eff^2 - n_cl^2)/(n_co^2 - n_cl^2).
```

Therefore,

```text
n_eff = sqrt(n_cl^2 + b (n_co^2 - n_cl^2)).
```

Interpretation:

```text
b near 0: mode is near cutoff and weakly confined.
b near 1: mode is strongly confined in the core.
```

For the symmetric slab implementation, the characteristic equations are

```text
W = q U tan(U)       even modes
W = -q U cot(U)      odd modes
```

with

```text
q = 1                 for TE
q = (n_cl/n_co)^2     for TM
```

The planar dispersion plot is normalized `b` versus `V`; it does not require a physical thickness. The mode-field and thickness-sweep plots convert physical inputs into `V` before solving for the guided branches.

## 5. Cylindrical step-index dielectric guide

The cylindrical dielectric guide is described using the step-index variables

```text
V = k_0 a sqrt(n_co^2 - n_cl^2)
U = a sqrt(n_co^2 k_0^2 - beta^2)
W = a sqrt(beta^2 - n_cl^2 k_0^2)
V^2 = U^2 + W^2
```

Here `a` is the core radius. Guided modes again satisfy

```text
n_cl < n_eff < n_co.
```

The plotted contours are zero contours of the cylindrical characteristic equation. Each contour family corresponds to an azimuthal order `m`. The dashed line `U=V` is the cutoff boundary `W=0`.

## 6. What each plot means

- **Mode field:** normalized spatial mode pattern. The colorbar shows relative signed amplitude, not absolute power.
- **Planar dispersion:** normalized `b(V)` branches. Use it to see when modes appear and how confined they become.
- **Planar mode existence:** cutoff locations in normalized `V`.
- **Planar thickness sweep:** fixed-frequency scan over slab thickness; it shows mode count and `n_eff` branches.
- **Metal dispersion:** frequency scan of `beta` and `v_g/c`; every branch starts only above that mode's `f_c`.
- **Cutoff map:** mode-index table of cutoff frequencies.
- **Cylindrical dielectric dispersion:** normalized characteristic-equation contours in the `V-U` plane.
