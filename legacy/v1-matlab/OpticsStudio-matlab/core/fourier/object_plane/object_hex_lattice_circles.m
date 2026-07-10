function out = object_hex_lattice_circles(X, Y, params)
%OBJECT_HEX_LATTICE_CIRCLES Hexagonally packed circular apertures.
if nargin == 1 && ischar(X) && strcmpi(X, 'info')
    out = struct('Name', 'Hex lattice circles', ...
        'Description', 'Finite hexagonal array of circular micro-apertures for rich lattice spectra.');
    return
end
R = max(20e-6, 0.5 * params.object_scale_m);
p = max(2.2 * R, params.secondary_scale_m);
py = sqrt(3) / 2 * p;
out = zeros(size(X));
centers = [];
for row = -3:3
    for col = -3:3
        cx = col * p + 0.5 * mod(row, 2) * p;
        cy = row * py;
        centers(end+1, :) = [cx, cy]; %#ok<AGROW>
    end
end
for k = 1:size(centers, 1)
    cx = centers(k, 1);
    cy = centers(k, 2);
    out = out | ((X - cx).^2 + (Y - cy).^2 <= R.^2);
end
out = double(out);
end
