function B = evaluate_dipole_field_map(X, Y, z, magnets, params)
%EVALUATE_DIPOLE_FIELD_MAP Fast compact-cuboid magnetic field map.
% By default this uses a coarse equivalent surface-magnetic-charge model
% for each cuboid magnet. It preserves the rectangular cuboid/checkerboard
% geometry while remaining fast enough for GUI visualization.

params = validate_graphite_levitation_params(params);
sourceN = 1;
try, sourceN = params.numerics.fieldSourceN; catch, end
if sourceN <= 1
    B = local_dipole_field_map(X, Y, z, magnets, params);
else
    B = local_surface_charge_field_map(X, Y, z, magnets, params, sourceN);
end
end

function B = local_surface_charge_field_map(X, Y, z, magnets, params, sourceN)
mu0 = params.numerics.mu0;
soft = params.numerics.fieldSoftening;
Bx = zeros(size(X)); By = Bx; Bz = Bx;
M = params.magnet.Br / mu0;

% Patch centers on a compact rectangular top/bottom surface.
ux = ((1:sourceN) - (sourceN+1)/2) / sourceN * magnets.a;
uy = ((1:sourceN) - (sourceN+1)/2) / sourceN * magnets.b;
[UX, UY] = meshgrid(ux, uy);
dA = magnets.a * magnets.b / (sourceN^2);

for k = 1:numel(magnets.x)
    sgn = magnets.sign(k);
    for surfaceId = 1:2
        if surfaceId == 1
            zs = 0;       % top face, outward normal +z
            qsign = sgn;
        else
            zs = -magnets.c; % bottom face, outward normal -z
            qsign = -sgn;
        end
        q = qsign * M * dA;
        for j = 1:numel(UX)
            rx = X - (magnets.x(k) + UX(j));
            ry = Y - (magnets.y(k) + UY(j));
            rz = z - zs;
            r2 = rx.^2 + ry.^2 + rz.^2 + soft^2;
            r32 = r2 .^ 1.5;
            coef = mu0/(4*pi) * q ./ r32;
            Bx = Bx + coef .* rx;
            By = By + coef .* ry;
            Bz = Bz + coef .* rz;
        end
    end
end
B = struct('Bx', Bx, 'By', By, 'Bz', Bz);
end

function B = local_dipole_field_map(X, Y, z, magnets, params)
mu0 = params.numerics.mu0;
Bx = zeros(size(X)); By = Bx; Bz = Bx;
volume = magnets.a * magnets.b * magnets.c;
M = params.magnet.Br / mu0;
m0 = M * volume;
soft = 0.25 * min([magnets.a magnets.b magnets.c]);

for k = 1:numel(magnets.x)
    rx = X - magnets.x(k);
    ry = Y - magnets.y(k);
    rz = z - magnets.z(k);
    r2 = rx.^2 + ry.^2 + rz.^2 + soft^2;
    r = sqrt(r2);
    m = magnets.sign(k) * m0;
    mdotr = m * rz;
    coef = mu0/(4*pi) ./ (r.^5);
    Bx = Bx + coef .* (3*rx.*mdotr);
    By = By + coef .* (3*ry.*mdotr);
    Bz = Bz + mu0/(4*pi) .* (3*rz.*mdotr./(r.^5) - m./(r.^3));
end
B = struct('Bx', Bx, 'By', By, 'Bz', Bz);
end
