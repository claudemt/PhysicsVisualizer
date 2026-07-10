function out = filter_circular_low_pass(XF, YF, params)
%FILTER_CIRCULAR_LOW_PASS Circular low-pass Fourier filter.
if nargin == 1 && ischar(XF) && strcmpi(XF, 'info')
    out = struct('Name', 'Circular low-pass', ...
        'Description', 'Binary circular low-pass stop in the Fourier plane, ideal for smoothing and blur demos.');
    return
end
r = hypot(XF, YF);
rmax = max(r(:));
Rc = max(1e-12, params.filter_scale_ratio * rmax);
out = double(r <= Rc);
end
