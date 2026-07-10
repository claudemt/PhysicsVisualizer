function sol = solve_rect_free_ritz_general(nu, k, n, a, b)
%SOLVE_RECT_FREE_RITZ_GENERAL Free-free rectangular plate via a Ritz basis.
% The three rigid-body modes {1, x, y} are removed by projection.

if nargin < 4 || isempty(a), a = 2.0; end
if nargin < 5 || isempty(b), b = 2.0; end

pStart = max(8, ceil(2*sqrt(k)) + 4);
pStop = 22;
sol = [];
for pMax = pStart:2:pStop
    sol = solve_once(nu, k, n, a, b, pMax);
    if numel(sol.lamDisp) >= k || pMax == pStop
        break;
    end
end

if isempty(sol) || isempty(sol.lamDisp)
    error('FFFF Ritz solver produced no valid bending eigenvalues.');
end
end

function sol = solve_once(nu, k, n, a, b, pMax)
[nBasis, pairs] = tensor_basis_pairs(pMax);
Nq = max(2*pMax + 8, 36);
[xq, wq] = gauss_legendre_rule(Nq);
[P, dP, d2P] = legendre_family_eval(pMax, xq);

sx = a / 2;
sy = b / 2;

I00 = weighted_gram_sym(P, P, wq);
I11 = weighted_gram_sym(dP, dP, wq);
I22 = weighted_gram_sym(d2P, d2P, wq);
I20 = weighted_cross(d2P, P, wq);
I02 = I20.';

K = zeros(nBasis, nBasis);
M = zeros(nBasis, nBasis);
for i = 1:nBasis
    pi = pairs(i,1) + 1;
    qi = pairs(i,2) + 1;
    for j = i:nBasis
        pj = pairs(j,1) + 1;
        qj = pairs(j,2) + 1;

        mass_ij = sx * sy * I00(pi,pj) * I00(qi,qj);
        k_xx = (sy / sx^3) * I22(pi,pj) * I00(qi,qj);
        k_yy = (sx / sy^3) * I00(pi,pj) * I22(qi,qj);
        k_xy = (1 / (sx * sy)) * I11(pi,pj) * I11(qi,qj);
        k_cpl = (nu / (sx * sy)) * (I20(pi,pj) * I02(qi,qj) + I02(pi,pj) * I20(qi,qj));
        stiff_ij = k_xx + k_yy + 2*(1-nu)*k_xy + k_cpl;

        M(i,j) = mass_ij;
        K(i,j) = stiff_ij;
        if j ~= i
            M(j,i) = mass_ij;
            K(j,i) = stiff_ij;
        end
    end
end

M = (M + M.') / 2;
K = (K + K.') / 2;
reg = 1e-13 * trace(M) / max(size(M,1),1);
S = chol(M + reg*eye(size(M)), 'lower');
A = S \ (K / S.');
A = (A + A.') / 2;

idx00 = find(pairs(:,1) == 0 & pairs(:,2) == 0, 1);
idx10 = find(pairs(:,1) == 1 & pairs(:,2) == 0, 1);
idx01 = find(pairs(:,1) == 0 & pairs(:,2) == 1, 1);
Z = zeros(nBasis, 3);
Z(idx00,1) = 1;
Z(idx10,2) = 1;
Z(idx01,3) = 1;
Yz = S.' * Z;
Qz = orth(Yz);
Yperp = null(Qz.');
Ared = Yperp.' * A * Yperp;
Ared = (Ared + Ared.') / 2;

[Vr, Dr] = eig(Ared, 'vector');
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
[Pxi, ~, ~] = legendre_family_eval(pMax, xiGrid(:));
[Peta, ~, ~] = legendre_family_eval(pMax, etaGrid(:));

modesU = cell(1, kUse);
lamDisp = sqrt(max(lamOp(1:kUse), 0));
for j = 1:kUse
    coeff = S.' \ (Yperp * Vr(:,j));
    C = zeros(pMax+1, pMax+1);
    for t = 1:nBasis
        px = pairs(t,1) + 1;
        qy = pairs(t,2) + 1;
        C(qy, px) = coeff(t);
    end
    U = real(Peta * C * Pxi.');
    U = canonicalize_mode(U);
    utol = 1e-12 * max(1, max(abs(U(:)), [], 'omitnan'));
    U(abs(U) < utol) = 0;
    modesU{j} = U;
end

sol = struct('x', x, 'y', y, 'modesU', {modesU}, 'lamDisp', lamDisp(:).', ...
    'a', a, 'b', b, 'Nx', Nx, 'Ny', Ny, 'rigid_modes_removed', true, ...
    'basis_order', pMax);
end

function [nBasis, pairs] = tensor_basis_pairs(pMax)
pairs = zeros((pMax+1)^2, 2);
t = 0;
for px = 0:pMax
    for qy = 0:pMax
        t = t + 1;
        pairs(t,:) = [px qy];
    end
end
nBasis = t;
pairs = pairs(1:t,:);
end

function G = weighted_gram_sym(A, B, w)
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
