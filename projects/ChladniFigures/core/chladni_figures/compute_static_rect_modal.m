function result = compute_static_rect_modal(nu, n, boundary, a, b, loadSpec, kModes, D, drawZeroContour)
%STATIC_SOURCE_RECT_MODAL Modal/Ritz static response for rectangular plates.
%
% Computes D*nabla^4 w = q with a truncated static modal expansion
%   w ~= sum_j phi_j <q,phi_j> / (D*lambda_j*<phi_j,phi_j>).
% The same rectangular eigen-solvers used by the Chladni renderer are reused
% here, so the original boundary-code and display conventions are preserved.

if nargin < 9 || isempty(drawZeroContour), drawZeroContour = true; end
if nargin < 8 || isempty(D), D = 1.0; end
if nargin < 7 || isempty(kModes), kModes = 80; end
if nargin < 6 || isempty(loadSpec), loadSpec = struct('type','points','sources',[0 0 1 0]); end
if nargin < 5 || isempty(b), b = 1.0; end
if nargin < 4 || isempty(a), a = 2.0; end
if nargin < 3 || isempty(boundary), boundary = 'SSSS'; end

meta = rect_boundary_meta(boundary);
if meta.is_all_simply
    sol = solve_rect_navier_ssss(kModes, n, a, b);
else
    sol = solve_rect_ritz_general(nu, kModes, n, a, b, meta.code);
end

x = sol.x(:).';
y = sol.y(:);
[X, Y] = meshgrid(x, y);
Qdist = distributed_load_rect(X, Y, loadSpec);
Ustatic = zeros(numel(y), numel(x));
modalWeights = zeros(1, numel(sol.modesU));

for j = 1:numel(sol.modesU)
    Phi = sol.modesU{j};
    if isempty(Phi) || j > numel(sol.lamDisp), continue; end

    % Existing solvers report a frequency-like display value.  For static
    % flexibility we need the biharmonic eigenvalue.  The project convention
    % is lamDisp = sqrt(Lambda) for most Ritz paths, hence Lambda=lamDisp^2.
    lambda_j = sol.lamDisp(j)^2;
    if ~isfinite(lambda_j) || lambda_j <= 1e-12, continue; end

    norm_j = trapz(y, trapz(x, Phi.^2, 2));
    if ~isfinite(norm_j) || norm_j <= 1e-14, continue; end

    qproj = trapz(y, trapz(x, Qdist .* Phi, 2));
    qproj = qproj + point_source_projection_rect(x, y, X, Y, Phi, loadSpec);

    coeff = qproj / (D * lambda_j * norm_j);
    modalWeights(j) = coeff;
    Ustatic = Ustatic + coeff * Phi;
end

compat = rect_static_compatibility(meta, loadSpec, x, y, Qdist);
if meta.is_all_free && (~compat.force || ~compat.moment_x || ~compat.moment_y)
    warning(['Static response for FFFF is a pseudo-static response in the ', ...
        'orthogonal complement of rigid modes. A physically free plate needs ', ...
        'zero resultant force and zero resultant moments.']);
end


result = struct();
result.x = x;
result.y = y;
result.U = Ustatic;
result.Q = Qdist;
result.loadSpec = loadSpec;
result.modalWeights = modalWeights;
result.compatibility = compat;
result.method = 'rectangular modal/Ritz static summation';
result.drawZeroContour = drawZeroContour;
result.boundary = meta.code;
result.xi0 = b / a;
end

function Q = distributed_load_rect(X, Y, loadSpec)
Q = zeros(size(X));
lt = lower(char(string(loadSpec.type)));
if any(strcmp(lt, {'uniform','mixed'}))
    Q = Q + loadSpec.q0 * ones(size(X));
end
if any(strcmp(lt, {'custom','mixed'})) && isfield(loadSpec, 'load_function') && ~isempty(loadSpec.load_function)
    Qcustom = evaluate_custom_load(loadSpec.load_function, X, Y, true(size(X)));
    if isscalar(Qcustom), Qcustom = Qcustom + zeros(size(X)); end
    if ~isequal(size(Qcustom), size(X))
        error('load_function must return either a scalar or an array of the same size as X,Y.');
    end
    Q = Q + Qcustom;
end
if any(strcmp(lt, {'points','mixed'})) && isfield(loadSpec, 'sources') && ~isempty(loadSpec.sources)
    S = loadSpec.sources;
    x = X(1,:); y = Y(:,1);
    for s = 1:size(S,1)
        sig = S(s,4);
        if sig > 0
            xs = S(s,1); ys = S(s,2); P = S(s,3);
            G = exp(-((X-xs).^2 + (Y-ys).^2) / (2*sig^2));
            total = trapz(y, trapz(x, G, 2));
            if total > 0, Q = Q + (P / total) * G; end
        end
    end
end
end


function Q = evaluate_custom_load(fun, X, Y, mask)
if nargin < 4 || isempty(mask), mask = true(size(X)); end
try
    if nargin(fun) >= 3 || nargin(fun) < 0
        Q = fun(X, Y, mask);
    else
        Q = fun(X, Y);
    end
catch ME
    error('Failed to evaluate custom q(X,Y) load: %s', ME.message);
end
end

function val = load_field_default(s, name, defaultVal)
if isfield(s, name) && ~isempty(s.(name))
    val = s.(name);
else
    val = defaultVal;
end
end

function qproj = point_source_projection_rect(x, y, X, Y, Phi, loadSpec)
qproj = 0;
if ~isfield(loadSpec, 'sources') || isempty(loadSpec.sources), return; end
if ~any(strcmp(lower(char(string(loadSpec.type))), {'points','mixed'})), return; end
S = loadSpec.sources;
for s = 1:size(S,1)
    xs = S(s,1); ys = S(s,2); P = S(s,3); sig = S(s,4);
    if sig <= 0
        phi_at_source = interp2(X, Y, Phi, xs, ys, 'linear', 0);
        qproj = qproj + P * phi_at_source;
    end
end
end

function compat = rect_static_compatibility(meta, loadSpec, x, y, Qdist)
[X, Y] = meshgrid(x, y);
Pdist = trapz(y, trapz(x, Qdist, 2));
Mxdist = trapz(y, trapz(x, Qdist .* Y, 2));
Mydist = trapz(y, trapz(x, Qdist .* X, 2));
Psrc = 0; Mxsrc = 0; Mysrc = 0;
if isfield(loadSpec, 'sources') && ~isempty(loadSpec.sources) && any(strcmp(lower(char(string(loadSpec.type))), {'points','mixed'}))
    S = loadSpec.sources;
    Psrc = sum(S(:,3));
    Mxsrc = sum(S(:,3) .* S(:,2));
    Mysrc = sum(S(:,3) .* S(:,1));
end
P = Pdist + Psrc; Mx = Mxdist + Mxsrc; My = Mydist + Mysrc;
tol = 1e-10 * max(1, abs(Pdist)+abs(Psrc));
compat = struct();
compat.force = abs(P) <= tol;
compat.moment_x = abs(Mx) <= tol;
compat.moment_y = abs(My) <= tol;
compat.is_all_free = meta.is_all_free;
compat.resultant = P;
compat.moment_about_x = Mx;
compat.moment_about_y = My;
end


function label = plain_load_label(loadSpec)
switch lower(char(string(loadSpec.type)))
    case 'points'
        label = 'point';
    case 'uniform'
        label = 'uniform';
    case 'custom'
        label = 'custom';
    otherwise
        label = 'mixed';
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
