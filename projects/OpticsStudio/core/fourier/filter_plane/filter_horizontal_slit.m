function out = filter_horizontal_slit(XF, YF, params)
%FILTER_HORIZONTAL_SLIT Horizontal slit in the Fourier plane.
if nargin == 1 && ischar(XF) && strcmpi(XF, 'info')
    out = struct('Name', 'Horizontal slit', ...
        'Description', 'Horizontal Fourier slit that selects directional spatial frequencies.');
    return
end
ymax = max(abs(YF(:)));
xmax = max(abs(XF(:)));
half_width = max(1e-12, 0.12 * params.filter_scale_ratio * ymax);
half_len = max(1e-12, 0.95 * xmax);
out = double(abs(YF) <= half_width & abs(XF) <= half_len);
end
