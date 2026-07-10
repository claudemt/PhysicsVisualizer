function R = rectangular_metal_dispersion(modeType, a, b, maxOrder, fMinGHz, fMaxGHz, samples)
%RECTANGULAR_METAL_DISPERSION PEC rectangular-guide beta and vg curves.
C = physical_constants();
if fMaxGHz <= fMinGHz
    error('f max must be greater than f min.');
end
fGHz = linspace(fMinGHz, fMaxGHz, samples);
fHz = fGHz * 1e9;
curves = struct('m', {}, 'n', {}, 'fcGHz', {}, 'fGHz', {}, 'beta', {}, 'vgOverC', {}, 'label', {});
for m = 0:maxOrder
    for n = 0:maxOrder
        if m == 0 && n == 0, continue; end
        if strcmp(modeType, 'TM') && (m == 0 || n == 0), continue; end
        fc = C.c0/2 * sqrt((m/a)^2 + (n/b)^2);
        mask = fHz > fc;
        if nnz(mask) < 4, continue; end
        ff = fHz(mask);
        beta = (2*pi/C.c0) * sqrt(ff.^2 - fc^2);
        vgOverC = sqrt(1 - (fc./ff).^2);
        label = sprintf('$\\mathrm{%s}_{%d,%d}\\, (f_{\\mathrm{c}}=%s\\,\\mathrm{GHz})$', ...
            modeType, m, n, format_sig3(fc/1e9));
        curves(end+1) = struct('m', m, 'n', n, 'fcGHz', fc/1e9, ...
            'fGHz', fGHz(mask), 'beta', beta, 'vgOverC', vgOverC, 'label', label); %#ok<AGROW>
    end
end
if isempty(curves)
    error('No propagating modes below f max. Increase f max, reduce max order, or enlarge the guide.');
end
R = struct('curves', curves, 'fMinGHz', fMinGHz, 'fMaxGHz', fMaxGHz, ...
    'titleText', sprintf('Rectangular PEC $\\mathrm{%s}$ dispersion: $a=%s\\;\\mathrm{m}$, $b=%s\\;\\mathrm{m}$, $f_{\\mathrm{max}}=%s\\;\\mathrm{GHz}$', ...
    modeType, format_sig3(a), format_sig3(b), format_sig3(fMaxGHz)));
end
