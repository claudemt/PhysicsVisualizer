function out = filter_horizontal_double_slit(XF, YF, params)
%FILTER_HORIZONTAL_DOUBLE_SLIT Two horizontal Fourier slits.
if nargin == 1 && ischar(XF) && strcmpi(XF, 'info')
    out = struct('Name', 'Horizontal double slit', ...
        'Description', 'Two parallel horizontal slits in the Fourier plane, useful for selecting symmetric directional bands.');
    return
end
ymax = max(abs(YF(:)));
xmax = max(abs(XF(:)));
half_width = max(1e-12, 0.08 * params.filter_scale_ratio * ymax);
half_len = max(1e-12, 0.95 * xmax);
d = max(1e-12, 0.28 * params.filter_scale_ratio * ymax + 0.04 * ymax);
out = double((abs(YF - d) <= half_width & abs(XF) <= half_len) | ...
             (abs(YF + d) <= half_width & abs(XF) <= half_len));
end
