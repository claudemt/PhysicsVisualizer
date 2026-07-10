function [u1, transfer_function] = angular_spectrum_propagation(u0, dx, wavelength, z, use_bandlimit)
%ANGULAR_SPECTRUM_PROPAGATION Propagate a scalar field using the angular spectrum method.

[nx, ny] = size(u0);
[~, ~, fx, fy] = make_coordinate_grid(nx, ny, dx, dx);

argument = 1 - (wavelength * fx).^2 - (wavelength * fy).^2;
transfer_function = exp(1i * 2 * pi * z / wavelength * sqrt(complex(argument, 0)));

if use_bandlimit
    lx = ny * dx;
    ly = nx * dx;
    fx_limit = 1 / (wavelength * sqrt(1 + (2 * z / lx)^2));
    fy_limit = 1 / (wavelength * sqrt(1 + (2 * z / ly)^2));
    transfer_function(abs(fx) > fx_limit | abs(fy) > fy_limit) = 0;
end

u0_hat = fftshift(fft2(ifftshift(u0)));
u1_hat = u0_hat .* transfer_function;
u1 = fftshift(ifft2(ifftshift(u1_hat)));
end
