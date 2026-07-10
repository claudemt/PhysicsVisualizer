function R = planar_dispersion(modeType, n1, n2, Vmax, maxOrder, samples)
%PLANAR_DISPERSION Compute normalized b-V curves for a symmetric slab.
if n1 <= n2
    error('Planar dispersion requires n1 > n2.');
end
if Vmax <= 0
    error('V max must be positive.');
end
V = linspace(1e-4, Vmax, max(160, samples));
curves = struct('order', {}, 'V', {}, 'b', {}, 'neff', {}, 'u', {});
for order = 0:maxOrder
    VV = []; BB = []; NN = []; UU = [];
    for k = 1:numel(V)
        [u, ~, bNorm, ok] = planar_solve_u(modeType, order, V(k), n1, n2);
        if ok
            VV(end+1) = V(k); %#ok<AGROW>
            BB(end+1) = bNorm; %#ok<AGROW>
            NN(end+1) = sqrt(n2^2 + bNorm*(n1^2 - n2^2)); %#ok<AGROW>
            UU(end+1) = u; %#ok<AGROW>
        end
    end
    if numel(VV) >= 5
        curves(end+1) = struct('order', order, 'V', VV, 'b', BB, 'neff', NN, 'u', UU); %#ok<AGROW>
    end
end
if isempty(curves)
    error('No guided planar branches were found.');
end
R = struct('modeType', modeType, 'n1', n1, 'n2', n2, ...
    'Vmax', Vmax, 'curves', curves);
end
