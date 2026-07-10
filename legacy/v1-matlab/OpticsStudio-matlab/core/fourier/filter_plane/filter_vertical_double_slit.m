function out = filter_vertical_double_slit(XF, YF, params)
%FILTER_VERTICAL_DOUBLE_SLIT Two vertical Fourier slits.
if nargin == 1 && ischar(XF) && strcmpi(XF, 'info')
    out = struct('Name', 'Vertical double slit', ...
        'Description', 'Two parallel vertical slits in the Fourier plane, complementary to the horizontal double-slit mask.');
    return
end
ymax = max(abs(YF(:)));
xmax = max(abs(XF(:)));
half_width = max(1e-12, 0.08 * params.filter_scale_ratio * xmax);
half_len = max(1e-12, 0.95 * ymax);
d = max(1e-12, 0.28 * params.filter_scale_ratio * xmax + 0.04 * xmax);
out = double((abs(XF - d) <= half_width & abs(YF) <= half_len) | ...
             (abs(XF + d) <= half_width & abs(YF) <= half_len));
end
