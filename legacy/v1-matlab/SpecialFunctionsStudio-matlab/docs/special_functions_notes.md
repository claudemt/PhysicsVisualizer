# Special Functions Reference

This note records the definitions and differential-equation context used by the GUI.  The MATLAB implementation follows the conventions described here.

## Bessel Functions

The ordinary Bessel equation is

$$
x^2 y'' + x y' + (x^2-\nu^2)y = 0.
$$

The regular solution is

$$
J_\nu(x)=\sum_{k=0}^{\infty}\frac{(-1)^k}{k!\Gamma(k+\nu+1)}\left(\frac{x}{2}\right)^{2k+\nu}.
$$

For noninteger order, a second solution can be written as

$$
Y_\nu(x)=\frac{J_\nu(x)\cos(\pi\nu)-J_{-\nu}(x)}{\sin(\pi\nu)}.
$$

The modified Bessel equation is

$$
x^2 y'' + x y' - (x^2+\nu^2)y = 0,
$$

with standard solutions $I_\nu$ and $K_\nu$.  The $I$ solution is regular near the origin; the $K$ solution decays on the positive real axis.

## Spherical Bessel Functions

The spherical radial Helmholtz equation is

$$
x^2 y'' + 2xy' + (x^2-n(n+1))y=0.
$$

The standard functions are

$$
j_n(x)=\sqrt{\frac{\pi}{2x}}J_{n+1/2}(x),\qquad
y_n(x)=\sqrt{\frac{\pi}{2x}}Y_{n+1/2}(x).
$$

## Airy Functions

Airy functions solve

$$
y'' - xy = 0.
$$

$\mathrm{Ai}(x)$ is the solution that decays on the positive real axis; $\mathrm{Bi}(x)$ is the second standard real solution.  They arise as canonical local solutions near simple turning points in second-order linear ODEs.

## Lane--Emden Function

The Lane--Emden equation is

$$
\frac{1}{\xi^2}\frac{d}{d\xi}\left(\xi^2\frac{d\theta}{d\xi}\right)+\theta^n=0,
\qquad \theta(0)=1,\quad \theta'(0)=0.
$$

It comes from polytropic models of self-gravitating spheres.  The regular solution begins as $\theta(\xi)=1-\xi^2/6+O(\xi^4)$.

## Elliptic Integrals

This project uses the Legendre parameter $m$ rather than the modulus $k$; in many texts $m=k^2$.

$$
K(m)=\int_0^{\pi/2}\frac{d\theta}{\sqrt{1-m\sin^2\theta}},
$$

$$
E(m)=\int_0^{\pi/2}\sqrt{1-m\sin^2\theta}\,d\theta,
$$

$$
F(\phi|m)=\int_0^\phi\frac{d\theta}{\sqrt{1-m\sin^2\theta}},
$$

$$
E(\phi|m)=\int_0^\phi\sqrt{1-m\sin^2\theta}\,d\theta,
$$

$$
\Pi(n;\phi|m)=\int_0^\phi\frac{d\theta}{(1-n\sin^2\theta)\sqrt{1-m\sin^2\theta}}.
$$

## Jacobi Elliptic Functions

Let

$$
u = F(\phi|m).
$$

Then

$$
sn(u|m)=\sin\phi,
\qquad cn(u|m)=\cos\phi,
\qquad dn(u|m)=\sqrt{1-m\sin^2\phi}.
$$

These functions generalize sine and cosine and occur in nonlinear oscillators and elliptic parametrizations.

## Gauss Hypergeometric Function

The hypergeometric equation is

$$
z(1-z)y''+[c-(a+b+1)z]y'-aby=0.
$$

The normalized analytic solution at $z=0$ is

$$
{}_2F_1(a,b;c;z)=\sum_{k=0}^{\infty}\frac{(a)_k(b)_k}{(c)_k}\frac{z^k}{k!}.
$$

## Spherical Harmonics

The GUI uses the Condon--Shortley phase convention:

$$
Y_l^m(\theta,\phi)=(-1)^m\sqrt{\frac{2l+1}{4\pi}\frac{(l-m)!}{(l+m)!}}P_l^m(\cos\theta)e^{im\phi}.
$$

They satisfy the spherical Laplacian eigenvalue equation

$$
\Delta_{S^2}Y_l^m=-l(l+1)Y_l^m.
$$

## Vector Spherical Harmonics

The project visualizes three common angular vector fields:

$$
\mathbf X_{lm}=\frac{1}{\sqrt{l(l+1)}}\mathbf L Y_l^m,
\qquad \mathbf L=-i\mathbf r\times\nabla,
$$

$$
\mathbf\Psi_{lm}=\frac{r\nabla Y_l^m}{\sqrt{l(l+1)}},
$$

$$
\mathbf Y_{lm}^{(r)}=\hat{\mathbf r}Y_l^m.
$$
