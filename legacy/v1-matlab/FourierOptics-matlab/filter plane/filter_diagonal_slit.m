function out = filter_diagonal_slit(XF, YF, params)
%FILTER_DIAGONAL_SLIT Diagonal Fourier slit.
if nargin == 1 && ischar(XF) && strcmpi(XF, 'info')
    out = struct('Name', 'Diagonal slit', ...
        'Description', 'A 45-degree Fourier slit inspired by directional filtering demos and useful for selecting diagonal spatial frequencies.');
    return
end
rmax = max(hypot(XF(:), YF(:))) + eps;
width = max(1e-12, 0.10 * params.filter_scale_ratio * rmax);
span = max(1e-12, 0.95 * rmax);
dist = abs((XF - YF) ./ sqrt(2));
parallel = abs((XF + YF) ./ sqrt(2));
out = double(dist <= width & parallel <= span);
end
