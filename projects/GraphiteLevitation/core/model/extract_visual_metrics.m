function metrics = extract_visual_metrics(x, y, U, B2, params)
%EXTRACT_VISUAL_METRICS Measurable quantities from potential map.
% Boundary rows of a finite magnet array are visually useful but physically
% trivial for the local levitation problem: U falls at the edge because there
% are no magnets outside. Extrema and stiffness are therefore extracted from
% the interior region, roughly excluding the outer half-magnet strip.

params = validate_graphite_levitation_params(params);
[X, Y] = meshgrid(x, y);
innerHalfX = max(params.array.nx*params.magnet.a/2 - params.magnet.a/2, min(abs(x))*0 + max(abs(x))*0.5);
innerHalfY = max(params.array.ny*params.magnet.b/2 - params.magnet.b/2, min(abs(y))*0 + max(abs(y))*0.5);
inner = abs(X) <= innerHalfX & abs(Y) <= innerHalfY & isfinite(U);
if ~any(inner(:))
    inner = isfinite(U);
end
Usearch = U;
Usearch(~inner) = NaN;
[~, idx] = min(Usearch(:));
if isempty(idx) || isnan(Usearch(idx))
    [~, idx] = min(U(:));
end
[iy, ix] = ind2sub(size(U), idx);
finiteU = U(inner & isfinite(U));
if isempty(finiteU), finiteU = U(isfinite(U)); end
if isempty(finiteU), finiteU = 0; end
metrics = struct();
metrics.xMin = x(ix);
metrics.yMin = y(iy);
metrics.UMin = U(iy, ix);
metrics.B2AtMin = B2(iy, ix);
metrics.UAvg = mean(finiteU(:));
metrics.UStd = std(finiteU(:));
metrics.UContrast = max(finiteU(:)) - min(finiteU(:));
metrics.innerHalfX = innerHalfX;
metrics.innerHalfY = innerHalfY;

% All grid-resolved stable planar equilibria are local minima of U in the
% interior search region. They are sorted by increasing potential.
metrics.stable = local_find_stable_points(x, y, U, inner);
if ~isempty(metrics.stable.x)
    metrics.xMin = metrics.stable.x(1);
    metrics.yMin = metrics.stable.y(1);
    metrics.UMin = metrics.stable.U(1);
    metrics.B2AtMin = interp2(x, y, B2, metrics.xMin, metrics.yMin, 'linear', NaN);
    [~, ix] = min(abs(x - metrics.xMin));
    [~, iy] = min(abs(y - metrics.yMin));
end

% Local finite-difference stiffness proxies near the primary interior minimum.
metrics.kx = NaN; metrics.ky = NaN;
if ix > 1 && ix < numel(x)
    dx = x(ix+1)-x(ix);
    metrics.kx = (U(iy,ix+1)-2*U(iy,ix)+U(iy,ix-1))/(dx^2);
end
if iy > 1 && iy < numel(y)
    dy = y(iy+1)-y(iy);
    metrics.ky = (U(iy+1,ix)-2*U(iy,ix)+U(iy-1,ix))/(dy^2);
end

% Barrier proxies along the row/column through the minimum, clipped to the
% interior so the edge drop does not dominate the plotted number.
rowMask = abs(x) <= innerHalfX;
colMask = abs(y) <= innerHalfY;
Ux = U(iy,rowMask); Ux = Ux(isfinite(Ux));
Uy = U(colMask,ix); Uy = Uy(isfinite(Uy));
if isempty(Ux), Ux = 0; end
if isempty(Uy), Uy = 0; end
metrics.barrierX = max(Ux(:)) - min(Ux(:));
metrics.barrierY = max(Uy(:)) - min(Uy(:));

% Numerical force proxy from the potential gradient, again interior-only.
try
    [dUdx, dUdy] = gradient(U, x, y);
    fx = abs(dUdx(inner)); fx = fx(isfinite(fx));
    fy = abs(dUdy(inner)); fy = fy(isfinite(fy));
    if isempty(fx), fx = 0; end
    if isempty(fy), fy = 0; end
    metrics.FmaxX = max(fx);
    metrics.FmaxY = max(fy);
catch
    metrics.FmaxX = NaN; metrics.FmaxY = NaN;
end

area = graphite_area(params.graphite);
m = params.graphite.rho * area * params.graphite.thickness;
mg = max(m*9.80665, eps);
metrics.FcxOverMg = metrics.FmaxX / mg;
metrics.FcyOverMg = metrics.FmaxY / mg;
end


function stable = local_find_stable_points(x, y, U, inner)
%LOCAL_FIND_STABLE_POINTS Find all grid-resolved local minima in the
%interior search region. This is deliberately toolbox-free.
stable = struct('x', [], 'y', [], 'U', [], 'ix', [], 'iy', [], 'count', 0);
if numel(x) < 3 || numel(y) < 3 || isempty(U)
    return;
end
rows = 2:(size(U,1)-1);
cols = 2:(size(U,2)-1);
C = U(rows, cols);
valid = inner(rows, cols) & isfinite(C);
isMin = valid;
for dy = -1:1
    for dx = -1:1
        if dx == 0 && dy == 0
            continue;
        end
        N = U(rows+dy, cols+dx);
        isMin = isMin & C <= N;
    end
end
[iy0, ix0] = find(isMin);
if isempty(ix0)
    return;
end
ix = ix0 + 1;
iy = iy0 + 1;
vals = U(sub2ind(size(U), iy, ix));
[vals, order] = sort(vals(:), 'ascend');
ix = ix(order);
iy = iy(order);

% Keep all distinct local minima, but collapse immediate plateau duplicates
% by accepting only points separated by at least two grid steps.
keep = true(size(ix));
for k = 1:numel(ix)
    if ~keep(k), continue; end
    near = abs(ix - ix(k)) <= 1 & abs(iy - iy(k)) <= 1;
    near(1:k) = false;
    keep(near) = false;
end
ix = ix(keep);
iy = iy(keep);
vals = vals(keep);

stable.x = x(ix);
stable.y = y(iy);
stable.U = vals(:).';
stable.ix = ix(:).';
stable.iy = iy(:).';
stable.count = numel(ix);
end
