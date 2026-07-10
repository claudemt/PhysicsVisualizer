function tf = has_zero_level(A)
%HAS_ZERO_LEVEL True when finite data genuinely crosses zero.
vals = A(:);
vals = vals(isfinite(vals));
if isempty(vals)
    tf = false;
    return;
end
mn = min(vals);
mx = max(vals);
tol = 1000 * eps(max(1, max(abs(vals))));
tf = (mn < -tol) && (mx > tol);
end
