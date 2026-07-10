function [jRoot, jpRoot] = bessel_roots(m, n)
%BESSEL_ROOTS Return the nth positive root of J_m and J_m'.
if m < 0 || n < 1
    error('Bessel roots require m >= 0 and n >= 1.');
end
jRoot = nthRoot(@(x) besselj(m, x), m, n, false);
jpRoot = nthRoot(@(x) besseljprime(m, x), m, n, true);
end

function r = nthRoot(fun, m, n, isDerivative)
opts = optimset('TolX', 1e-12, 'Display', 'off');
roots = [];
step = 0.035;
scanMax = max(60, (n + m/2 + 10)*pi);
xPrev = 1e-8;
yPrev = safeValue(fun, xPrev);
for x = step:step:scanMax
    y = safeValue(fun, x);
    if isfinite(yPrev) && isfinite(y) && yPrev*y < 0
        try
            rr = fzero(fun, [x-step, x], opts);
            if rr > 1e-7 && (isempty(roots) || abs(rr - roots(end)) > 1e-6)
                roots(end+1) = rr; %#ok<AGROW>
            end
        catch
        end
    end
    yPrev = y;
    if numel(roots) >= n
        r = roots(n);
        return;
    end
end
label = 'J_m';
if isDerivative
    label = 'J_m prime';
end
error('Failed to find root %d of %s for m = %d.', n, label, m);
end

function y = safeValue(fun, x)
try
    y = fun(x);
    if ~isfinite(y) || ~isreal(y)
        y = NaN;
    end
catch
    y = NaN;
end
end
