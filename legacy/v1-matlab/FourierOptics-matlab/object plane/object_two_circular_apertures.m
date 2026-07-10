function out = object_two_circular_apertures(X, Y, params)
%OBJECT_TWO_CIRCULAR_APERTURES Two separated circular apertures.
if nargin == 1 && ischar(X) && strcmpi(X, 'info')
    out = struct('Name', 'Two circular apertures', ...
        'Description', 'Two equal circular holes, useful for comparing with the double-slit case while keeping circular symmetry.');
    return
end
R = max(18e-6, 0.42 * params.object_scale_m);
d = max(2.4 * R, 0.70 * params.secondary_scale_m);
out = double(((X - d/2).^2 + Y.^2 <= R.^2) | ((X + d/2).^2 + Y.^2 <= R.^2));
end
