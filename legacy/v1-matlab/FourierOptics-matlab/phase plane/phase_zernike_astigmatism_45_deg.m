function out = phase_zernike_astigmatism_45_deg(X, Y, params)
%PHASE_ZERNIKE_ASTIGMATISM_45_DEG Astigmatism at 45 degrees.
if nargin == 1 && ischar(X) && strcmpi(X, 'info')
    out = struct('Name', 'Zernike astigmatism 45 deg', ...
        'Description', 'Astigmatic phase using Z_2^{-2}, rotated by 45 degrees relative to the x/y axes.');
    return
end
rho = hypot(X, Y) ./ max(params.phase_radius_m, eps);
theta = atan2(Y, X);
Z = zernike_nm(2, -2, rho, theta);
out = 2 * pi * params.zernike_coeff_waves .* Z;
out(rho > 1) = 0;
end
