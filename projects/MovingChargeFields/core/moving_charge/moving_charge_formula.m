function [data, rq_now] = moving_charge_formula(X, Y, Z, tObs, motionType, a, omega, lambda_ref)
%MOVING_CHARGE_FORMULA Physics backend for moving-charge field rendering.
% Computes Lienard-Wiechert fields on a 2D slice.

[rx0, ry0, rz0, ~, ~, ~, ~, ~, ~] = motion_state(tObs, motionType, a, omega);
rq_now = [rx0, ry0, rz0];

dx0 = X - rx0;
dy0 = Y - ry0;
dz0 = Z - rz0;
tr = tObs - sqrt(max(dx0.^2 + dy0.^2 + dz0.^2, 0));

maxPicard = 4;
maxNewton = 24;
tol = 5e-12;

for k = 1:maxPicard
    [rx, ry, rz, ~, ~, ~, ~, ~, ~] = motion_state(tr, motionType, a, omega);
    R = sqrt(max((X-rx).^2 + (Y-ry).^2 + (Z-rz).^2, 0));
    tr_new = tObs - R;
    bad = ~isfinite(tr_new);
    tr_new(bad) = tr(bad);
    tr = tr_new;
end

converged = false(size(tr));
tr_prev = tr;
for k = 1:maxNewton
    [rx, ry, rz, vx, vy, vz, ~, ~, ~] = motion_state(tr, motionType, a, omega);

    Rx = X - rx;
    Ry = Y - ry;
    Rz = Z - rz;
    R = sqrt(max(Rx.^2 + Ry.^2 + Rz.^2, 0));
    R = max(R, 1e-13);

    nx = Rx ./ R;
    ny = Ry ./ R;
    nz = Rz ./ R;

    kappa = 1 - (nx.*vx + ny.*vy + nz.*vz);
    kappa = stabilize_kappa(kappa);

    f = tObs - tr - R;
    dtr = f ./ kappa;
    dtr(~isfinite(dtr)) = 0;

    step = 1.0;
    tr_try = tr + step*dtr;
    bad = ~isfinite(tr_try);
    tr_try(bad) = tr(bad);

    improve = abs(step*dtr) < abs(tr - tr_prev) | ~converged;
    tr_prev = tr;
    tr(improve) = tr_try(improve);

    converged = converged | (abs(dtr) < tol);
    if all(converged(:))
        break;
    end
end

[rx, ry, rz, vx, vy, vz, ax, ay, az] = motion_state(tr, motionType, a, omega);

Rx = X - rx;
Ry = Y - ry;
Rz = Z - rz;
R = sqrt(max(Rx.^2 + Ry.^2 + Rz.^2, 0));
R = max(R, 1e-13);

nx = Rx ./ R;
ny = Ry ./ R;
nz = Rz ./ R;

beta2 = vx.^2 + vy.^2 + vz.^2;
invGamma2 = max(1 - beta2, 0);
kappa = stabilize_kappa(1 - (nx.*vx + ny.*vy + nz.*vz));

E1x = invGamma2 .* (nx - vx) ./ (kappa.^3 .* R.^2);
E1y = invGamma2 .* (ny - vy) ./ (kappa.^3 .* R.^2);
E1z = invGamma2 .* (nz - vz) ./ (kappa.^3 .* R.^2);

c1x = (ny - vy).*az - (nz - vz).*ay;
c1y = (nz - vz).*ax - (nx - vx).*az;
c1z = (nx - vx).*ay - (ny - vy).*ax;

E2x = (ny.*c1z - nz.*c1y) ./ (kappa.^3 .* R);
E2y = (nz.*c1x - nx.*c1z) ./ (kappa.^3 .* R);
E2z = (nx.*c1y - ny.*c1x) ./ (kappa.^3 .* R);

Etotx = E1x + E2x;
Etoty = E1y + E2y;
Etotz = E1z + E2z;

[B1x, B1y, B1z] = cross_n_with_field(nx, ny, nz, E1x, E1y, E1z);
[B2x, B2y, B2z] = cross_n_with_field(nx, ny, nz, E2x, E2y, E2z);
[Btx, Bty, Btz] = cross_n_with_field(nx, ny, nz, Etotx, Etoty, Etotz);

maskRadius = max(0.03*lambda_ref, 0.06*a);
badBase = ~isfinite(R) | ~isfinite(kappa) | ~isfinite(invGamma2) | beta2 >= 1;
mask = (R < maskRadius) | badBase | abs(kappa) < 1e-7;

[E1x, E1y, E1z] = apply_mask(mask, real(E1x), real(E1y), real(E1z));
[E2x, E2y, E2z] = apply_mask(mask, real(E2x), real(E2y), real(E2z));
[Etotx, Etoty, Etotz] = apply_mask(mask, real(Etotx), real(Etoty), real(Etotz));

[B1x, B1y, B1z] = apply_mask(mask, real(B1x), real(B1y), real(B1z));
[B2x, B2y, B2z] = apply_mask(mask, real(B2x), real(B2y), real(B2z));
[Btx, Bty, Btz] = apply_mask(mask, real(Btx), real(Bty), real(Btz));

tr(mask) = NaN;

data.vel.Ex = E1x;   data.vel.Ey = E1y;   data.vel.Ez = E1z;
data.vel.Bx = B1x;   data.vel.By = B1y;   data.vel.Bz = B1z;

data.rad.Ex = E2x;   data.rad.Ey = E2y;   data.rad.Ez = E2z;
data.rad.Bx = B2x;   data.rad.By = B2y;   data.rad.Bz = B2z;

data.tot.Ex = Etotx; data.tot.Ey = Etoty; data.tot.Ez = Etotz;
data.tot.Bx = Btx;   data.tot.By = Bty;   data.tot.Bz = Btz;

data.tr = real(tr);
data.mask = mask;
end

function kappa = stabilize_kappa(kappa)
kappa = real(kappa);
s = sign(kappa);
s(s == 0) = 1;
small = abs(kappa) < 1e-10;
kappa(small) = s(small) * 1e-10;
end

function [Fx, Fy, Fz] = apply_mask(mask, Fx, Fy, Fz)
Fx(mask) = NaN;
Fy(mask) = NaN;
Fz(mask) = NaN;
end

function [Cx, Cy, Cz] = cross_n_with_field(nx, ny, nz, Fx, Fy, Fz)
Cx = ny.*Fz - nz.*Fy;
Cy = nz.*Fx - nx.*Fz;
Cz = nx.*Fy - ny.*Fx;
end

function [rx, ry, rz, vx, vy, vz, ax, ay, az] = motion_state(t, motionType, a, omega)
if strcmp(motionType, 'circular')
    rx = a*cos(omega*t);
    ry = a*sin(omega*t);
    rz = 0*t;

    vx = -a*omega*sin(omega*t);
    vy =  a*omega*cos(omega*t);
    vz = 0*t;

    ax = -a*omega^2*cos(omega*t);
    ay = -a*omega^2*sin(omega*t);
    az = 0*t;
else
    rx = 0*t;
    ry = 0*t;
    rz = a*cos(omega*t);

    vx = 0*t;
    vy = 0*t;
    vz = -a*omega*sin(omega*t);

    ax = 0*t;
    ay = 0*t;
    az = -a*omega^2*cos(omega*t);
end
end
