function sol = solve_rect_navier_ssss(k, n, a, b)
%SOLVE_RECT_NAVIER_SSSS Exact Navier modes for a simply supported rectangle.

if nargin < 3 || isempty(a), a = 2.0; end
if nargin < 4 || isempty(b), b = 2.0; end

[Nx, Ny, x, y] = rect_plot_vectors(a, b, n);
xp = x + a/2;
yp = y + b/2;

mMax = max(12, ceil(sqrt(k)) + 8);
pairs = zeros(mMax*mMax, 2);
lam = zeros(mMax*mMax, 1);
t = 0;
for m = 1:mMax
    for nn = 1:mMax
        t = t + 1;
        pairs(t,:) = [m nn];
        lam(t) = (m*pi/a)^2 + (nn*pi/b)^2;
    end
end
pairs = pairs(1:t,:);
lam = lam(1:t);
[lam, ord] = sort(lam, 'ascend');
pairs = pairs(ord,:);

kUse = min(k, numel(lam));
modesU = cell(1, kUse);
modeTags = cell(1, kUse);
lamDisp = lam(1:kUse).';
lamDisp(lamDisp < 1e-12) = 0;

for j = 1:kUse
    m = pairs(j,1);
    nn = pairs(j,2);
    X = sin(m*pi*xp/a);
    Y = sin(nn*pi*yp/b);
    U = Y(:) * X(:).';
    U(1,:) = 0; U(end,:) = 0; U(:,1) = 0; U(:,end) = 0;
    modesU{j} = canonicalize_mode(U);
    modeTags{j} = sprintf('mode%d,%d', m, nn);
end

sol = struct('x', x, 'y', y, 'modesU', {modesU}, 'lamDisp', lamDisp, 'modeTags', {modeTags}, ...
    'a', a, 'b', b, 'Nx', Nx, 'Ny', Ny);
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

function U = canonicalize_mode(U)
[~, idx] = max(abs(U(:)));
if isempty(idx) || abs(U(idx)) < eps
    return;
end
if U(idx) < 0
    U = -U;
end
end
