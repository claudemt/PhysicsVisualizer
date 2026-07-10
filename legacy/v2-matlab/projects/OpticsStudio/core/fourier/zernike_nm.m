function Z = zernike_nm(n, m, rho, theta)
%ZERNIKE_NM Real-valued Zernike polynomial Z_n^m on the unit disk.
%   rho should be in [0,1]. Outside the unit disk the output is zero.

validateattributes(n, {'numeric'}, {'scalar','integer','nonnegative'});
validateattributes(m, {'numeric'}, {'scalar','integer'});
if mod(n - abs(m), 2) ~= 0
    Z = zeros(size(rho));
    return
end

mask = rho <= 1;
R = zeros(size(rho));
ma = abs(m);
for s = 0:((n - ma) / 2)
    coeff = ((-1)^s) * factorial(n - s) / ...
        (factorial(s) * factorial((n + ma)/2 - s) * factorial((n - ma)/2 - s));
    R = R + coeff .* rho.^(n - 2*s);
end

if m > 0
    Z = R .* cos(ma * theta);
elseif m < 0
    Z = R .* sin(ma * theta);
else
    Z = R;
end

norm_factor = 1;
if m ~= 0
    norm_factor = sqrt(2*(n + 1));
else
    norm_factor = sqrt(n + 1);
end
Z = norm_factor .* Z;
Z(~mask) = 0;
end
