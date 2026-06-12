function [Wplot, x, y] = build_chi_image(params)
%BUILD_CHI_IMAGE High-density image of normalized |chi| inside the graphite.

params = validate_graphite_levitation_params(params);
g = params.graphite;
N = params.numerics.chiGridN;
e = graphite_extent(g) * 1.08;
x = linspace(-e, e, N);
y = linspace(-e, e, N);
[X, Y] = meshgrid(x, y);

switch lower(char(string(g.shape)))
    case 'circle'
        mask = X.^2 + Y.^2 <= g.radius^2;
    case 'square'
        phi = g.rotationDeg * pi / 180;
        Xloc =  cos(phi)*X + sin(phi)*Y;
        Yloc = -sin(phi)*X + cos(phi)*Y;
        mask = abs(Xloc) <= g.side/2 & abs(Yloc) <= g.side/2;
    otherwise
        mask = false(size(X));
end
W = ones(size(X));
if params.laser.enabled
    sigma = params.laser.spotDiameter / 2.355;
    sigma = max(sigma, 1e-9);
    G = exp(-((X-params.laser.spotX).^2 + (Y-params.laser.spotY).^2)/(2*sigma^2));
    W = max(0.02, 1 - params.laser.alpha * G);
end
Wplot = W;
Wplot(~mask) = NaN;
end
