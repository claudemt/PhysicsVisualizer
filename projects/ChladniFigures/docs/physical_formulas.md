# Chladni Figures — formulas and interpretation

## What this project visualizes

This project studies transverse deformation of a thin isotropic plate.  The dynamic displacement is written
\[
w(x,y,t)=\Re\{W(x,y)e^{i\omega t}\}.
\]
The **chladni modes** tab computes eigenmodes `W(x,y)` for rectangular, circular, and annular plates.  The **static sources** tab solves the forced static problem for loads `q(x,y)`.  In preview images, color is the signed displacement or mode amplitude and black zero contours mark nodal sets.

## Symbols

| Symbol | Meaning |
|---|---|
| \(w(x,y,t)\) | transverse displacement |
| \(W(x,y)\) | spatial eigenmode or mode shape |
| \(D\) | bending stiffness scale |
| \(\rho h\) | mass per unit area |
| \(\nu\) | Poisson ratio |
| \(q(x,y)\) | transverse load |
| \(\Omega\) | plate domain |
| \(\partial\Omega\) | plate boundary |
| \(\nabla^4\) | biharmonic operator |
| \(\xi_0\) | rectangular aspect ratio \(b/a\), or annulus inner/outer radius ratio |

## Kirchhoff--Love thin-plate equation

The small-deflection isotropic plate model is
\[
D\nabla^4 w + \rho h\,\frac{\partial^2 w}{\partial t^2}=q(x,y,t),
\]
where
\[
\nabla^4=\nabla^2\nabla^2
=\frac{\partial^4}{\partial x^4}
+2\frac{\partial^4}{\partial x^2\partial y^2}
+\frac{\partial^4}{\partial y^4}.
\]
For free vibration with no forcing,
\[
D\nabla^4 W=\rho h\omega^2 W.
\]
The code works mostly in nondimensional units, so exported images emphasize normalized shapes and nodal structure rather than absolute units.

## Boundary-condition letters

The project supports the three classical ideal edge types:

| Letter | Name | Conditions |
|---|---|---|
| `C` | clamped | \(W=0\), \(\partial W/\partial n=0\) |
| `S` | simply supported | \(W=0\), \(M_{nn}=0\) |
| `F` | free | \(M_{nn}=0\), \(Q_n=0\) |

Here \(M_{nn}\) is the bending moment normal to the boundary and \(Q_n\) is the effective transverse shear.  Boundary choices are not cosmetic: they change both eigenvalues and the zero-contour topology.

## Rectangular boundary input

For rectangles, the GUI accepts an arbitrary four-letter string in **ULDR order**:

\[
\texttt{boundary}=\texttt{Up Left Down Right}.
\]
Each character must be `C`, `S`, or `F`. Examples:

| Code | Interpretation |
|---|---|
| `FFFF` | all edges free |
| `SSSS` | all edges simply supported |
| `CCCC` | all edges clamped |
| `CFSF` | top clamped, left free, bottom simply supported, right free |
| `SCFS` | top simply supported, left clamped, bottom free, right simply supported |

The rectangle uses a fixed horizontal side \(a=2\) and vertical side
\[
b=2\xi_0,
\]
so `xi_0` is the aspect ratio \(b/a\).

## Rectangular eigenmode solvers

For an all-simply-supported rectangle, the solver uses the exact Navier basis
\[
W_{mn}(x,y)=\sin\!\left(\frac{m\pi(x+a/2)}{a}\right)
\sin\!\left(\frac{n\pi(y+b/2)}{b}\right).
\]
When the left and right edges are simply supported, the mixed `?S?S` family uses the same Levy determinant solver as the MATLAB project: the x direction is sinusoidal and the y direction is expanded in \(\cosh(py)\), \(\sinh(py)\), \(\cos(qy)\), and \(\sin(qy)\), with boundary rows enforcing \(W,\theta,M,V\) as appropriate.  All-clamped `CCCC` uses a biharmonic finite-difference eigenproblem with clamped ghost-row closure.  All-free `FFFF` has a dedicated Ritz entry point that projects out the three rigid-body modes, and the legacy square-only `free_sparse` ghost-boundary formulation remains selectable for comparison.  Other mixed cases use the general Ritz trial basis.  `compute_rect_modes(..., solver=...)` accepts `auto`, `navier`, `clamped_fd`, `levy`, `free_ritz`, `free_sparse`, and `ritz`; `ritz` preserves the general variational path explicitly.
\[
K\mathbf{c}=\Lambda M\mathbf{c}.
\]
The exported Chladni images show the reconstructed field \(W(x,y)\), normalized by its maximum absolute amplitude.

## Circular and annular eigenmodes

In polar coordinates,
\[
x=r\cos\theta,\qquad y=r\sin\theta,
\]
separable modes have angular dependence
\[
\cos(m\theta)\quad\text{or}\quad\sin(m\theta)
\]
and radial parts built from Bessel and modified-Bessel functions.  For a solid disk, regularity at the origin removes singular basis terms.  For an annulus, inner and outer boundary conditions both enter the radial system.

The annulus boundary code is an ordered outer-inner pair, for example `CF` means clamped outer edge and free inner edge.  The Python solver now mirrors the MATLAB high-accuracy path: it builds the Bessel/modified-Bessel boundary matrix, equilibrates rows and columns, finds determinant sign changes and smallest-singular-value minima, polishes roots, and reconstructs each radial mode from the null vector.

## Static forced response

The static tab solves
\[
D\nabla^4 w=q(x,y).
\]
The input load can be one of four types:

| Load type | Meaning |
|---|---|
| `points` | source matrix rows `[x y P sigma]` |
| `uniform` | constant load \(q_0\) |
| `custom` | MATLAB expression or handle `q(X,Y)` |
| `mixed` | combination of uniform, source rows, and custom expression |

For a source row `[x_j y_j P_j sigma_j]`, `sigma=0` is treated as an ideal point load when supported by the solver.  A positive `sigma` is interpreted as a localized Gaussian patch.

A custom load can be written as either a function handle

```matlab
@(X,Y) exp(-18*((X-0.25).^2 + (Y+0.1).^2))
```

or as a bare elementwise expression such as

```matlab
sin(pi*X).*sin(pi*Y)
```

## Static rectangular algorithm

For rectangular domains, the load is projected onto a truncated static modal/Ritz basis.  If \(\phi_j\) are basis modes, then
\[
w(x,y)\approx \sum_j a_j\phi_j(x,y),
\]
with coefficients determined by the modal stiffness and load projections.  The `truncation` input controls the number of retained basis functions.

For completely free static plates, the problem is singular unless the load has zero resultant and zero resultant moment.  The solver checks compatibility for free rectangular plates and reports an error if the static solution is not unique.

## Static circular and annular algorithm

For disks and annuli, the static solver uses polar biharmonic Green-function expansions.  Point loads are summed directly over Fourier order \(m\); uniform loads are approximated by radial shell moments.  Free disk and free-free annulus static cases remain singular without a balancing gauge and are rejected.

## How to read the images

- Color shows the signed mode shape or static displacement.
- Black contours mark the zero-level set where nodal lines occur.
- Rectangular edges constrained by `C` or `S` may include zero boundary lines because \(W=0\) there.
- Circular and annular masks hide points outside the physical plate.
- Higher modes contain finer nodal features and may need a larger grid size.

## Export behavior

The preview list lets you select and reorder images before exporting.  Exports use the shared project convention: short semantic filenames plus a `parameters.txt` file recording the full numerical setup.  Reproducibility information goes into `reproduce_code.m`.
