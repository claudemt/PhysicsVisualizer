function coeff = fresnel_coefficients(n1, n2, theta_i)
%FRESNEL_COEFFICIENTS Compute power reflection and transmission coefficients.

sin_theta_t = n1 / n2 * sin(theta_i);
valid = abs(sin_theta_t) <= 1;

theta_t = zeros(size(theta_i));
theta_t(valid) = asin(sin_theta_t(valid));

a = n1 * cos(theta_i);
b = n2 * cos(theta_t);
c = n1 * cos(theta_t);
d = n2 * cos(theta_i);

rs = (a - b) ./ (a + b + eps);
rp = (c - d) ./ (c + d + eps);

rs(~valid) = 1;
rp(~valid) = 1;

coeff.rs = abs(rs).^2;
coeff.rp = abs(rp).^2;
coeff.ts = 1 - coeff.rs;
coeff.tp = 1 - coeff.rp;
coeff.theta_t = theta_t;
coeff.total_internal_reflection = ~valid;
end
