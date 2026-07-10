function sol = solve_rect_clamped_fd_highres(k, n, a, b)
%SOLVE_RECT_CLAMPED_FD_HIGHRES Clamped finite-difference solver for a rectangle.

if nargin < 3 || isempty(a), a = 2.0; end
if nargin < 4 || isempty(b), b = 2.0; end

[Nx, Ny, x, y] = rect_fd_vectors(a, b, n);
Mx = Nx - 2;
My = Ny - 2;
hx = a / (Nx - 1);
hy = b / (Ny - 1);
[D2x, D4x] = clamped_1d_operators(Mx, hx);
[D2y, D4y] = clamped_1d_operators(My, hy);

Ix = speye(Mx);
Iy = speye(My);
A = kron(D4x, Iy) + 2*kron(D2x, D2y) + kron(Ix, D4y);
A = (A + A.') / 2;

kSearch = min(k + 12, size(A,1) - 2);
if kSearch < 1
    error('Grid too small for clamped solver.');
end

opts.isreal = true;
opts.issym = true;
opts.tol = 1e-10;
opts.maxit = 4000;

try
    [V, D] = eigs(A, kSearch, 'SM', opts);
catch
    [V, D] = eigs(A, kSearch, 1e-8, opts);
end

lamVec = real(diag(D));
good = isfinite(lamVec) & (lamVec > -1e-10);
lamVec = lamVec(good);
V = V(:, good);
[lamVec, ord] = sort(lamVec, 'ascend');
V = V(:, ord);

if isempty(lamVec)
    error('Clamped FD solver produced no valid eigenvalues.');
end

kUse = min(k, numel(lamVec));
modesU = cell(1, kUse);
lamDisp = sqrt(max(lamVec(1:kUse), 0));
lamDisp(lamDisp < 1e-12) = 0;

for j = 1:kUse
    Uin = reshape(real(V(:,j)), My, Mx);
    Uin = canonicalize_mode(Uin);
    U = zeros(Ny, Nx);
    U(2:end-1, 2:end-1) = Uin;
    U(1,:) = 0; U(end,:) = 0; U(:,1) = 0; U(:,end) = 0;
    utol = 1e-12 * max(1, max(abs(U(:)), [], 'omitnan'));
    U(abs(U) < utol) = 0;
    modesU{j} = U;
end

sol = struct('x', x, 'y', y, 'modesU', {modesU}, 'lamDisp', lamDisp(:).', ...
    'a', a, 'b', b, 'Nx', Nx, 'Ny', Ny);
end

function [Nx, Ny, x, y] = rect_fd_vectors(a, b, n)
baseN = max(121, 3*round(n) + 31);
baseN = min(baseN, 241);
if a >= b
    Nx = baseN;
    Ny = max(41, round((b/a) * (Nx - 1)) + 1);
else
    Ny = baseN;
    Nx = max(41, round((a/b) * (Ny - 1)) + 1);
end
Nx = max(9, 2*floor((Nx-1)/2) + 1);
Ny = max(9, 2*floor((Ny-1)/2) + 1);
x = linspace(-a/2, a/2, Nx);
y = linspace(-b/2, b/2, Ny);
end

function [D2, D4] = clamped_1d_operators(M, h)
D2 = spalloc(M, M, 3*M);
D4 = spalloc(M, M, 5*M);
for r = 1:M
    i = r + 1;
    add2 = zeros(1, M);
    if i-1 >= 2, add2(i-2) = add2(i-2) + 1; end
    add2(i-1) = add2(i-1) - 2;
    if i+1 <= M+1, add2(i) = add2(i) + 1; end
    D2(r,:) = sparse(add2 / h^2);

    add4 = zeros(1, M);
    coeffs = [1, -4, 6, -4, 1];
    idxs = [i-2, i-1, i, i+1, i+2];
    for t = 1:5
        q = idxs(t);
        c = coeffs(t);
        if q == 0
            add4(1) = add4(1) + c;
        elseif q == 1
        elseif q >= 2 && q <= M+1
            add4(q-1) = add4(q-1) + c;
        elseif q == M+2
        elseif q == M+3
            add4(M) = add4(M) + c;
        else
            error('Unexpected index in clamped_1d_operators.');
        end
    end
    D4(r,:) = sparse(add4 / h^4);
end
D2 = (D2 + D2.') / 2;
D4 = (D4 + D4.') / 2;
end

function v = canonicalize_mode(v)
[~, idx] = max(abs(v(:)));
if isempty(idx) || abs(v(idx)) < eps
    return;
end
if v(idx) < 0
    v = -v;
end
end
