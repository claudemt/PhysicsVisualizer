function R = rectangular_metal_field(modeType, m, n, a, xi0, gridN)
%RECTANGULAR_METAL_FIELD Scalar longitudinal field for a rectangular PEC guide.
% a is the half-width (full width = 2a), b = a * xi0 is the half-height.
% Domain is centered at origin: x in [-a, a], y in [-b, b].
C = physical_constants();
b = a * xi0;
x = linspace(-a, a, gridN);
y = linspace(-b, b, gridN);
[X, Y] = meshgrid(x, y);
% Shift to [0, 2a] x [0, 2b] for standard mode formulas
Xp = X + a;
Yp = Y + b;
if strcmp(modeType, 'TE')
    F = cos(m*pi*Xp/(2*a)) .* cos(n*pi*Yp/(2*b));
    cbLabel = '$H_z$';
else
    F = sin(m*pi*Xp/(2*a)) .* sin(n*pi*Yp/(2*b));
    cbLabel = '$E_z$';
end
F = F ./ (max(abs(F(:))) + eps);
% Full width = 2a, full height = 2b
fcGHz = C.c0/4 * sqrt((m/a)^2 + (n/b)^2) / 1e9;
titleText = sprintf('$\\mathrm{%s}_{%d,%d},\\ f_{\\mathrm{c}}=%.4g\\ \\mathrm{GHz},\\ \\xi_0=%.4g$', ...
    modeType, m, n, fcGHz, xi0);
R = struct('x', X/a, 'y', Y/a, 'F', F, 'xi0', xi0, ...
    'modeLabel', sprintf('%s_{%d,%d}', modeType, m, n), ...
    'cbLabel', cbLabel, 'titleText', titleText);
end
