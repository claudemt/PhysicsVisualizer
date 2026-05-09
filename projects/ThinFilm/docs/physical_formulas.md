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
k_x=k_P\sin\theta_P=k_S\sin\theta_S.
\]
For layer m, the vertical phases used in the transfer matrices are
\[
\varphi_{P,m}=k_{P,m}h_m\cos\theta_{P,m},
\qquad
\varphi_{S,m}=k_{S,m}h_m\cos\theta_{S,m}.
\]
Real vertical phases represent propagating vertical components; imaginary phases represent evanescent decay.

### P/SV potentials and interface conditions

For in-plane motion, the displacement is written in terms of a P potential \(\phi\) and an SV potential \(\psi\):
\[
u_x=\frac{\partial\phi}{\partial x}+\frac{\partial\psi}{\partial z},
\qquad
u_z=\frac{\partial\phi}{\partial z}-\frac{\partial\psi}{\partial x}.
\]
At every interface, the code imposes continuity of displacement and traction:
\[
u_x^{(1)}=u_x^{(2)},\qquad
u_z^{(1)}=u_z^{(2)},
\]
\[
\sigma_{xz}^{(1)}=\sigma_{xz}^{(2)},\qquad
\sigma_{zz}^{(1)}=\sigma_{zz}^{(2)}.
\]
These four conditions couple P and SV waves.  In code, the P/SV state is a normalized four-component vector proportional to
\[
\mathbf{s}_{PSV}=\begin{bmatrix}
u_x&u_z&\sigma_{xz}&\sigma_{zz}\end{bmatrix}^T.
\]

For one layer, define
\[
\kappa=\frac{\mu}{\lambda+2\mu},
\qquad
E_P^\pm=e^{\pm i\varphi_P},
\qquad
E_S^\pm=e^{\pm i\varphi_S}.
\]
The layer basis matrix used by `elastic_film_formula.m` is
\[
B(\varphi_P,\varphi_S)=
\begin{bmatrix}
E_P^+ & E_P^- & -\cot\theta_S E_S^+ & \cot\theta_S E_S^- \\
\cot\theta_P E_P^+ & -\cot\theta_P E_P^- & E_S^+ & E_S^- \\
\eta\kappa\sin2\theta_P E_P^+ & -\eta\kappa\sin2\theta_P E_P^- & -\eta\cos2\theta_S E_S^+ & -\eta\cos2\theta_S E_S^- \\
\eta\cos2\theta_S E_P^+ & \eta\cos2\theta_S E_P^- & \eta\sin2\theta_S E_S^+ & -\eta\sin2\theta_S E_S^-
\end{bmatrix}.
\]
The P/SV transfer matrix for the layer is
\[
M_m^{PSV}=B(0,0)\,B(\varphi_{P,m},\varphi_{S,m})^{-1}.
\]
The stack matrix is the product of the layer matrices.  Reflection and transmission for P incidence and SV incidence are found by solving the resulting 4-by-4 linear systems for reflected P, reflected SV, transmitted P, and transmitted SV amplitudes.

### SH channel

SH motion is independent of P/SV motion.  The code uses the shear impedance
\[
\zeta=\eta c_S
\]
and the S-wave vertical phase \(\varphi_S=k_S h\cos\theta_S\).  The SH layer matrix is
\[
M_m^{SH}=
\begin{bmatrix}
\cos\varphi_S & -i\dfrac{\sin\varphi_S}{\zeta\cos\theta_S} \\
-i\zeta\cos\theta_S\sin\varphi_S & \cos\varphi_S
\end{bmatrix}.
\]
After multiplying the SH layer matrices, the solver computes the SH reflection and transmission amplitudes from the two boundary impedances in media **a** and **g**.

### Elastic report quantities

For **P incidence**, the report lists
\[
r_{P|P},\quad r_{SV|P},\quad t_{P|P},\quad t_{SV|P}
\]
and their flux-normalized powers
\[
R_{P|P},\quad R_{SV|P},\quad T_{P|P},\quad T_{SV|P}.
\]
For **SV incidence**, it lists the analogous converted and non-converted P/SV coefficients.  For **SH incidence**, it lists \(r_{SH}\), \(t_{SH}\), \(R_{SH}\), and \(T_{SH}\).  The reported energy sums are
\[
E_P=R_{P|P}+R_{SV|P}+T_{P|P}+T_{SV|P},
\]
\[
E_{SV}=R_{P|SV}+R_{SV|SV}+T_{P|SV}+T_{SV|SV},
\]
\[
E_{SH}=R_{SH}+T_{SH}.
\]

---

## Optical-wave tab

### Model and material parameters

The optical tab models a stratified electromagnetic stack.  Each medium is defined by
\[
(\varepsilon,\mu),
\]
where \(\varepsilon\) is permittivity and \(\mu\) is permeability in the unit system used by the GUI.  The refractive index and characteristic admittance are
\[
n=\sqrt{\varepsilon\mu},
\qquad
\zeta=\sqrt{\frac{\varepsilon}{\mu}}.
\]
The incident angle in medium **a** fixes the in-plane wave number:
\[
k_x=\omega n_a\sin\theta_a
  =\omega\sqrt{\varepsilon_a\mu_a}\sin\theta_a.
\]
In medium m,
\[
k_{z,m}=\sqrt{\omega^2\varepsilon_m\mu_m-k_x^2},
\qquad
\cos\theta_m=\frac{k_{z,m}}{\omega n_m},
\]
and the layer phase is
\[
\varphi_m=k_{z,m}h_m.
\]
The s and p polarizations do not couple in this isotropic optical model, so the solver uses separate 2-by-2 matrices.

### s-polarized layer matrix

For s polarization, the tangential electric and magnetic state is propagated with
\[
P_m=
\begin{bmatrix}
\cos\varphi_m & -i\dfrac{\sin\varphi_m}{\zeta_m\cos\theta_m} \\
-i\zeta_m\cos\theta_m\sin\varphi_m & \cos\varphi_m
\end{bmatrix}.
\]
This has the same impedance-and-phase structure as the elastic SH matrix, with the optical admittance \(\zeta\) replacing the elastic shear impedance.

### p-polarized layer matrix

For p polarization, the admittance factors are interchanged according to the p-polarized boundary variables.  The code uses
\[
Q_m=
\begin{bmatrix}
\cos\varphi_m & -i\dfrac{\zeta_m\sin\varphi_m}{\cos\theta_m} \\
-i\dfrac{\cos\theta_m\sin\varphi_m}{\zeta_m} & \cos\varphi_m
\end{bmatrix}.
\]
The total optical matrices are
\[
P=P_1P_2\cdots P_N,
\qquad
Q=Q_1Q_2\cdots Q_N.
\]
When \(N=0\), these products are identity matrices, so the formulas reduce to the direct interface case between **a** and **g**.

### Optical reflection and transmission coefficients

For s polarization, define
\[
C_s=P_{11}+\zeta_g\cos\theta_g P_{12},
\qquad
D_s=P_{21}+\zeta_g\cos\theta_g P_{22}.
\]
Then
\[
r_s=\frac{\zeta_a\cos\theta_a C_s-D_s}
          {\zeta_a\cos\theta_a C_s+D_s},
\qquad
 t_s=\frac{2\zeta_a\cos\theta_a}
          {\zeta_a\cos\theta_a C_s+D_s}.
\]
For p polarization, define
\[
C_p=Q_{11}\zeta_g+Q_{12}\cos\theta_g,
\qquad
D_p=Q_{21}\zeta_g+Q_{22}\cos\theta_g.
\]
Then
\[
r_p=\frac{\cos\theta_a C_p-\zeta_a D_p}
          {\cos\theta_a C_p+\zeta_a D_p},
\qquad
 t_p=\frac{2\zeta_a\cos\theta_a}
          {\cos\theta_a C_p+\zeta_a D_p}.
\]
The reported optical powers are
\[
R_s=|r_s|^2,
\qquad
T_s=\frac{\zeta_g\cos\theta_g}{\zeta_a\cos\theta_a}|t_s|^2,
\]
\[
R_p=|r_p|^2,
\qquad
T_p=\frac{\zeta_g\cos\theta_g}{\zeta_a\cos\theta_a}|t_p|^2.
\]
For lossless, propagating boundary media, the report checks
\[
E_s=R_s+T_s\approx1,
\qquad
E_p=R_p+T_p\approx1.
\]

### Layer-thickness input

In the optical GUI, each layer row is entered as

```text
eps mu h
```

The third field can be either a numeric thickness or a symbolic optical thickness of the form

```text
coeff*lambda
```

Spaces around `*` are allowed.  Here `lambda` means the wavelength in the incident medium **a**:
\[
\lambda_a=\frac{2\pi}{\omega n_a}.
\]
The parser interprets `coeff*lambda` as a normal optical path condition,
\[
n_m\cos\theta_m\,h_m=\mathrm{coeff}\,\lambda_a.
\]
Using \(n_m\cos\theta_m=k_{z,m}/\omega\), the corresponding physical thickness is
\[
h_m=\frac{\mathrm{coeff}\,\lambda_a}{n_m\cos\theta_m}.
\]
This symbolic thickness is intended for propagating layers.  If the layer is evanescent so that \(\operatorname{Re}(k_{z,m}/\omega)\le0\), the code raises an error rather than silently converting the input into an unphysical very large thickness.

Scripted calls to `optical_film_formula` also support quarter-wave helpers such as `quarterwave` and `alternating_quarterwave`.  Those helpers are optional conveniences for batch construction; the GUI uses the explicit layer table described above.

---

## How to read the report

The report is text because the main output is a set of numerical transfer-matrix diagnostics rather than an image.  Both tabs follow the same order:

1. global inputs such as \(N\), \(\omega\), and either \(k_x\) or \(\theta_a\);
2. incident and substrate medium properties;
3. layer-by-layer material parameters and phases;
4. complex reflection/transmission amplitudes;
5. flux-normalized powers and energy-sum diagnostics.

A blank layer table means \(N=0\): the two half-spaces interact directly with no inserted film layers.
