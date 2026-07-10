function [u, w, bNorm, ok] = planar_solve_u(modeType, order, V, n1, n2)
%PLANAR_SOLVE_U Solve the symmetric slab normalized eigenvalue equation.
ok = false;
u = NaN; w = NaN; bNorm = NaN;
if V <= 0 || order < 0 || n1 <= n2
    return;
end
lower = order*pi/2;
upper = (order + 1)*pi/2;
if V <= lower
    return;
end
epsU = 1e-8;
a = lower + epsU;
b = min(upper - epsU, V - epsU);
if b <= a
    return;
end
if strcmp(modeType, 'TE')
    ratio = 1;
else
    ratio = (n2/n1)^2;
end
if mod(order, 2) == 0
    fun = @(x) sqrt(max(V.^2 - x.^2, 0)) - ratio*x.*tan(x);
else
    fun = @(x) sqrt(max(V.^2 - x.^2, 0)) + ratio*x.*cot(x);
end
opts = optimset('TolX', 1e-12, 'Display', 'off');
try
    xs = linspace(a, b, 100);
    ys = arrayfun(@(xx) safeEval(fun, xx), xs);
    good = isfinite(ys);
    idx = find(good(1:end-1) & good(2:end) & ys(1:end-1).*ys(2:end) <= 0, 1, 'first');
    if isempty(idx)
        [~, j] = min(abs(ys));
        if isempty(j) || ~isfinite(ys(j))
            return;
        end
        span = (b-a)/100;
        aa = max(a, xs(j)-span);
        bb = min(b, xs(j)+span);
    else
        aa = xs(idx); bb = xs(idx+1);
    end
    uTry = fzero(fun, [aa bb], opts);
    if isfinite(uTry) && uTry > lower && uTry < min(upper, V)
        u = uTry;
        w = sqrt(max(V^2 - u^2, 0));
        bNorm = (w/V)^2;
        ok = isfinite(bNorm) && bNorm >= -1e-8 && bNorm <= 1+1e-8;
        bNorm = min(max(bNorm, 0), 1);
    end
catch
    ok = false;
end
end

function y = safeEval(fun, x)
try
    y = fun(x);
    if ~isfinite(y) || ~isreal(y)
        y = NaN;
    end
catch
    y = NaN;
end
end
