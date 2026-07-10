# ChladniFigures-matlab
A MATLAB project for generating **Chladni figures** (nodal-line patterns of vibrating plates). The code is built around the **Kirchhoff–Love thin-plate model**, computes plate eigenmodes for several geometries and boundary conditions, and exports the zero level sets of those modes as PNG images.
This repository is useful in three ways:
- As a GUI tool for quickly generating rectangular, circular, and annular Chladni patterns.
- As a compact teaching/research code for thin-plate eigenvalue problems.
- As a starting point for extending solvers, geometries, or boundary-condition families.

---

## Features
- Supported domains:
  - Rectangle (`rect`)
  - Solid disk (`circ`)
  - Annulus (`annulus`)
- Flexible boundary conditions for all shapes
- Interactive MATLAB GUI
- High-resolution PNG image export
- Clean, modular, research-ready code

---

## Supported Geometries & Boundary Conditions

### Rectangular Plate
Boundary sides encoded in **ULDR** order:
- `U` = Up (top)
- `L` = Left
- `D` = Down (bottom)
- `R` = Right

Each edge can be:
- `C` = Clamped
- `S` = Simply supported
- `F` = Free

Predefined common cases:
`FFFF`, `CCCC`, `SSSS`, `SSCC`, `SSFF`, `SSSC`, `SSSF`, `SSCF`

### Disk & Annulus
- Solid disk: supports `C`, `S`, `F` on the outer boundary
- Annulus: uses **outer–inner** two-letter codes
  - Example: `CC`, `CS`, `CF`, `SC`, `SS`, `SF`, `FC`, `FS`, `FF`

---

## How to Run
Start the GUI in MATLAB:
```matlab
main
```
Or:
```matlab
launch_chladni_studio(pwd)
```

### Main GUI Parameters
- `domain`: `rect`, `circ`, `annulus`
- `boundary`: boundary condition code (e.g., `FFFF`, `SSSS`, `CF`)
- `nu`: Poisson’s ratio ν
- `number of modes`: number of eigenmodes to compute and export
- `grid size`: image resolution
- `xi_0`: geometry ratio (aspect ratio for rectangles, inner/outer radius for annuli)

### Output
- Temporary previews: `.cache/`
- Exported high-resolution PNGs: `output/`
- Filenames automatically encode geometry, BCs, ν, aspect ratio, and mode number

Example filenames:
```
rect-FFFF-nu0.225-xi0.45-mode1.png
annulus-CF-nu0.3-xi0.4-mode2,1.png
```

---

## Governing Equations
The project solves the **Kirchhoff–Love thin-plate equation** for free vibrations:

$$
D \nabla^4 W = \rho h \omega^2 W
$$

Where:
- $W(x,y)$ = transverse mode shape
- $D$ = bending stiffness
- $\nabla^4$ = biharmonic operator
- $\omega$ = natural frequency

Chladni figures correspond to the **nodal lines**:

$$
W(x,y) = 0
$$

### Boundary Conditions
- **Clamped (C)**: $W=0,\ \partial W/\partial n=0$
- **Simply supported (S)**: $W=0,\ M_{nn}=0$
- **Free (F)**: $M_{nn}=0,\ V_n=0$

---

## Numerical Methods
The code uses specialized solvers for each geometry and boundary condition:

### Rectangular Plates
- `SSSS`: Exact Navier double-sine solution
- `SS??` families: Levy-type semi-analytic method
- General BCs: Ritz method, sparse eigenvalue solvers, high-order finite differences

### Circular / Annular Plates
- Polar coordinate separation
- Bessel & modified Bessel functions
- Two-stage numerical root-finding (stable & accurate)

---

## Physical Meaning
Each image shows:
- A vibrational mode shape of a thin plate
- **Dark lines = nodal lines** (no motion during vibration)
- In physical experiments, sand accumulates exactly along these lines

---

## Repository Structure
```
main.m                  GUI entry point
app/                    GUI layout and callbacks
core/rect/              Rectangular plate solvers
core/circ/              Disk and annulus solvers
core/common/            Shared utilities
.cache/                 Temporary preview images
output/                 Exported PNG figures
```

---

## Notes & Limitations
- Focused on **eigenmode computation and Chladni pattern visualization**
- Different solvers for different boundary conditions (numerical behavior may vary slightly)
- Circular modes are real-valued representations of polar eigenfunctions
- Ideal for education, demonstrations, and method development

---

## Suggested Uses
- Classroom demos of plate vibration
- Generating figures for papers, reports, or presentations
- Studying how geometry and boundary conditions affect nodal patterns
- Extending to new plate shapes or numerical methods

---

## License
MIT License (feel free to use and modify for research & education)

---

---

## Static Source Problems

The GUI now has a separate **static sources** tab.  This page is independent from the eigenmode/Chladni tab and solves

```math
D\nabla^4 w = q
```

then renders `w` as a signed heat map.

Supported static load types:

```matlab
% Multiple point or Gaussian patch loads: [x y P sigma]
params.load_type = 'points';
params.sources = [0 0 1 0; 0.5 0.2 -0.7 0.04];

% Uniform transverse load / self-weight
params.load_type = 'uniform';
params.q0 = 1.0;

% General distributed load
params.load_type = 'custom';
params.load_function = @(X,Y) exp(-20*((X-0.3).^2 + Y.^2));

% Superpose all active contributions
params.load_type = 'mixed';
```

For source rows, `x,y` are Cartesian coordinates in the plotted physical domain. Rect uses `x in [-a/2,a/2]`, `y in [-b/2,b/2]`; disk uses `hypot(x,y) < 1`; annulus uses `xi_0 < hypot(x,y) < 1`, so the central hole and the exterior are rejected.

For custom distributed loads, `X` and `Y` are arrays of Cartesian sample locations in the plate material, not an unconstrained square background. The function must return either a scalar or an array with the same size as `X,Y`; use MATLAB elementwise operators such as `.*`, `./`, and `.^`. A three-argument form `@(X,Y,mask) ...` is also accepted; `mask` is true at supplied material samples.

Examples are in:

```text
examples/static/static_points_example.m
examples/static/static_uniform_self_weight_example.m
examples/static/static_custom_load_example.m
examples/static/static_mixed_load_example.m
```



## Static source updates

The GUI keeps eigenvalue/Chladni rendering and static-load rendering on separate tabs.
The `static sources` tab solves `D*nabla^4 w = q` and plots a heat map of the displacement.

Static loads can be selected as:

```matlab
params.load_type = 'points';
params.sources = [0 0 1 0; 0.45 0.25 -0.6 0.04];  % [x y P sigma]
```

```matlab
params.load_type = 'uniform';
params.q0 = 1.0;  % self-weight can be rho*h*g in consistent units
```


```matlab
params.load_type = 'custom';
params.load_function = @(X,Y) exp(-20*((X-0.3).^2 + Y.^2));
```

For `mixed`, point sources, `q0`, and `load_function` are added together. The circular and annular
static backend accelerates custom/uniform loads by computing Fourier moments of polar-shell load
samples and reusing each radial Green solve. Positive-only or negative-only static fields are plotted with one-sided color limits, so zero is at the darkest colorbar end. Sign-changing fields are plotted
with a zero-anchored color scale; mixed-sign fields keep the symmetric signed scale.

