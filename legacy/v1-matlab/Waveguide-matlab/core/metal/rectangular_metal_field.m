function R = rectangular_metal_field(modeType, m, n, a, b, gridN)
%RECTANGULAR_METAL_FIELD Scalar longitudinal field for a rectangular PEC guide.
C = physical_constants();
x = linspace(0, a, gridN);
y = linspace(0, b, gridN);
[X, Y] = meshgrid(x, y);
if strcmp(modeType, 'TE')
    F = cos(m*pi*X/a) .* cos(n*pi*Y/b);
    cbLabel = '$H_z$';
else
    F = sin(m*pi*X/a) .* sin(n*pi*Y/b);
    cbLabel = '$E_z$';
end
F = F ./ (max(abs(F(:))) + eps);
fcGHz = C.c0/2 * sqrt((m/a)^2 + (n/b)^2) / 1e9;
modeLabel = sprintf('%s_{%d,%d}', modeType, m, n);
titleText = sprintf('Rectangular PEC $\\mathrm{%s}_{%d,%d}$ mode: $f_{\\mathrm{c}}=%s\\;\\mathrm{GHz}$', ...
    modeType, m, n, format_sig3(fcGHz));
R = struct('x', X, 'y', Y, 'F', F, 'fcGHz', fcGHz, ...
    'modeLabel', modeLabel, 'cbLabel', cbLabel, 'titleText', titleText);
end
