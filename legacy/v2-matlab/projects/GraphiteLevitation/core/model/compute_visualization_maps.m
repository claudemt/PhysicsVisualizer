function result = compute_visualization_maps(params)
%COMPUTE_VISUALIZATION_MAPS Four core plots and laser/no-laser comparison data.
% The display height is not blindly accepted as a fixed input. It is used as
% an initial guess, then the no-laser vertical force balance Fz = mg is solved
% at the planar potential minimum. The maps are then recomputed at that
% equilibrated height. This makes the visualization closer to the actual
% levitation experiment.

params = validate_graphite_levitation_params(params);
paramsInput = params;
paramsOff = params;
paramsOff.laser.enabled = false;

% First quick map at the user guess to locate a reasonable horizontal well.
baseGuess = local_compute_single_maps(paramsOff);
metricsGuess = extract_visual_metrics(baseGuess.x, baseGuess.y, baseGuess.U, baseGuess.B2, paramsOff);

% Solve vertical force balance at the no-laser well. The PPT experiment uses
% N52 magnets with Br around 1.46 T and fitted |chi| around 305e-6; these are
% the defaults, so the solved z should land in the experimentally plausible
% millimetre scale when the sample size/thickness is reasonable.
[zEq, zInfo] = local_solve_vertical_equilibrium(paramsOff, metricsGuess.xMin, metricsGuess.yMin);
paramsOff.graphite.z0 = zEq;
params.graphite.z0 = zEq;

% Final maps at the mechanically balanced height.
base = local_compute_single_maps(paramsOff);
active = local_compute_single_maps(params);

metricsBase = extract_visual_metrics(base.x, base.y, base.U, base.B2, paramsOff);
metricsActive = extract_visual_metrics(active.x, active.y, active.U, active.B2, params);
metrics = local_combine_metrics(metricsActive, metricsBase, params, active, base, zInfo, paramsInput.graphite.z0);

% Top-level aliases keep older render/scan code simple.
result = active;
result.params = params;
result.inputParams = paramsInput;
result.base = base;
result.active = active;
result.metrics = metrics;
result.compareEnabled = params.laser.enabled;
end

function out = local_compute_single_maps(params)
params = validate_graphite_levitation_params(params);
mu0 = params.numerics.mu0;

magnets = build_compact_checkerboard_magnets(params);
[displayHalfX, displayHalfY, sampleExtent] = local_view_extents(params);
N = params.numerics.gridN;

% The potential is a convolution of the field map with the graphite footprint.
% We need an extended field grid so the graphite center can approach the edge
% of the displayed magnet array without truncating the kernel.
margin = sampleExtent + 0.25*max(params.magnet.a, params.magnet.b);
baseSpanX = 2*displayHalfX;
baseSpanY = 2*displayHalfY;
NxExt = max(N, N + 2*ceil(N*margin/(baseSpanX+eps)));
NyExt = max(N, N + 2*ceil(N*margin/(baseSpanY+eps)));
xExt = linspace(-displayHalfX-margin, displayHalfX+margin, NxExt);
yExt = linspace(-displayHalfY-margin, displayHalfY+margin, NyExt);
[Xext, Yext] = meshgrid(xExt, yExt);

z0 = params.graphite.z0;
dz = local_force_dz(params);
B0 = evaluate_dipole_field_map(Xext, Yext, z0, magnets, params);
Bp = evaluate_dipole_field_map(Xext, Yext, z0 + dz, magnets, params);
Bm = evaluate_dipole_field_map(Xext, Yext, max(z0 - dz, 1e-6), magnets, params);
B2ext = B0.Bx.^2 + B0.By.^2 + B0.Bz.^2;
B2p = Bp.Bx.^2 + Bp.By.^2 + Bp.Bz.^2;
B2m = Bm.Bx.^2 + Bm.By.^2 + Bm.Bz.^2;

ix = find(xExt >= -displayHalfX & xExt <= displayHalfX);
iy = find(yExt >= -displayHalfY & yExt <= displayHalfY);
x = xExt(ix); y = yExt(iy);
B2 = B2ext(iy, ix);

dx = mean(diff(xExt)); dy = mean(diff(yExt));
[kernel, kernelInfo] = build_graphite_chi_kernel(params, dx, dy);
coef = params.graphite.thickness * params.graphite.chiAbs / (2*mu0);
Uext = conv2(B2ext, rot90(kernel, 2), 'same') * dx * dy * coef;
Upext = conv2(B2p, rot90(kernel, 2), 'same') * dx * dy * coef;
Umext = conv2(B2m, rot90(kernel, 2), 'same') * dx * dy * coef;
Fzext = -(Upext - Umext) / (2*dz);
U = Uext(iy, ix);
Fz = Fzext(iy, ix);

[chiMap, chiX, chiY] = build_chi_image(params);

out = struct();
out.params = params;
out.magnets = magnets;
out.x = x; out.y = y;
out.B2 = B2; out.B2Norm = local_norm_by_max(B2);
out.U = U; out.UNorm = local_norm_by_max(U);
out.Fz = Fz;
out.chi = struct('x', chiX, 'y', chiY, 'weight', chiMap);
out.kernel = kernelInfo;
end

function metrics = local_combine_metrics(active, base, params, activeMaps, baseMaps, zInfo, zInput)
metrics = active;
metrics.xMinOff = base.xMin;
metrics.yMinOff = base.yMin;
metrics.xMinOn = active.xMin;
metrics.yMinOn = active.yMin;
metrics.stableOff = base.stable;
metrics.stableOn = active.stable;
metrics.dxLaser = active.xMin - base.xMin;
metrics.dyLaser = active.yMin - base.yMin;
metrics.displacement = hypot(metrics.dxLaser, metrics.dyLaser);
metrics.UContrastOff = base.UContrast;
metrics.UContrastOn = active.UContrast;
metrics.barrierXOff = base.barrierX;
metrics.barrierYOff = base.barrierY;
metrics.barrierXOn = active.barrierX;
metrics.barrierYOn = active.barrierY;

area = graphite_area(params.graphite);
mass = params.graphite.rho * area * params.graphite.thickness;
mg = max(mass * 9.80665, eps);
metrics.mass = mass;
metrics.weight = mg;
metrics.zInput = zInput;
metrics.zEqOff = params.graphite.z0;
metrics.zEqOn = NaN;
metrics.zSolveConverged = zInfo.converged;
metrics.zSolveMessage = zInfo.message;

% Force readback from the displayed finite-difference force maps.
metrics.FzOffAtMin = NaN;
metrics.FzOnAtMin = NaN;
try
    metrics.FzOffAtMin = interp2(baseMaps.x, baseMaps.y, baseMaps.Fz, base.xMin, base.yMin, 'linear', NaN);
catch
end
try
    metrics.FzOnAtMin = interp2(activeMaps.x, activeMaps.y, activeMaps.Fz, active.xMin, active.yMin, 'linear', NaN);
catch
end
if ~isfinite(metrics.FzOffAtMin)
    try, metrics.FzOffAtMin = zInfo.FzEq; catch, end
end
metrics.FzOffOverMg = metrics.FzOffAtMin / mg;
metrics.FzOnOverMg = metrics.FzOnAtMin / mg;

% Solve the active vertical height as a diagnostic, but keep comparison maps at
% the same no-laser height so U0 and UL are visually comparable.
try
    [zOn, infoOn] = local_solve_vertical_equilibrium(params, active.xMin, active.yMin);
    metrics.zEqOn = zOn;
    metrics.FzOnEq = infoOn.FzEq;
catch
    metrics.FzOnEq = NaN;
end

% Linearized horizontal force proxy from the no-laser potential well.
metrics.FxLaserProxy = base.kx * metrics.dxLaser;
metrics.FyLaserProxy = base.ky * metrics.dyLaser;
metrics.FLaserProxy = hypot(metrics.FxLaserProxy, metrics.FyLaserProxy);
metrics.FLaserOverMg = metrics.FLaserProxy / mg;

metrics.thetaX = 0;
metrics.thetaY = 0;
metrics.thetaMag = 0;
metrics.tauX = 0;
metrics.tauY = 0;
metrics.KthetaX = NaN;
metrics.KthetaY = NaN;
if params.laser.enabled
    tilt = local_estimate_magnetic_tilt(params, active.xMin, active.yMin, params.graphite.z0);
    metrics.thetaX = tilt.thetaX;
    metrics.thetaY = tilt.thetaY;
    metrics.thetaMag = hypot(tilt.thetaX, tilt.thetaY);
    metrics.tauX = tilt.tauX;
    metrics.tauY = tilt.tauY;
    metrics.KthetaX = tilt.KthetaX;
    metrics.KthetaY = tilt.KthetaY;
end

% Complete grid-resolved equilibrium pose lists for export. The displayed maps
% are all at the no-laser vertical equilibrium height, so z is common here.
metrics.posesOff = local_pose_list_from_stable(baseMaps.params, base.stable, params.graphite.z0, false);
metrics.posesOn = local_pose_list_from_stable(params, active.stable, params.graphite.z0, params.laser.enabled);
end

function poses = local_pose_list_from_stable(params, stable, z, includeTilt)
poses = struct('x', [], 'y', [], 'z', [], 'thetaX', [], 'thetaY', [], 'thetaMag', [], 'U', [], 'count', 0);
try, n = stable.count; catch, n = 0; end
if n <= 0
    return;
end
poses.x = stable.x(:).';
poses.y = stable.y(:).';
poses.z = z * ones(1, n);
poses.U = stable.U(:).';
poses.thetaX = zeros(1, n);
poses.thetaY = zeros(1, n);
poses.thetaMag = zeros(1, n);
if includeTilt
    for ii = 1:n
        try
            t = local_estimate_magnetic_tilt(params, poses.x(ii), poses.y(ii), z);
            poses.thetaX(ii) = t.thetaX;
            poses.thetaY(ii) = t.thetaY;
            poses.thetaMag(ii) = t.thetaMag;
        catch
        end
    end
end
poses.count = n;
end

function [zEq, info] = local_solve_vertical_equilibrium(params, x0, y0)
params = validate_graphite_levitation_params(params);
area = graphite_area(params.graphite);
mg = params.graphite.rho * area * params.graphite.thickness * 9.80665;
zGuess = params.graphite.z0;

zLow = max(0.08e-3, 0.08*params.magnet.c);
zLow = min(zLow, 0.20e-3);
zHigh = max(8e-3, 1.2*params.magnet.c);

f = @(z) local_vertical_force_at_position(params, x0, y0, z) - mg;
info = struct('converged', false, 'message', 'not solved', 'FzEq', NaN, 'mg', mg);
try
    fLow = f(zLow);
    fHigh = f(zHigh);
    tries = 0;
    while fHigh > 0 && tries < 3
        zHigh = zHigh * 1.6;
        fHigh = f(zHigh);
        tries = tries + 1;
    end
    if fLow < 0
        zEq = zGuess;
        info.message = 'magnetic force is below weight even near the magnet surface; using input height';
    elseif fHigh > 0
        zEq = zGuess;
        info.message = 'magnetic force remains above weight at the search ceiling; using input height';
    else
        zEq = fzero(f, [zLow zHigh]);
        info.converged = true;
        info.message = 'Fz = mg solved';
    end
catch ME
    zEq = zGuess;
    info.message = ['vertical solver failed: ' ME.message];
end
try
    info.FzEq = local_vertical_force_at_position(params, x0, y0, zEq);
catch
end
end

function Fz = local_vertical_force_at_position(params, x0, y0, z)
q = local_force_distribution(params, x0, y0, z);
Fz = sum(q.fzElem(:));
end

function tilt = local_estimate_magnetic_tilt(params, x0, y0, z)
q = local_force_distribution(params, x0, y0, z);
X = q.Xrel; Y = q.Yrel;
fz = q.fzElem;
dfdz = q.dfdzElem;
valid = q.valid;
% Magnetic torque about sample center from vertical magnetic force elements.
tauX = sum(Y(valid) .* fz(valid));
tauY = -sum(X(valid) .* fz(valid));
% Linearized magnetic restoring torque from local height change under tilt.
KthetaX = -sum((Y(valid).^2) .* dfdz(valid));
KthetaY = -sum((X(valid).^2) .* dfdz(valid));
if ~isfinite(KthetaX) || KthetaX <= 0, KthetaX = params.tilt.torsionalStiffness; end
if ~isfinite(KthetaY) || KthetaY <= 0, KthetaY = params.tilt.torsionalStiffness; end
thetaX = tauX / KthetaX;
thetaY = tauY / KthetaY;
tilt = struct('thetaX', thetaX, 'thetaY', thetaY, 'thetaMag', hypot(thetaX, thetaY), ...
    'tauX', tauX, 'tauY', tauY, 'KthetaX', KthetaX, 'KthetaY', KthetaY);
end

function q = local_force_distribution(params, x0, y0, z)
params = validate_graphite_levitation_params(params);
mu0 = params.numerics.mu0;
N = local_force_kernel_N(params);
extent = graphite_extent(params.graphite) * 1.08;
dx = 2*extent/max(N-1,1);
dy = dx;
[~, info] = build_graphite_chi_kernel(params, dx, dy);
[Xrel, Yrel] = meshgrid(info.x, info.y);
valid = info.mask & isfinite(info.weight);
X = x0 + Xrel;
Y = y0 + Yrel;

magnets = build_compact_checkerboard_magnets(params);
dz = local_force_dz(params);
B0 = evaluate_dipole_field_map(X, Y, z, magnets, params);
Bp = evaluate_dipole_field_map(X, Y, z + dz, magnets, params);
Bm = evaluate_dipole_field_map(X, Y, max(z - dz, 1e-6), magnets, params);
B20 = B0.Bx.^2 + B0.By.^2 + B0.Bz.^2;
B2p = Bp.Bx.^2 + Bp.By.^2 + Bp.Bz.^2;
B2m = Bm.Bx.^2 + Bm.By.^2 + Bm.Bz.^2;
dB2dz = (B2p - B2m) / (2*dz);
d2B2dz2 = (B2p - 2*B20 + B2m) / (dz^2);
coef = params.graphite.chiAbs * params.graphite.thickness / (2*mu0);
dA = dx * dy;
W = info.weight .* double(info.mask);
fzElem = -coef .* W .* dB2dz * dA;
dfdzElem = -coef .* W .* d2B2dz2 * dA;
fzElem(~valid) = 0;
dfdzElem(~valid) = 0;
q = struct('Xrel', Xrel, 'Yrel', Yrel, 'valid', valid, 'fzElem', fzElem, 'dfdzElem', dfdzElem);
end

function N = local_force_kernel_N(params)
N = 55;
try
    if isfield(params.numerics, 'forceKernelN')
        N = params.numerics.forceKernelN;
    end
catch
end
N = max(25, round(N));
if mod(N,2)==0, N = N+1; end
end

function dz = local_force_dz(params)
dz = 0.035e-3;
try
    if isfield(params.numerics, 'forceDz')
        dz = params.numerics.forceDz;
    end
catch
end
dz = max(dz, 5e-6);
end

function Z = local_norm_by_max(Z)
vals = Z(isfinite(Z));
if isempty(vals), m = 0; else, m = max(vals(:)); end
if isfinite(m) && m > 0
    Z = Z ./ m;
end
end
