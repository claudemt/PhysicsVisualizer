function [x, y, fx, fy] = make_coordinate_grid(nx, ny, dx, dy)
%MAKE_COORDINATE_GRID Build centered spatial and frequency coordinates.

if nargin < 4
    dy = dx;
end

x_vec = ((0:ny-1) - floor(ny/2)) * dx;
y_vec = ((0:nx-1) - floor(nx/2)) * dy;
[x, y] = meshgrid(x_vec, y_vec);

fx_vec = ((0:ny-1) - floor(ny/2)) / (ny * dx);
fy_vec = ((0:nx-1) - floor(nx/2)) / (nx * dy);
[fx, fy] = meshgrid(fx_vec, fy_vec);
end
