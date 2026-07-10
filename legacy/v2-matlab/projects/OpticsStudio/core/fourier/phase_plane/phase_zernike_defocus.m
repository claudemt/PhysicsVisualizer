function out = phase_zernike_defocus(X, Y, params)
%PHASE_ZERNIKE_DEFOCUS Defocus phase on a circular pupil.
if nargin == 1 && ischar(X) && strcmpi(X, 'info')
    out = struct('Name', 'Zernike defocus', ...
        'Description', 'Defocus phase map using the real-valued Zernike polynomial Z_2^0.');
    return
end
rho = hypot(X, Y) ./ max(params.phase_radius_m, eps);
theta = atan2(Y, X);
Z = zernike_nm(2, 0, rho, theta);
out = 2 * pi * params.zernike_coeff_waves .* Z;
out(rho > 1) = 0;
end
