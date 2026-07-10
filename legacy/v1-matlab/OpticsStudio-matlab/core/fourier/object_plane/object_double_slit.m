function out = object_double_slit(X, Y, params)
%OBJECT_DOUBLE_SLIT Binary double-slit object.
if nargin == 1 && ischar(X) && strcmpi(X, 'info')
    out = struct('Name', 'Double slit', ...
        'Description', 'Classic two-slit amplitude transmission for interference and 4f filtering demos.');
    return
end
slit_w = max(10e-6, 0.06 * params.object_scale_m);
slit_h = max(0.20e-3, params.object_scale_m);
d = max(2.5 * slit_w, 0.45 * params.secondary_scale_m);
out = double((abs(X - d/2) <= slit_w/2 & abs(Y) <= slit_h/2) | ...
             (abs(X + d/2) <= slit_w/2 & abs(Y) <= slit_h/2));
end
