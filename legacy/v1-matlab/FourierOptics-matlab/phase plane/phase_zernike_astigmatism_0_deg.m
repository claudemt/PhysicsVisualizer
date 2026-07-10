function out = phase_zernike_astigmatism_0_deg(X, Y, params)
%PHASE_ZERNIKE_ASTIGMATISM_0_DEG Astigmatism at 0 degrees.
if nargin == 1 && ischar(X) && strcmpi(X, 'info')
    out = struct('Name', 'Zernike astigmatism 0 deg', ...
        'Description', 'Astigmatic phase using Z_2^2 with its principal axes aligned to x/y.');
    return
end
rho = hypot(X, Y) ./ max(params.phase_radius_m, eps);
theta = atan2(Y, X);
Z = zernike_nm(2, 2, rho, theta);
out = 2 * pi * params.zernike_coeff_waves .* Z;
out(rho > 1) = 0;
end
