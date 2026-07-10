function out = phase_zernike_coma_x(X, Y, params)
%PHASE_ZERNIKE_COMA_X Horizontal coma phase.
if nargin == 1 && ischar(X) && strcmpi(X, 'info')
    out = struct('Name', 'Zernike coma x', ...
        'Description', 'Horizontal coma phase using Z_3^1, ideal for asymmetric focal spots.');
    return
end
rho = hypot(X, Y) ./ max(params.phase_radius_m, eps);
theta = atan2(Y, X);
Z = zernike_nm(3, 1, rho, theta);
out = 2 * pi * params.zernike_coeff_waves .* Z;
out(rho > 1) = 0;
end
