function out = object_circular_aperture(X, Y, params)
%OBJECT_CIRCULAR_APERTURE Binary circular aperture.
if nargin == 1 && ischar(X) && strcmpi(X, 'info')
    out = struct('Name', 'Circular aperture', ...
        'Description', 'Circular amplitude pupil useful for Airy-like patterns and thin-lens focusing.');
    return
end
R = 0.5 * params.object_scale_m;
out = double(X.^2 + Y.^2 <= R.^2);
end
