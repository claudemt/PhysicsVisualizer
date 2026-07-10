function sol = solve_rect_ritz_general(nu, k, n, a, b, boundary)
%SOLVE_RECT_RITZ_GENERAL General rectangular plate Ritz solver.
% Boundary code order: ULDR = up, left, down, right.
% C = clamped, S = simply supported, F = free.
%
% Essential conditions are built into the trial space:
%   S -> w = 0 on that edge
%   C -> w = 0 and \partial_n w = 0 on that edge
% Free and the natural parts of S/C are handled variationally.
% For FFFF, the rigid-body modes {1, x, y} are projected out.

if nargin < 4 || isempty(a), a = 2.0; end
if nargin < 5 || isempty(b), b = 2.0; end
if nargin < 6 || isempty(boundary), boundary = 'FFFF'; end

meta = rect_boundary_meta(boundary);

pStart = max(8, ceil(2*sqrt(k)) + 4);
pStop = 20;
sol = [];
for pMax = pStart:2:pStop
    sol = solve_once(nu, k, n, a, b, meta, pMax);
    if numel(sol.lamDisp) >= k || pMax == pStop
        break;
    end
end

if isempty(sol) || isempty(sol.lamDisp)
    error('Rectangular Ritz solver produced no valid eigenvalues for %s.', meta.code);
end
end

function sol = solve_once(nu, k, n, a, b, meta, pMax)
Nq = max(2*pMax + 2*max_edge_power(meta) + 10, 40);
[xq, wq] = gauss_legendre_rule(Nq);
[P, dP, d2P] = legendre_family_eval(pMax, xq);

[Fx, dFx, d2Fx] = constrained_family_1d(xq, P, dP, d2P, meta.left, meta.right);
[Fy, dFy, d2Fy] = constrained_family_1d(xq, P, dP, d2P, meta.bottom, meta.top);

Ix00 = weighted_gram(Fx, Fx, wq);
Ix11 = weighted_gram(dFx, dFx, wq);
Ix22 = weighted_gram(d2Fx, d2Fx, wq);
Ix20 = weighted_cross(d2Fx, Fx, wq);
Ix02 = Ix20.';

Iy00 = weighted_gram(Fy, Fy, wq);
Iy11 = weighted_gram(dFy, dFy, wq);
Iy22 = weighted_gram(d2Fy, d2Fy, wq);
Iy20 = weighted_cross(d2Fy, Fy, wq);
Iy02 = Iy20.';

sx = 2 / a;
sy = 2 / b;
areaScale = a * b / 4;

M = areaScale * kron(Ix00, Iy00);
K = areaScale * ( ...
    sx^4 * kron(Ix22, Iy00) + ...
    sy^4 * kron(Ix00, Iy22) + ...
    nu * sx^2 * sy^2 * (kron(Ix20, Iy02) + kron(Ix02, Iy20)) + ...
    2 * (1 - nu) * sx^2 * sy^2 * kron(Ix11, Iy11));

M = (M + M.') / 2;
K = (K + K.') / 2;

reg = 1e-13 * trace(M) / max(size(M,1), 1);
S = chol(M + reg * eye(size(M)), 'lower');
A = S \ (K / S.');
A = (A + A.') / 2;

if meta.is_all_free
    A = project_free_rigid_modes(A, S, pMax);
end

A = (A + A.') / 2;
[Vr, Dr] = eig(A, 'vector');
lamOp = real(Dr(:));
good = isfinite(lamOp) & (lamOp > 1e-9);
lamOp = lamOp(good);
Vr = Vr(:, good);
[lamOp, ord] = sort(lamOp, 'ascend');
Vr = Vr(:, ord);

kUse = min(k, numel(lamOp));
if kUse < 1
    sol = struct('x', [], 'y', [], 'modesU', {{}}, 'lamDisp', []);
    return;
end

[Nx, Ny, x, y] = rect_plot_vectors(a, b, n);
xiGrid = 2 * x / a;
etaGrid = 2 * y / b;
[Px, dPx, d2Px] = legendre_family_eval(pMax, xiGrid(:));
[Py, dPy, d2Py] = legendre_family_eval(pMax, etaGrid(:));
[Fxg, ~, ~] = constrained_family_1d(xiGrid(:), Px, dPx, d2Px, meta.left, meta.right);
[Fyg, ~, ~] = constrained_family_1d(etaGrid(:), Py, dPy, d2Py, meta.bottom, meta.top);

if meta.is_all_free
    [Yperp, Skeep] = projected_subspace(S, pMax);
end

modesU = cell(1, kUse);
modeTags = cell(1, kUse);
lamDisp = sqrt(max(lamOp(1:kUse), 0));
for j = 1:kUse
    if meta.is_all_free
        coeffVec = Skeep.' \ (Yperp * Vr(:,j)); %#ok<MINV>
    else
        coeffVec = S.' \ Vr(:,j); %#ok<MINV>
    end
    C = reshape(coeffVec, pMax+1, pMax+1);
    U = real(Fyg * C * Fxg.');
    U = canonicalize_mode(U);
    utol = 1e-12 * max(1, max(abs(U(:)), [], 'omitnan'));
    U(abs(U) < utol) = 0;
    modesU{j} = U;
    modeTags{j} = sprintf('mode%d', j);
end

sol = struct('x', x, 'y', y, 'modesU', {modesU}, 'lamDisp', lamDisp(:).', 'modeTags', {modeTags}, ...
    'a', a, 'b', b, 'Nx', Nx, 'Ny', Ny, 'basis_order', pMax, 'boundary', meta.code);
end

function Ared = project_free_rigid_modes(A, S, pMax)
[Yperp, ~] = projected_subspace(S, pMax);
Ared = Yperp.' * A * Yperp;
Ared = (Ared + Ared.') / 2;
end

function [Yperp, Skeep] = projected_subspace(S, pMax)
n1 = pMax + 1;
idx00 = sub2ind([n1 n1], 1, 1);
idx10 = sub2ind([n1 n1], 1, 2);
idx01 = sub2ind([n1 n1], 2, 1);
Z = zeros(n1*n1, 3);
Z(idx00,1) = 1;
Z(idx10,2) = 1;
Z(idx01,3) = 1;
Yz = S.' * Z;
Qz = orth(Yz);
Yperp = null(Qz.');
Skeep = S;
end

function [F, dF, d2F] = constrained_family_1d(x, P, dP, d2P, kindMinus, kindPlus)
[pMinus, pPlus] = edge_powers(kindMinus, kindPlus);
[g, dg, d2g] = edge_factor(x, pMinus, pPlus);
F = g .* P;
dF = dg .* P + g .* dP;
d2F = d2g .* P + 2 * dg .* dP + g .* d2P;
end

function [pMinus, pPlus] = edge_powers(kindMinus, kindPlus)
pMinus = essential_power(kindMinus);
pPlus = essential_power(kindPlus);
end

function p = essential_power(kind)
switch upper(kind)
    case 'F'
        p = 0;
    case 'S'
        p = 1;
    case 'C'
        p = 2;
    otherwise
        error('Unknown boundary kind: %s', kind);
end
end

function [g, dg, d2g] = edge_factor(x, pMinus, pPlus)
x = x(:);
A = (1 + x) .^ pMinus;
B = (1 - x) .^ pPlus;
g = A .* B;

if pMinus > 0
    dA = pMinus * (1 + x) .^ (pMinus - 1);
else
    dA = zeros(size(x));
end
if pPlus > 0
    dB = -pPlus * (1 - x) .^ (pPlus - 1);
else
    dB = zeros(size(x));
end
if pMinus > 1
    d2A = pMinus * (pMinus - 1) * (1 + x) .^ (pMinus - 2);
else
    d2A = zeros(size(x));
end
if pPlus > 1
    d2B = pPlus * (pPlus - 1) * (1 - x) .^ (pPlus - 2);
else
    d2B = zeros(size(x));
end

dg = dA .* B + A .* dB;
d2g = d2A .* B + 2 * dA .* dB + A .* d2B;
end

function p = max_edge_power(meta)
p = max([essential_power(meta.top), essential_power(meta.left), ...
    essential_power(meta.bottom), essential_power(meta.right)]);
end

function G = weighted_gram(A, B, w)
G = A.' * (w(:) .* B);
G = (G + G.') / 2;
end

function G = weighted_cross(A, B, w)
G = A.' * (w(:) .* B);
end

function [x, w] = gauss_legendre_rule(n)
if n < 1
    error('Quadrature order must be positive.');
end
beta = 0.5 ./ sqrt(1 - (2*(1:n-1)).^(-2));
T = diag(beta,1) + diag(beta,-1);
[V, D] = eig(T);
x = diag(D);
[x, ord] = sort(x, 'ascend');
V = V(:, ord);
w = 2 * (V(1,:).^2).';
end

function [P, dP, d2P] = legendre_family_eval(pMax, x)
x = x(:);
N = numel(x);
P = zeros(N, pMax+1);
dP = zeros(N, pMax+1);
d2P = zeros(N, pMax+1);
P(:,1) = 1;
if pMax >= 1
    P(:,2) = x;
    dP(:,2) = 1;
end
for n = 1:pMax-1
    P(:,n+2) = ((2*n+1) * x .* P(:,n+1) - n * P(:,n)) / (n+1);
end

mask = abs(1 - x.^2) > 1e-12;
for n = 1:pMax
    pn = P(:,n+1);
    pnm1 = P(:,n);
    d = zeros(N,1);
    d(mask) = n * (pnm1(mask) - x(mask).*pn(mask)) ./ (1 - x(mask).^2);
    if any(~mask)
        xm = x(~mask);
        d(~mask) = 0.5 * n * (n + 1) .* (xm .^ (n-1));
    end
    dP(:,n+1) = d;
end
for n = 0:pMax
    if n <= 1
        d2P(:,n+1) = 0;
        continue;
    end
    pn = P(:,n+1);
    d = dP(:,n+1);
    d2 = zeros(N,1);
    d2(mask) = (2*x(mask).*d(mask) - n*(n+1)*pn(mask)) ./ (1 - x(mask).^2);
    d2(~mask) = 0.25 * (n-1) * n * (n+1) * (n+2) .* (x(~mask).^(max(n-2,0)));
    d2P(:,n+1) = d2;
end
end

function U = canonicalize_mode(U)
[~, idx] = max(abs(U(:)));
if isempty(idx) || abs(U(idx)) < eps
    return;
end
if U(idx) < 0
    U = -U;
end
end

function [Nx, Ny, x, y] = rect_plot_vectors(a, b, n)
longN = max(241, 2*round(n) + 1);
longN = max(longN, 81);
if a >= b
    Nx = longN;
    Ny = max(81, 2*floor(((b/a)*(Nx-1))/2) + 1);
else
    Ny = longN;
    Nx = max(81, 2*floor(((a/b)*(Ny-1))/2) + 1);
end
x = linspace(-a/2, a/2, Nx);
y = linspace(-b/2, b/2, Ny);
end
