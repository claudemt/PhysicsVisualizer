function out = filter_ring_band_pass(XF, YF, params)
%FILTER_RING_BAND_PASS Ring-shaped Fourier band-pass filter.
if nargin == 1 && ischar(XF) && strcmpi(XF, 'info')
    out = struct('Name', 'Ring band-pass', ...
        'Description', 'Annular band-pass filter that suppresses both DC and extreme high frequencies.');
    return
end
r = hypot(XF, YF);
rmax = max(r(:));
center = max(0.08, min(0.78, params.filter_scale_ratio));
rin = max(1e-12, (center - 0.10) * rmax);
rout = max(rin, (center + 0.08) * rmax);
out = double(r >= rin & r <= rout);
end
