function out = object_five_slits(X, Y, params)
%OBJECT_FIVE_SLITS Five parallel slits.
if nargin == 1 && ischar(X) && strcmpi(X, 'info')
    out = struct('Name', 'Five slits', ...
        'Description', 'Five equally spaced slits for richer diffraction orders and stronger comb-like spectra.');
    return
end
slit_w = max(10e-6, 0.045 * params.object_scale_m);
slit_h = max(0.22e-3, 1.1 * params.object_scale_m);
d = max(2.8 * slit_w, 0.42 * params.secondary_scale_m);
out = zeros(size(X));
for k = -2:2
    out = out | (abs(X - k*d) <= slit_w/2 & abs(Y) <= slit_h/2);
end
out = double(out);
end
