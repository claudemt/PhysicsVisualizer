# Creative Plot Studio — mathematical motifs and interpretation

## What this project visualizes

This project is a curated collection of MATLAB generative-plot scripts.  It is less about one governing physical law and more about reusable mathematical image-making ideas: parametric curves, polar harmonics, complex iteration, nonlinear maps, particle traces, and color transforms.  The GUI chooses a category and a concrete script, then renders it in a shared preview axes.

## Symbols

| Symbol | Meaning |
|---|---|
| \(t\) | curve parameter |
| \(\theta\) | polar angle |
| \(z=x+iy\) | complex-plane coordinate |
| \(n\) | iteration index |
| \(c\) | complex or real control parameter |
| \(N\) | maximum iteration count |
| \(C\) | color value or palette coordinate |

## Parametric and polar curves

Many scripts construct a curve
\[
\mathbf r(t)=\begin{bmatrix}x(t)\\y(t)\end{bmatrix},\qquad t\in[t_0,t_1],
\]
and then use radius, curvature, time, or phase to color it.  A common polar family is
\[
r(\theta)=a+b\cos(k\theta+\phi),
\]
with Cartesian coordinates
\[
x=r(\theta)\cos\theta,\qquad y=r(\theta)\sin\theta.
\]
When several harmonics are added,
\[
r(\theta)=a+\sum_j b_j\cos(k_j\theta+\phi_j),
\]
small changes in \(k_j\) and \(\phi_j\) can turn a simple rosette into a woven pattern.

## Iterated maps

Fractal and nonlinear scripts often iterate
\[
z_{n+1}=f(z_n,c).
\]
The classic quadratic example is
\[
z_{n+1}=z_n^2+c.
\]
An escape-time image records the first \(n\) for which
\[
|z_n|>R_\mathrm{escape}.
\]
Points that do not escape before \(N\) iterations are treated as belonging to the bounded set for that finite computation.  The visible image is often
\[
C(x,y)=\frac{n_\mathrm{escape}(x,y)}{N}
\]
or a smoothed variant of that quantity.

## Nonlinear and chaotic trajectories

Some scripts plot trajectories of a map
\[
\mathbf x_{n+1}=F(\mathbf x_n;\boldsymbol\alpha),
\]
or sample an implicit flow field.  The picture is not merely a set of points; it is a record of how repeated application of the same rule accumulates structure.  Sensitivity to parameters is expected, especially near chaotic regimes.

## Color mapping

The scripts frequently convert scalar quantities into color:
\[
\mathrm{RGB}=P(C),
\]
where \(P\) is a palette interpolation.  A useful normalized color coordinate is
\[
C=\frac{s-s_\mathrm{min}}{s_\mathrm{max}-s_\mathrm{min}},
\]
where \(s\) might be radius, iteration count, speed, curvature, or phase.  Phase-like quantities are often cyclic:
\[
C=\frac{\operatorname{mod}(\phi,2\pi)}{2\pi}.
\]

## How the preview is generated

The selected script draws directly into the shared preview axes.  GUI-level layout, export, cache handling, and file naming come from the shared utilities.  The script itself should focus on geometry, iteration, and color.  Exported images are named by category/project rather than by a long parameter list because run metadata is recorded in `parameters.txt`.

## Python reproduction parity

The Python catalog mirrors the MATLAB domain/category/project catalog: 17 art entries, 22 fractal entries, and 23 nonlinear entries.  The `everything_composite` reproduction exports the 62 canonical individual PNG files plus the root preview composite, and also writes a legacy-compatible partial batch under `output/creative_plot_studio_all_python/individual` with the first 34 legacy file names and its preview composite.  This matches the legacy example's 98 PNG file structure while keeping reusable export behavior in `utils.image_output`.

The current Python renderers are item-specific rather than category placeholders.  They cover MATLAB-style escape-time sets, Newton/Nova basins, orbit traps, recursive fractals, Gray-Scott and FitzHugh-Nagumo fields, ODE attractors, maps, oscillators, procedural floral/scene drawings, and generative surfaces.  Randomized scenes use deterministic local seeds so repeated reproduction runs are stable.

## Interpretation notes

A generative plot is usually not a direct measurement of a physical observable.  It is a visualization of an algorithmic rule.  When comparing two images, ask which part changed: the curve equation, the sampling density, the iteration limit, the palette, the axes scaling, or the random seed.  The same mathematical object can look very different under a different palette or camera view.
