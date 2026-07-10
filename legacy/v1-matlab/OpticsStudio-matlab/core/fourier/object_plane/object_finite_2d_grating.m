function out = object_finite_2d_grating(X, Y, params)
%OBJECT_FINITE_2D_GRATING Finite orthogonal 2D grating.
if nargin == 1 && ischar(X) && strcmpi(X, 'info')
    out = struct('Name', 'Finite 2D grating', ...
        'Description', 'Finite orthogonal line grating inspired by classroom Fourier-optics demos and useful for spatial-frequency lattice views.');
    return
end
L = 3.2 * params.object_scale_m;
half = L / 2;
p = max(40e-6, 0.55 * params.secondary_scale_m);
line_w = 0.28 * p;
out = double(abs(mod(X + half, p) - p/2) <= line_w/2 | abs(mod(Y + half, p) - p/2) <= line_w/2);
out(abs(X) > half | abs(Y) > half) = 0;
end
