function out = object_rectangular_aperture(X, Y, params)
%OBJECT_RECTANGULAR_APERTURE Binary rectangular aperture.
if nargin == 1 && ischar(X) && strcmpi(X, 'info')
    out = struct('Name', 'Rectangular aperture', ...
        'Description', 'Binary rectangular opening with rigorously defined Cartesian edges.');
    return
end
w = params.object_scale_m;
h = max(0.18e-3, 0.45 * params.secondary_scale_m);
out = double(abs(X) <= w/2 & abs(Y) <= h/2);
end
