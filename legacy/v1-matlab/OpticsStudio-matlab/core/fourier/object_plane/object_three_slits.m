function out = object_three_slits(X, Y, params)
%OBJECT_THREE_SLITS Three parallel slits.
if nargin == 1 && ischar(X) && strcmpi(X, 'info')
    out = struct('Name', 'Three slits', ...
        'Description', 'Three parallel amplitude slits with controllable pitch, ideal for discrete Fourier-order demonstrations.');
    return
end
slit_w = max(10e-6, 0.05 * params.object_scale_m);
slit_h = max(0.20e-3, params.object_scale_m);
d = max(2.6 * slit_w, 0.55 * params.secondary_scale_m);
out = double((abs(X + d) <= slit_w/2 & abs(Y) <= slit_h/2) | ...
             (abs(X) <= slit_w/2 & abs(Y) <= slit_h/2) | ...
             (abs(X - d) <= slit_w/2 & abs(Y) <= slit_h/2));
end
