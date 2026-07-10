function out = filter_vertical_slit(XF, YF, params)
%FILTER_VERTICAL_SLIT Vertical slit in the Fourier plane.
if nargin == 1 && ischar(XF) && strcmpi(XF, 'info')
    out = struct('Name', 'Vertical slit', ...
        'Description', 'Vertical Fourier slit that selects directional spatial frequencies.');
    return
end
ymax = max(abs(YF(:)));
xmax = max(abs(XF(:)));
half_width = max(1e-12, 0.12 * params.filter_scale_ratio * xmax);
half_len = max(1e-12, 0.95 * ymax);
out = double(abs(XF) <= half_width & abs(YF) <= half_len);
end
