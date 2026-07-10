function R = circular_metal_field(modeType, m, n, radius, gridN)
%CIRCULAR_METAL_FIELD Scalar longitudinal field for a circular PEC guide.
C = physical_constants();
[tmRoot, teRoot] = bessel_roots(m, n);
rho = linspace(0, radius, gridN);
phi = linspace(0, 2*pi, gridN);
[Rho, Phi] = meshgrid(rho, phi);
X = Rho .* cos(Phi);
Y = Rho .* sin(Phi);
if strcmp(modeType, 'TE')
    root = teRoot;
    cbLabel = '$H_z$';
else
    root = tmRoot;
    cbLabel = '$E_z$';
end
F = besselj(m, root*Rho/radius) .* cos(m*Phi);
F = F ./ (max(abs(F(:))) + eps);
fcGHz = C.c0*root/(2*pi*radius) / 1e9;
modeLabel = sprintf('%s_{%d,%d}', modeType, m, n);
titleText = sprintf('Circular PEC $\\mathrm{%s}_{%d,%d}$ mode: $f_{\\mathrm{c}}=%s\\;\\mathrm{GHz}$', ...
    modeType, m, n, format_sig3(fcGHz));
R = struct('x', X, 'y', Y, 'F', F, 'fcGHz', fcGHz, ...
    'modeLabel', modeLabel, 'cbLabel', cbLabel, 'titleText', titleText);
end
