function chladni_formula_circ(nu, k, n, normalizeForDisplay, outputFolder, boundary, xi0)
%CHLADNI_FORMULA_CIRC Solid-disk / annulus Chladni modes from analytic boundary systems.
%
% Solid disk:
%   boundary = 'clamped' | 'simply' | 'free'
%   xi0 = 0
%
% Annulus:
%   boundary = two-letter outer-inner code in {cc, cs, cf, sc, ss, sf, fc, fs, ff}
%   xi0 in (0, 1)
%
% Annulus eigenvalues are refined with a two-stage analytic procedure:
%   1) coarse candidate detection from balanced determinant sign changes and
%      smallest-singular-value local minima,
%   2) high-accuracy polishing with fzero / fminbnd on the analytic 4x4 system.
%
% This is noticeably more stable than relying on raw determinant samples alone.

if nargin < 7 || isempty(xi0)
    xi0 = 0;
end
if nargin < 6 || isempty(boundary)
    boundary = 'free';
end
if nargin < 5 || isempty(outputFolder)
    outputFolder = fullfile(pwd, '.cache');
end
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

isAnnulus = xi0 > 0;
if isAnnulus
    if ~isfinite(xi0) || xi0 <= 0 || xi0 >= 1
        error('For annulus runs, xi0 must satisfy 0 < xi0 < 1.');
    end
    bcTag = parse_annulus_boundary(boundary);
else
    bcTag = parse_disk_boundary(boundary);
    xi0 = 0;
end

nuStr = sprintf('%.6g', nu);
xi0Str = sprintf('%.6g', xi0);
a = 1.0;

x = linspace(-a, a, n);
y = x;
[X, Y] = meshgrid(x, y);
Rr = hypot(X, Y);
TH = atan2(Y, X);
mask = (Rr <= a + 1e-12) & (Rr >= xi0*a - 1e-12);
rr = Rr / a;

modes = collect_circular_modes(nu, k, bcTag, xi0);
kUse = min(k, numel(modes));

for i = 1:kUse
    beta = modes(i).beta;
    m = modes(i).m;
    s = modes(i).s;
    coeffs = modes(i).coeffs;

    U = nan(n, n);
    radial = evaluate_radial_mode(beta * rr(mask), beta, m, coeffs, xi0);
    if m > 0
        radial = radial .* cos(m * TH(mask));
    end
    U(mask) = radial;

    fig = figure('Visible', 'off', 'Color', [1 1 1]);
    set(fig, 'InvertHardcopy', 'off');
    set(fig, 'Renderer', 'opengl');
    ax = gca;
    set(ax, 'Color', [1 1 1]);

    [Uf, climVal] = signed_field_for_display(U, normalizeForDisplay);
    UfImg = Uf;
    UfImg(~mask) = 0;
    hImg = imagesc(x, y, UfImg);
    set(ax, 'YDir', 'normal');
    axis(ax, 'equal');
    axis(ax, [-a a -a a]);
    set(hImg, 'AlphaData', double(mask), 'AlphaDataMapping', 'none');

    color_bar(ax, 'Location', 'eastoutside', 'Interpreter', 'latex', 'Limits', [-climVal climVal]);
    hold(ax, 'on');
    contour(x, y, U, [0 0], 'k-', 'LineWidth', 1.0);

    apply_latex_formatting(fig, ax);
    lam_i = beta^2 / a^2;
    modeTag = sprintf('mode%d,%d', m, s);
    if isAnnulus
        title(ax, local_annulus_title(nu, xi0, bcTag, m, s, lam_i), 'Interpreter', 'latex');
        filename = fullfile(outputFolder, sprintf( ...
            'annulus-%s-nu%s-xi%s-%s.png', ...
            upper(bcTag), nuStr, xi0Str, modeTag));
    else
        title(ax, local_circ_title(nu, bcTag, m, s, lam_i), 'Interpreter', 'latex');
        filename = fullfile(outputFolder, sprintf( ...
            'circ-%s-nu%s-xi%s-%s.png', ...
            upper(bcTag), nuStr, xi0Str, modeTag));
    end

    print(fig, '-dpng', filename);
    close(fig);
    end
end

function modes = collect_circular_modes(nu, k, bcTag, xi0)
isAnnulus = xi0 > 0;
maxExpand = 8;
if isAnnulus
    betaMinGlobal = 0.18;
    betaMax = max(40, 18 + 12 * sqrt(k) + 12 * xi0);
    scanStep = 0.02;
    sigmaTol = 1e-9;
else
    betaMinGlobal = 1e-4;
    betaMax = max(30, 15 + 8 * sqrt(k));
    scanStep = 0.02;
    sigmaTol = 1e-10;
end
mMax = max(12, ceil(sqrt(2 * k)) + 8);
modes = struct('beta', {}, 'm', {}, 's', {}, 'coeffs', {});

for expand = 1:maxExpand
    modes = struct('beta', {}, 'm', {}, 's', {}, 'coeffs', {});
    for m = 0:mMax
        betaMinLocal = betaMinGlobal;
        if isAnnulus
            % Near beta = 0, the J/I and Y/K columns become nearly dependent.
            % A mild m-dependent lower cutoff suppresses those quasi-static false roots.
            betaMinLocal = max(betaMinLocal, 0.5 * m);
        end

        sigmaFun = @(beta) local_sigma_min(beta, m, nu, bcTag, xi0);
        detFun = @(beta) local_det_balanced(beta, m, nu, bcTag, xi0);
        roots_m = local_find_analytic_roots(sigmaFun, detFun, betaMinLocal, betaMax, scanStep, sigmaTol);

        for s = 1:numel(roots_m)
            beta = roots_m(s);
            coeffs = local_mode_coeffs(beta, m, nu, bcTag, xi0);
            entry = struct('beta', beta, 'm', m, 's', s, 'coeffs', coeffs);
            modes(end+1) = entry; %#ok<AGROW>
        end
    end

    if numel(modes) >= k
        break;
    end
    betaMax = betaMax * 1.5;
    mMax = mMax + 6;
end

if isempty(modes)
    error('No circular eigen-roots found. Increase the search range or adjust the geometry.');
end

betaVals = reshape([modes.beta], [], 1);
lambdaVals = betaVals .^ 2;
mVals = reshape([modes.m], [], 1);
sVals = reshape([modes.s], [], 1);
sortKeys = [lambdaVals, mVals, sVals];
[~, idxSort] = sortrows(sortKeys, [1 2 3]);
modes = modes(idxSort);

if numel(modes) < k
    % Keep GUI terminal output clean: return the modes found without command-window warnings.
end
end

function coeffs = local_mode_coeffs(beta, m, nu, bcTag, xi0)
M = build_mode_matrix(beta, m, nu, bcTag, xi0);
[Mbal, ~, colScale] = equilibrate_matrix(M);
[~, ~, V] = svd(Mbal, 'econ');
y = V(:, end);
coeffs = y ./ colScale(:);
coeffs = coeffs ./ max(abs(coeffs));
if norm(imag(coeffs)) <= 1e-10 * max(1, norm(real(coeffs)))
    coeffs = real(coeffs);
end
idx = find(abs(coeffs) == max(abs(coeffs)), 1, 'first');
if ~isempty(idx) && real(coeffs(idx)) < 0
    coeffs = -coeffs;
end
end

function sigmaMin = local_sigma_min(beta, m, nu, bcTag, xi0)
if ~isfinite(beta) || beta <= 0
    sigmaMin = Inf;
    return;
end
M = build_mode_matrix(beta, m, nu, bcTag, xi0);
[Mbal, ~, ~] = equilibrate_matrix(M);
s = svd(Mbal, 'econ');
sigmaMin = s(end);
end

function detVal = local_det_balanced(beta, m, nu, bcTag, xi0)
if ~isfinite(beta) || beta <= 0
    detVal = NaN;
    return;
end
M = build_mode_matrix(beta, m, nu, bcTag, xi0);
[Mbal, ~, ~] = equilibrate_matrix(M);
detVal = det(Mbal);
if ~isreal(detVal)
    detVal = real(detVal);
end
end

function roots_out = local_find_analytic_roots(sigFun, detFun, betaMin, betaMax, step, sigmaTol)
if betaMax <= betaMin
    roots_out = [];
    return;
end

grid = betaMin:step:betaMax;
if isempty(grid) || grid(end) < betaMax
    grid(end+1) = betaMax; %#ok<AGROW>
end

sigVals = nan(size(grid));
detVals = nan(size(grid));
for i = 1:numel(grid)
    sigVals(i) = sigFun(grid(i));
    detVals(i) = detFun(grid(i));
end

intervals = zeros(0, 2);
for i = 1:(numel(grid) - 1)
    dL = detVals(i);
    dR = detVals(i + 1);
    if ~(isfinite(dL) && isfinite(dR))
        continue;
    end
    if dL == 0 || dR == 0 || sign(dL) ~= sign(dR)
        intervals(end+1, :) = [grid(i), grid(i + 1)]; %#ok<AGROW>
    end
end

for i = 2:(numel(grid) - 1)
    vPrev = sigVals(i - 1);
    vNow = sigVals(i);
    vNext = sigVals(i + 1);
    if ~(isfinite(vPrev) && isfinite(vNow) && isfinite(vNext))
        continue;
    end
    if vNow <= vPrev && vNow <= vNext
        intervals(end+1, :) = [grid(i - 1), grid(i + 1)]; %#ok<AGROW>
    end
end

intervals = merge_intervals(intervals, step);
roots_out = [];
optsZero = optimset('TolX', 1e-12, 'Display', 'off');
optsMin = optimset('TolX', 1e-12, 'Display', 'off');

for i = 1:size(intervals, 1)
    left = max(betaMin, intervals(i, 1));
    right = min(betaMax, intervals(i, 2));
    if ~(isfinite(left) && isfinite(right)) || right <= left
        continue;
    end

    betaStar = NaN;
    dL = detFun(left);
    dR = detFun(right);
    hasSignBracket = isfinite(dL) && isfinite(dR) && (dL == 0 || dR == 0 || sign(dL) ~= sign(dR));

    if hasSignBracket
        try
            betaStar = fzero(detFun, [left, right], optsZero);
        catch
            betaStar = NaN;
        end
    end

    if ~isfinite(betaStar)
        try
            betaStar = fminbnd(sigFun, left, right, optsMin);
        catch
            betaStar = NaN;
        end
    end

    if ~isfinite(betaStar) || betaStar <= betaMin || betaStar >= betaMax
        continue;
    end

    polishHalfWidth = max(5e-3, 0.75 * step);
    left2 = max(betaMin, betaStar - polishHalfWidth);
    right2 = min(betaMax, betaStar + polishHalfWidth);
    dL2 = detFun(left2);
    dR2 = detFun(right2);
    hasLocalBracket = isfinite(dL2) && isfinite(dR2) && (dL2 == 0 || dR2 == 0 || sign(dL2) ~= sign(dR2));
    if hasLocalBracket
        try
            betaStar = fzero(detFun, [left2, right2], optsZero);
        catch
            % Keep the minimizer if the sign-bracket polish fails.
        end
    else
        try
            betaStar = fminbnd(sigFun, left2, right2, optsMin);
        catch
            % Keep the earlier estimate.
        end
    end

    sigmaStar = sigFun(betaStar);
    if isfinite(sigmaStar) && sigmaStar <= sigmaTol
        roots_out(end+1) = betaStar; %#ok<AGROW>
    end
end

roots_out = local_unique_tol(roots_out, 1e-7);
end

function intervalsOut = merge_intervals(intervalsIn, pad)
if isempty(intervalsIn)
    intervalsOut = intervalsIn;
    return;
end

intervals = sortrows(intervalsIn, 1);
intervalsOut = intervals(1, :);
for i = 2:size(intervals, 1)
    left = intervals(i, 1);
    right = intervals(i, 2);
    lastIdx = size(intervalsOut, 1);
    if left <= intervalsOut(lastIdx, 2) + pad
        intervalsOut(lastIdx, 2) = max(intervalsOut(lastIdx, 2), right);
    else
        intervalsOut(end+1, :) = [left, right]; %#ok<AGROW>
    end
end
end

function vals = local_unique_tol(vals, tol)
if isempty(vals)
    return;
end
vals = sort(vals(:).');
keep = true(size(vals));
for i = 2:numel(vals)
    keep(i) = abs(vals(i) - vals(i - 1)) > tol;
end
vals = vals(keep);
end

function [Mbal, rowScale, colScale] = equilibrate_matrix(M)
rowScale = max(abs(M), [], 2);
rowScale(rowScale < 1) = 1;
Mrow = M ./ rowScale;

colScale = max(abs(Mrow), [], 1);
colScale(colScale < 1) = 1;
Mbal = Mrow ./ colScale;
end

function M = build_mode_matrix(beta, m, nu, bcTag, xi0)
if xi0 > 0
    lambda = beta * xi0;
    outerRows = edge_rows_annulus(bcTag(1), beta, beta, lambda, m, nu);
    innerRows = edge_rows_annulus(bcTag(2), lambda, beta, lambda, m, nu);
    M = [outerRows; innerRows];
else
    M = edge_rows_disk(bcTag, beta, m, nu);
end
end

function rowsOut = edge_rows_disk(edgeType, x, m, nu)
[C0, C1, S, F] = basis_rows_disk(x, m, nu);
switch edgeType
    case 'c'
        rowsOut = [C0; C1];
    case 's'
        rowsOut = [C0; S];
    case 'f'
        rowsOut = [S; F];
    otherwise
        error('Unknown disk edge type: %s', edgeType);
end
end

function rowsOut = edge_rows_annulus(edgeType, x, beta, lambda, m, nu)
[C0, C1, S, F] = basis_rows_annulus(x, beta, lambda, m, nu);
switch edgeType
    case 'c'
        rowsOut = [C0; C1];
    case 's'
        rowsOut = [C0; S];
    case 'f'
        rowsOut = [S; F];
    otherwise
        error('Unknown annulus edge type: %s', edgeType);
end
end

function [C0, C1, S, F] = basis_rows_disk(x, m, nu)
[J, Jd] = local_besselj_pair(m, x);
[I, Id] = local_besseli_pair_scaled_to_outer(m, x, x);

C0 = [J, I];
C1 = [x * Jd, x * Id];
S = [ ...
    x^2 * J + (1 - nu) * (x * Jd - m^2 * J), ...
   -x^2 * I + (1 - nu) * (x * Id - m^2 * I)];
F = [ ...
    x^3 * Jd + m^2 * (1 - nu) * (x * Jd - J), ...
   -x^3 * Id + m^2 * (1 - nu) * (x * Id - I)];
end

function [C0, C1, S, F] = basis_rows_annulus(x, beta, lambda, m, nu)
[J, Jd] = local_besselj_pair(m, x);
[Y, Yd] = local_bessely_pair(m, x);
[I, Id] = local_besseli_pair_scaled_to_outer(m, x, beta);
[K, Kd] = local_besselk_pair_scaled_to_inner(m, x, lambda);

C0 = [J, Y, I, K];
C1 = [x * Jd, x * Yd, x * Id, x * Kd];
S = [ ...
    x^2 * J + (1 - nu) * (x * Jd - m^2 * J), ...
    x^2 * Y + (1 - nu) * (x * Yd - m^2 * Y), ...
   -x^2 * I + (1 - nu) * (x * Id - m^2 * I), ...
   -x^2 * K + (1 - nu) * (x * Kd - m^2 * K)];
F = [ ...
    x^3 * Jd + m^2 * (1 - nu) * (x * Jd - J), ...
    x^3 * Yd + m^2 * (1 - nu) * (x * Yd - Y), ...
   -x^3 * Id + m^2 * (1 - nu) * (x * Id - I), ...
   -x^3 * Kd + m^2 * (1 - nu) * (x * Kd - K)];
end

function radial = evaluate_radial_mode(x, beta, m, coeffs, xi0)
if xi0 > 0
    lambda = beta * xi0;
    basisVals = annulus_basis_columns(x, beta, lambda, m);
else
    basisVals = disk_basis_columns(x, beta, m);
end
radial = basisVals * coeffs;
if norm(imag(radial)) <= 1e-10 * max(1, norm(real(radial)))
    radial = real(radial);
end
end

function B = disk_basis_columns(x, beta, m)
J = besselj(m, x(:));
I = local_besseli_scaled_eval(m, x(:), beta);
B = [J, I];
end

function B = annulus_basis_columns(x, beta, lambda, m)
J = besselj(m, x(:));
Y = bessely(m, x(:));
I = local_besseli_scaled_eval(m, x(:), beta);
K = local_besselk_scaled_eval(m, x(:), lambda);
B = [J, Y, I, K];
end

function bcTag = parse_disk_boundary(boundary)
bc = char(lower(string(boundary)));
switch bc
    case {'clamped', 'c'}
        bcTag = 'c';
    case {'simply', 's'}
        bcTag = 's';
    case {'free', 'f'}
        bcTag = 'f';
    otherwise
        error('Unknown solid-disk boundary condition: %s', boundary);
end
end

function bcTag = parse_annulus_boundary(boundary)
bcTag = char(lower(string(boundary)));
valid = {'cc', 'cs', 'cf', 'sc', 'ss', 'sf', 'fc', 'fs', 'ff'};
if ~any(strcmp(valid, bcTag))
    error('Unknown annulus boundary condition: %s', boundary);
end
end

function [J, Jd] = local_besselj_pair(m, x)
J = besselj(m, x);
if m == 0
    Jd = -besselj(1, x);
else
    Jd = 0.5 * (besselj(m - 1, x) - besselj(m + 1, x));
end
end

function [Y, Yd] = local_bessely_pair(m, x)
Y = bessely(m, x);
if m == 0
    Yd = -bessely(1, x);
else
    Yd = 0.5 * (bessely(m - 1, x) - bessely(m + 1, x));
end
end

function [I, Id] = local_besseli_pair_scaled_to_outer(m, x, beta)
Iscaled = besseli(m, x, 1);
if m == 0
    IdScaled = besseli(1, x, 1);
else
    IdScaled = 0.5 * (besseli(m - 1, x, 1) + besseli(m + 1, x, 1));
end
factor = exp(x - beta);
I = factor .* Iscaled;
Id = factor .* IdScaled;
end

function [K, Kd] = local_besselk_pair_scaled_to_inner(m, x, lambda)
Kscaled = besselk(m, x, 1);
if m == 0
    KdScaled = -besselk(1, x, 1);
else
    KdScaled = -0.5 * (besselk(m - 1, x, 1) + besselk(m + 1, x, 1));
end
factor = exp(lambda - x);
K = factor .* Kscaled;
Kd = factor .* KdScaled;
end

function I = local_besseli_scaled_eval(m, x, beta)
I = exp(x - beta) .* besseli(m, x, 1);
end

function K = local_besselk_scaled_eval(m, x, lambda)
K = exp(lambda - x) .* besselk(m, x, 1);
end

function txt = local_annulus_title(nu, xi0, bcTag, m, s, lambdaVal)
txt = sprintf('$\\nu=%.6g,\\ \\xi_0=%.6g,\\ %s\\ (m=%d,\\ s=%d),\\ \\Lambda=%.4g$', ...
    nu, xi0, upper(bcTag), m, s, lambdaVal);
end

function txt = local_circ_title(nu, bcTag, m, s, lambdaVal)
txt = sprintf('$\\nu=%.6g,\\ %s\\ (m=%d,\\ s=%d),\\ \\Lambda=%.4g$', ...
    nu, upper(bcTag), m, s, lambdaVal);
end
