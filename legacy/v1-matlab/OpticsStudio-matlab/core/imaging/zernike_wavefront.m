function w = zernike_wavefront(mode_name, rho, phi)
%ZERNIKE_WAVEFRONT Return a low-order Zernike-like pupil phase basis.

mask = rho <= 1;
mode_name = lower(strtrim(mode_name));

switch mode_name
    case 'none'
        w = zeros(size(rho));
    case 'tilt_x'
        w = rho .* cos(phi);
    case 'defocus'
        w = 2 * rho.^2 - 1;
    case 'astigmatism'
        w = rho.^2 .* cos(2 * phi);
    case 'coma'
        w = rho .* (3 * rho.^2 - 2) .* cos(phi);
    case 'spherical'
        w = 6 * rho.^4 - 6 * rho.^2 + 1;
    otherwise
        w = zeros(size(rho));
end

w = w .* mask;
end
