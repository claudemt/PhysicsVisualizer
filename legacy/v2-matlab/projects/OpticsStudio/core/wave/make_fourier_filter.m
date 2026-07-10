function filter_mask = make_fourier_filter(filter_type, fx, fy, scale)
%MAKE_FOURIER_FILTER Build a simple Fourier-plane mask.

if nargin < 4
    scale = 0.18;
end

fmax = max(abs(fx(:)));
fxn = fx / max(fmax, eps);
fyn = fy / max(fmax, eps);
r = sqrt(fxn.^2 + fyn.^2);
sep = min(0.6, max(0.15, 2.2 * scale));
width = max(0.03, scale);

switch lower(strtrim(filter_type))
    case 'none'
        filter_mask = ones(size(fx));
    case 'pinhole'
        filter_mask = double(r < scale);
    case 'ring'
        filter_mask = double(abs(r - 0.45) < width / 2);
    case 'horizontal_single'
        filter_mask = double(abs(fyn) < width);
    case 'horizontal_double'
        filter_mask = double(abs(fyn - sep) < width | abs(fyn + sep) < width);
    case 'vertical_single'
        filter_mask = double(abs(fxn) < width);
    case 'vertical_double'
        filter_mask = double(abs(fxn - sep) < width | abs(fxn + sep) < width);
    otherwise
        filter_mask = ones(size(fx));
end
end
