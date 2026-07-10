function out = phase_zernike_spherical(X, Y, params)
%PHASE_ZERNIKE_SPHERICAL Spherical aberration phase.
if nargin == 1 && ischar(X) && strcmpi(X, 'info')
    out = struct('Name', 'Zernike spherical', ...
        'Description', 'Primary spherical aberration using Z_4^0 for rich radial phase structure.');
    return
end
rho = hypot(X, Y) ./ max(params.phase_radius_m, eps);
theta = atan2(Y, X);
Z = zernike_nm(4, 0, rho, theta);
out = 2 * pi * params.zernike_coeff_waves .* Z;
out(rho > 1) = 0;
end
