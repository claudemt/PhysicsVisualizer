function R = circular_dielectric_dispersion(n1, n2, Vmax, Umax, maxOrder, samples)
%CIRCULAR_DIELECTRIC_DISPERSION Characteristic contours for a step-index dielectric guide.
if n1 <= n2
    error('Cylindrical dielectric guidance requires n1 > n2.');
end
samples = max(160, min(samples, 900));
V = linspace(0, Vmax, samples);
U = linspace(0, Umax, samples);
[Vg, Ug] = meshgrid(V, U);
eta = (n2/n1)^2;
Ue = Ug;
Ue(Ue == 0) = 1e-12;
W2 = Vg.^2 - Ug.^2;
W2(W2 <= 0) = NaN;
W = sqrt(W2);
We = W;
We(We == 0) = 1e-12;
curves = struct('order', {}, 'Phi', {});
for m = 0:maxOrder
    Jm = besselj(m, Ue);
    Km = besselk(m, We, 1);
    F = ((besselj(m-1, Ue) - m./Ue.*besselj(m, Ue)) ./ besselj(m, Ue)) ./ Ue;
    G = (-besselk(m-1, We, 1)./besselk(m, We, 1) - m./We) ./ We;
    bad = Ug < 1e-9 | We < 1e-9 | abs(Jm) < 1e-7 | abs(Km) < 1e-300;
    F(bad) = NaN;
    G(bad) = NaN;
    if m == 0
        Phi = F + G;
    else
        RHS = (m^2).*(1./Ue.^2 + 1./We.^2).*(1./Ue.^2 + eta./We.^2);
        Phi = (F + G).*(F + eta*G) - RHS;
    end
    curves(end+1) = struct('order', m, 'Phi', Phi); %#ok<AGROW>
end
R = struct('n1', n1, 'n2', n2, 'V', Vg, 'U', Ug, 'Vmax', Vmax, 'Umax', Umax, 'curves', curves);
end
