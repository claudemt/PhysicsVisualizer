function result = compute_static_circ_green(nu, n, boundary, xi0, loadSpec, mMax, D, drawZeroContour, distributionSamples)
%STATIC_SOURCE_CIRC_GREEN Static response of disks/annuli by polar Green sums.
%
% Point loads are summed directly. Smooth distributed loads are projected onto
% polar shells. For each shell and Fourier order, the radial Green solve is
% reused after collecting angular Fourier moments of q.

if nargin < 9 || isempty(distributionSamples), distributionSamples = 28; end
if nargin < 8 || isempty(drawZeroContour), drawZeroContour = true; end
if nargin < 7 || isempty(D), D = 1.0; end
if nargin < 6 || isempty(mMax), mMax = 50; end
if nargin < 5 || isempty(loadSpec), loadSpec = struct('type','points','sources',[0.35 0 1 0]); end
if nargin < 4 || isempty(xi0), xi0 = 0; end
if nargin < 3 || isempty(boundary), boundary = 'C'; end

isAnnulus = xi0 > 0;
if isAnnulus
    bcTag = parse_annulus_boundary_static(boundary);
    outerType = bcTag(1); innerType = bcTag(2);
    if outerType == 'F' && innerType == 'F'
        error(['The static Green function for an FF annulus is not unique. ', ...
            'Add a gauge/balancing reactions before using static FF.']);
    end
else
    bcTag = parse_disk_boundary_static(boundary);
    outerType = bcTag(1); innerType = 'R'; xi0 = 0;
    if outerType == 'F'
        error(['The static Green function for a free disk is not unique. ', ...
            'Use C/S or add balancing reactions and a rigid-mode gauge.']);
    end
end

R = 1.0;
nRender = max(240, round(n));
x = linspace(-R, R, nRender);
y = x;
[X, Y] = meshgrid(x, y);
RR = hypot(X, Y);
TH = atan2(Y, X);
mask = (RR <= R + 1e-12) & (RR >= xi0*R - 1e-12);
xi = RR / R;
xi_vec = xi(mask);
th_vec = TH(mask);
U = nan(size(X));
U(mask) = 0;

pointSources = point_sources_only(loadSpec);
for s = 1:size(pointSources,1)
    xs = pointSources(s,1); ys = pointSources(s,2); P = pointSources(s,3); sig = pointSources(s,4);
    if abs(P) <= eps, continue; end
    if sig > 0
        warning('Circular sigma>0 source is treated as a point at its center; use custom q(X,Y) for a resolved Gaussian patch.');
    end
    eta = hypot(xs, ys) / R;
    theta0 = atan2(ys, xs);
    if eta <= xi0 + 1e-8 || eta >= 1 - 1e-8
        continue;
    end
    add_vec = zeros(size(xi_vec));
    for m = 0:mMax
        gm = radial_green_static_values(xi_vec, eta, m, nu, outerType, innerType, xi0, isAnnulus);
        if m == 0
            add_vec = add_vec + (1/(2*pi)) .* gm;
        else
            add_vec = add_vec + (cos(m * (th_vec - theta0)) / pi) .* gm;
        end
    end
    U(mask) = U(mask) + (P * R^2 / D) * add_vec;
end

shells = distributed_shell_loads(loadSpec, xi0, distributionSamples, mMax);
if ~isempty(shells.eta)
    U(mask) = U(mask) + (R^2 / D) * shell_green_sum(xi_vec, th_vec, shells, mMax, nu, outerType, innerType, xi0, isAnnulus);
end


result = struct();
result.x = x; result.y = y; result.U = U; result.mask = mask;
result.sources = pointSources; result.loadSpec = loadSpec;
result.method = 'accelerated polar biharmonic Green function with shell Fourier moments';
result.shells = shells;
result.boundary = bcTag;
result.xi0 = xi0;
result.drawZeroContour = drawZeroContour;
end

function S = point_sources_only(loadSpec)
S = zeros(0,4);
lt = lower(char(string(loadSpec.type)));
if any(strcmp(lt, {'points','mixed'})) && isfield(loadSpec, 'sources') && ~isempty(loadSpec.sources)
    S = loadSpec.sources;
end
end

function shells = distributed_shell_loads(loadSpec, xi0, nSamples, mMax)
shells = struct('eta', [], 'theta', [], 'weights', []);
lt = lower(char(string(loadSpec.type)));
if ~any(strcmp(lt, {'uniform','custom','mixed'}))
    return;
end

nr = max(8, round(nSamples));
nth = max([48, 2*round(mMax)+3, 4*nr]);
rEdges = linspace(xi0, 1, nr+1);
theta = (0:nth-1) * (2*pi/nth) + pi/nth;
dtheta = 2*pi/nth;
eta = zeros(nr,1);
weights = zeros(nr, nth);

for i = 1:nr
    r1 = rEdges(i); r2 = rEdges(i+1);
    rc = sqrt(0.5*(r1^2 + r2^2));
    dA_r = 0.5*(r2^2 - r1^2);
    eta(i) = rc;
    X = rc .* cos(theta);
    Y = rc .* sin(theta);
    q = zeros(1, nth);
    if any(strcmp(lt, {'uniform','mixed'}))
        q = q + loadSpec.q0;
    end
    if any(strcmp(lt, {'custom','mixed'})) && isfield(loadSpec, 'load_function') && ~isempty(loadSpec.load_function)
        qc = evaluate_custom_load(loadSpec.load_function, X, Y, true(size(X)));
        if isscalar(qc)
            qc = qc + zeros(1, nth);
        end
        if ~isequal(size(qc), size(X))
            qc = reshape(qc, size(X));
        end
        q = q + qc;
    end
    weights(i,:) = q .* dA_r .* dtheta;
end

keep = eta > xi0 + 1e-10 & eta < 1 - 1e-10 & any(abs(weights) > 0, 2);
shells.eta = eta(keep);
shells.theta = theta;
shells.weights = weights(keep,:);
end

function q = evaluate_custom_load(fun, X, Y, mask)
if nargin < 4 || isempty(mask), mask = true(size(X)); end
try
    if nargin(fun) >= 3 || nargin(fun) < 0
        q = fun(X, Y, mask);
    else
        q = fun(X, Y);
    end
catch ME
    error('Failed to evaluate custom q(X,Y) load: %s', ME.message);
end
end

function Uvec = shell_green_sum(xi_vec, th_vec, shells, mMax, nu, outerType, innerType, xi0, isAnnulus)
Uvec = zeros(size(xi_vec));
cos_cache = cell(mMax,1);
sin_cache = cell(mMax,1);
for ir = 1:numel(shells.eta)
    eta = shells.eta(ir);
    wrow = shells.weights(ir,:);
    if ~any(abs(wrow) > 0), continue; end
    for m = 0:mMax
        if m == 0
            moment0 = sum(wrow);
            if abs(moment0) < eps * max(1, sum(abs(wrow)))
                continue;
            end
            gm = radial_green_static_values(xi_vec, eta, m, nu, outerType, innerType, xi0, isAnnulus);
            Uvec = Uvec + (moment0/(2*pi)) .* gm;
        else
            C = sum(wrow .* cos(m * shells.theta));
            S = sum(wrow .* sin(m * shells.theta));
            if abs(C) + abs(S) < eps * max(1, sum(abs(wrow)))
                continue;
            end
            gm = radial_green_static_values(xi_vec, eta, m, nu, outerType, innerType, xi0, isAnnulus);
            if isempty(cos_cache{m})
                cos_cache{m} = cos(m * th_vec);
                sin_cache{m} = sin(m * th_vec);
            end
            angular = (C .* cos_cache{m} + S .* sin_cache{m}) / pi;
            Uvec = Uvec + gm .* angular;
        end
    end
end
end

function g = radial_green_static_values(xiVec, eta, m, nu, outerType, innerType, xi0, isAnnulus)
fullTerms = static_basis_terms(m, false);
if isAnnulus
    innerRows = boundary_rows_static(innerType, xi0, m, nu, fullTerms);
    A = null(innerRows);
    innerTerms = fullTerms;
else
    innerTerms = static_basis_terms(m, true);
    A = eye(numel(innerTerms.p));
end
outerRows = boundary_rows_static(outerType, 1.0, m, nu, fullTerms);
B = null(outerRows);
if size(A,2) ~= 2 || size(B,2) ~= 2
    error('Boundary-adapted Green basis has unexpected dimension for m=%d.', m);
end
Ui = eval_boundary_block(eta, m, nu, innerTerms) * A;
Vo = eval_boundary_block(eta, m, nu, fullTerms) * B;
H = [-Ui, Vo];
rhs = [0; 0; 0; 1/eta];
if rcond(H) < 1e-12, coeff = pinv(H) * rhs; else, coeff = H \ rhs; end
alpha = coeff(1:2); beta = coeff(3:4);
g = zeros(size(xiVec));
left = xiVec <= eta;
if any(left)
    Wleft = eval_W_row(xiVec(left), innerTerms) * A;
    g(left) = Wleft * alpha;
end
if any(~left)
    Wright = eval_W_row(xiVec(~left), fullTerms) * B;
    g(~left) = Wright * beta;
end
end

function block = eval_boundary_block(xi, m, nu, terms)
[W, T, M, V] = eval_all_rows(xi, m, nu, terms);
block = [W; T; M; V];
end

function rows = boundary_rows_static(edgeType, xi, m, nu, terms)
[W, T, M, V] = eval_all_rows(xi, m, nu, terms);
switch upper(edgeType)
    case 'C', rows = [W; T];
    case 'S', rows = [W; M];
    case 'F', rows = [M; V];
    otherwise, error('Unknown circular boundary type: %s', edgeType);
end
end

function W = eval_W_row(xi, terms)
[W, ~, ~, ~] = eval_terms_and_derivatives(xi, terms);
end

function [W, T, M, V] = eval_all_rows(xi, m, nu, terms)
[W, T, D2, D3] = eval_terms_and_derivatives(xi, terms);
xi = xi(:);
DeltaPrime = D3 + D2 ./ xi - (1 + m^2) * T ./ (xi.^2) + 2*m^2 * W ./ (xi.^3);
M = D2 + nu * (T ./ xi - m^2 * W ./ (xi.^2));
V = DeltaPrime - (1-nu) * m^2 * (T - W ./ xi) ./ (xi.^2);
end

function [F, D1, D2, D3] = eval_terms_and_derivatives(xi, terms)
xi = xi(:); nb = numel(terms.p);
F = zeros(numel(xi), nb); D1 = F; D2 = F; D3 = F;
for j = 1:nb
    p = terms.p(j); useLog = terms.log(j);
    if useLog
        L = log(xi); xp = xi.^p;
        F(:,j) = xp .* L;
        D1(:,j) = p * xi.^(p-1) .* L + xi.^(p-1);
        D2(:,j) = p*(p-1) * xi.^(p-2) .* L + (2*p-1) * xi.^(p-2);
        D3(:,j) = p*(p-1)*(p-2) * xi.^(p-3) .* L + (3*p^2 - 6*p + 2) * xi.^(p-3);
    else
        F(:,j) = xi.^p;
        D1(:,j) = p * xi.^(p-1);
        D2(:,j) = p*(p-1) * xi.^(p-2);
        D3(:,j) = p*(p-1)*(p-2) * xi.^(p-3);
    end
end
end

function terms = static_basis_terms(m, regularOnly)
if regularOnly
    if m == 0
        terms.p = [0 2]; terms.log = [false false];
    elseif m == 1
        terms.p = [1 3]; terms.log = [false false];
    else
        terms.p = [m m+2]; terms.log = [false false];
    end
else
    if m == 0
        terms.p = [0 0 2 2]; terms.log = [false true false true];
    elseif m == 1
        terms.p = [1 -1 3 1]; terms.log = [false false false true];
    else
        terms.p = [m -m m+2 2-m]; terms.log = [false false false false];
    end
end
end

function bcTag = parse_disk_boundary_static(boundary)
s = upper(strtrim(char(string(boundary))));
switch s
    case {'C','CLAMPED','CLAMP'}, bcTag = 'C';
    case {'S','SIMPLY','SIMPLY_SUPPORTED','PINNED'}, bcTag = 'S';
    case {'F','FREE'}, bcTag = 'F';
    otherwise, error('Disk boundary must be C, S, or F.');
end
end

function bcTag = parse_annulus_boundary_static(boundary)
s = upper(strtrim(char(string(boundary))));
if strlength(string(s)) ~= 2 || any(~ismember(s, 'CSF'))
    error('Annulus boundary must be an outer-inner two-letter code in {C,S,F}^2.');
end
bcTag = s;
end


function label = plain_load_label(loadSpec)
switch lower(char(string(loadSpec.type)))
    case 'points', label = 'point';
    case 'uniform', label = 'uniform';
    case 'custom', label = 'custom';
    otherwise, label = 'mixed';
end
end

function tag = sanitize_tag(s)
tag = lower(regexprep(char(string(s)), '[^a-zA-Z0-9]+', ''));
if isempty(tag), tag = 'load'; end
end

function tag = local_num_tag(x)
% Match the eigenmode export convention: keep the decimal point in
% numeric tags, e.g. 0.225 instead of 0p225.  The file extension is
% appended separately by the caller, so internal decimal points are safe.
tag = sprintf('%.6g', x);
end
