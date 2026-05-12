function magnets = build_compact_checkerboard_magnets(params)
%BUILD_COMPACT_CHECKERBOARD_MAGNETS Tight Nx-by-Ny checkerboard cuboid array.
% Magnet centers are separated by their own footprint dimensions: compact packing.

params = validate_graphite_levitation_params(params);
nx = params.array.nx; ny = params.array.ny;
a = params.magnet.a; b = params.magnet.b; c = params.magnet.c;
xs = ((1:nx) - (nx+1)/2) * a;
ys = ((1:ny) - (ny+1)/2) * b;
[X, Y] = meshgrid(xs, ys);
S = ones(size(X));
for iy = 1:ny
    for ix = 1:nx
        S(iy,ix) = (-1)^(ix+iy);
    end
end
magnets = struct();
magnets.x = X(:);
magnets.y = Y(:);
magnets.z = -c/2 * ones(numel(X), 1);    % top surface at z = 0, center at -c/2
magnets.sign = S(:);
magnets.a = a;
magnets.b = b;
magnets.c = c;
magnets.Br = params.magnet.Br;
magnets.nx = nx;
magnets.ny = ny;
end
