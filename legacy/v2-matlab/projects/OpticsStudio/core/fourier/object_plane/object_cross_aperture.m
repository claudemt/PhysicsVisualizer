function out = object_cross_aperture(X, Y, params)
%OBJECT_CROSS_APERTURE Orthogonal cross-shaped aperture.
if nargin == 1 && ischar(X) && strcmpi(X, 'info')
    out = struct('Name', 'Cross aperture', ...
        'Description', 'Orthogonal cross aperture with strong horizontal and vertical spatial frequencies.');
    return
end
w = max(0.12e-3, 0.22 * params.object_scale_m);
L = max(0.50e-3, params.object_scale_m);
out = double((abs(X) <= w/2 & abs(Y) <= L/2) | (abs(Y) <= w/2 & abs(X) <= L/2));
end
