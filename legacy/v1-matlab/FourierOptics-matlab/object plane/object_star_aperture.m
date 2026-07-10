function out = object_star_aperture(X, Y, params)
%OBJECT_STAR_APERTURE Five-point star aperture defined by polygon edges.
if nargin == 1 && ischar(X) && strcmpi(X, 'info')
    out = struct('Name', 'Star aperture', ...
        'Description', 'Five-point star polygon, useful for showing angular spectral content.');
    return
end
R = 0.55 * params.object_scale_m;
r = 0.42 * R;
pts = zeros(10, 2);
for k = 0:9
    if mod(k, 2) == 0
        rr = R;
    else
        rr = r;
    end
    ang = pi/2 + k * pi/5;
    pts(k+1, :) = rr .* [cos(ang), sin(ang)];
end
out = inpolygon(X, Y, pts(:,1), pts(:,2));
out = double(out);
end
