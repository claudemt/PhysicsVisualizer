function out = phase_zernike_tilt_x(X, Y, params)
%PHASE_ZERNIKE_TILT_X Linear x-tilt phase.
if nargin == 1 && ischar(X) && strcmpi(X, 'info')
    out = struct('Name', 'Zernike tilt x', ...
        'Description', 'Linear x-tilt phase using Z_1^1, useful for steering the focal distribution off-axis.');
    return
end
rho = hypot(X, Y) ./ max(params.phase_radius_m, eps);
theta = atan2(Y, X);
Z = zernike_nm(1, 1, rho, theta);
out = 2 * pi * params.zernike_coeff_waves .* Z;
out(rho > 1) = 0;
end
