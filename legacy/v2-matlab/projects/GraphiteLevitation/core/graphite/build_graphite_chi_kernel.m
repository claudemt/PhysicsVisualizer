function [K, info] = build_graphite_chi_kernel(params, dx, dy)
%BUILD_GRAPHITE_CHI_KERNEL Discrete graphite/chi kernel for convolution.
% K samples |chi(x,y)|/|chi0| times the footprint mask in lab coordinates.

params = validate_graphite_levitation_params(params);
g = params.graphite;
e = graphite_extent(g);
% Pad a little so the rotated-square boundary is not clipped.
half = e * 1.05;
nx = max(3, 2*ceil(half/dx) + 1);
ny = max(3, 2*ceil(half/dy) + 1);
if mod(nx,2)==0, nx = nx+1; end
if mod(ny,2)==0, ny = ny+1; end
x = ((1:nx) - (nx+1)/2) * dx;
y = ((1:ny) - (ny+1)/2) * dy;
[X, Y] = meshgrid(x, y);

% Convert lab offsets to sample-local coordinates.
phi = g.rotationDeg*pi/180;
Xloc = cos(phi)*X + sin(phi)*Y;
Yloc = -sin(phi)*X + cos(phi)*Y;

switch lower(char(string(g.shape)))
    case 'circle'
        mask = Xloc.^2 + Yloc.^2 <= g.radius^2;
    case 'square'
        mask = abs(Xloc) <= g.side/2 & abs(Yloc) <= g.side/2;
    otherwise
        mask = false(size(X));
end

W = ones(size(X));
if params.laser.enabled
    sigma = params.laser.spotDiameter / 2.355; % FWHM-like diameter -> sigma
    sigma = max(sigma, 1e-9);
    G = exp(-((Xloc-params.laser.spotX).^2 + (Yloc-params.laser.spotY).^2)/(2*sigma^2));
    W = max(0.02, 1 - params.laser.alpha * G);
end
K = double(mask) .* W;
info = struct('x', x, 'y', y, 'mask', mask, 'weight', W, 'dx', dx, 'dy', dy);
end
