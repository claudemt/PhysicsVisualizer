function R = circular_metal_field(modeType, m, n, radius, gridN, xi0)
%CIRCULAR_METAL_FIELD Scalar longitudinal field for an annular PEC guide.
% xi0 = R_inner / R_outer; xi0 = 0 gives the full circular guide.
% Uses Cartesian grid for proper imagesc rendering.
if nargin < 6, xi0 = 0; end
C = physical_constants();
[tmRoot, teRoot] = bessel_roots(m, n);
x = linspace(-radius, radius, gridN);
y = linspace(-radius, radius, gridN);
[X, Y] = meshgrid(x, y);
Rho = sqrt(X.^2 + Y.^2);
Phi = atan2(Y, X);
if strcmp(modeType, 'TE')
    root = teRoot;
    cbLabel = '$H_z$';
else
    root = tmRoot;
    cbLabel = '$E_z$';
end
F = besselj(m, root*Rho/radius) .* cos(m*Phi);
F(Rho > radius) = NaN;
if xi0 > 0
    F(Rho < xi0 * radius) = NaN;
end
F = F ./ (max(abs(F(:))) + eps);
fcGHz = C.c0*root/(2*pi*radius) / 1e9;
titleText = sprintf('$\\mathrm{%s}_{%d,%d},\\ f_{\\mathrm{c}}=%.4g\\ \\mathrm{GHz},\\ \\xi_0=%.4g$', ...
    modeType, m, n, fcGHz, xi0);
boundaryRadii = 1;
if xi0 > 0
    boundaryRadii = [xi0, 1];
end
R = struct('x', X/radius, 'y', Y/radius, 'F', F, 'xi0', xi0, ...
    'modeLabel', sprintf('%s_{%d,%d}', modeType, m, n), ...
    'cbLabel', cbLabel, 'titleText', titleText, ...
    'boundaryRadii', boundaryRadii);
end
