function out = filter_circular_high_pass(XF, YF, params)
%FILTER_CIRCULAR_HIGH_PASS Circular high-pass Fourier filter.
if nargin == 1 && ischar(XF) && strcmpi(XF, 'info')
    out = struct('Name', 'Circular high-pass', ...
        'Description', 'Central stop that suppresses low spatial frequencies to emphasize edges and fine detail.');
    return
end
r = hypot(XF, YF);
rmax = max(r(:));
Rc = max(1e-12, params.filter_scale_ratio * rmax);
out = double(r >= Rc);
end
