function out = filter_mesh(XF, YF, params)
%FILTER_MESH Periodic mesh filter in the Fourier plane.
if nargin == 1 && ischar(XF) && strcmpi(XF, 'info')
    out = struct('Name', 'Mesh', ...
        'Description', 'Periodic mesh-like mask that samples the Fourier plane on a square lattice.');
    return
end
xmax = max(abs(XF(:))) + eps;
period = max(1e-12, 0.18 * params.filter_scale_ratio * xmax + 0.02 * xmax);
width = 0.18 * period;
modx = mod(XF + period/2, period) - period/2;
mody = mod(YF + period/2, period) - period/2;
out = double(abs(modx) <= width/2 | abs(mody) <= width/2);
end
