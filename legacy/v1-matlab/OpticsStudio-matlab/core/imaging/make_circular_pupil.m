function [pupil, rho, phi] = make_circular_pupil(n)
%MAKE_CIRCULAR_PUPIL Create a unit-radius circular pupil and its polar coordinates.

[x, y] = meshgrid(linspace(-1, 1, n));
rho = sqrt(x.^2 + y.^2);
phi = atan2(y, x);
pupil = double(rho <= 1);
end
