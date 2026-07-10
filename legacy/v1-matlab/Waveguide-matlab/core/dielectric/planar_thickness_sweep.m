function R = planar_thickness_sweep(modeType, n1, n2, d0, freqGHz, maxOrder, samples)
%PLANAR_THICKNESS_SWEEP Sweep slab thickness and track mode existence.
if n1 <= n2
    error('Planar sweep requires n1 > n2.');
end
C = physical_constants();
dValues = linspace(max(d0*0.15, eps), d0*2.5, samples);
modeCount = zeros(size(dValues));
branches = struct('order', {}, 'neff', {});
for order = 0:maxOrder
    branches(end+1) = struct('order', order, 'neff', NaN(size(dValues))); %#ok<AGROW>
end
for i = 1:numel(dValues)
    d = dValues(i);
    k0 = 2*pi*freqGHz*1e9/C.c0;
    V = k0*d*sqrt(n1^2 - n2^2)/2;
    count = 0;
    for order = 0:maxOrder
        [~, ~, bNorm, ok] = planar_solve_u(modeType, order, V, n1, n2);
        if ok
            count = count + 1;
            branches(order+1).neff(i) = sqrt(n2^2 + bNorm*(n1^2 - n2^2));
        end
    end
    modeCount(i) = count;
end
R = struct('modeType', modeType, 'n1', n1, 'n2', n2, 'dValues', dValues, ...
    'freqGHz', freqGHz, 'modeCount', modeCount, 'branches', branches);
end
