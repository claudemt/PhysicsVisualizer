function R = planar_field(modeType, order, freqGHz, n1, n2, d, zLength, gridN)
%PLANAR_FIELD Scalar field for a symmetric slab waveguide.
C = physical_constants();
if n1 <= n2
    error('Planar guidance requires nco > ncl.');
end
k0 = 2*pi*freqGHz*1e9/C.c0;
V = k0*d*sqrt(n1^2 - n2^2)/2;
[u, w, bNorm, ok] = planar_solve_u(modeType, order, V, n1, n2);
if ~ok
    error('The selected planar mode is not guided at this frequency. Increase frequency, thickness, or reduce mode order.');
end
neff = sqrt(n2^2 + bNorm*(n1^2 - n2^2));
beta = k0*neff;
kx = 2*u/d;
gamma = 2*w/d;
xSpan = max(1.25*d, d/2 + 4/max(gamma, 1e-12));
x = linspace(-xSpan, xSpan, gridN);
z = linspace(0, zLength, gridN);
[X, Z] = meshgrid(x, z);
Xabs = abs(X);
inside = Xabs <= d/2;
Xprofile = zeros(size(X));
if mod(order, 2) == 0
    core = cos(kx*X);
    boundary = cos(u);
    clad = boundary .* exp(-gamma*(Xabs - d/2));
else
    core = sin(kx*X);
    boundary = sin(u);
    clad = sign(X) .* boundary .* exp(-gamma*(Xabs - d/2));
end
Xprofile(inside) = core(inside);
Xprofile(~inside) = clad(~inside);
F = Xprofile .* cos(beta*Z);
F = F ./ (max(abs(F(:))) + eps);
if strcmp(modeType, 'TE')
    cbLabel = '$E_y$';
else
    cbLabel = '$H_y$';
end
modeLabel = sprintf('%s_%d', modeType, order);
titleText = sprintf('Planar slab $\\mathrm{%s}_{%d}$: $V=%s$, $n_{\\mathrm{eff}}=%s$', ...
    modeType, order, format_sig3(V), format_sig3(neff));
R = struct('x', X, 'z', Z, 'F', F, 'V', V, 'u', u, 'w', w, ...
    'b', bNorm, 'neff', neff, 'modeLabel', modeLabel, 'cbLabel', cbLabel, ...
    'cutoffV', order*pi/2, 'titleText', titleText);
end
