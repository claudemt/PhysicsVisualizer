function R = circular_metal_dispersion(modeType, radius, maxOrder, fMinGHz, fMaxGHz, samples)
%CIRCULAR_METAL_DISPERSION PEC circular-guide beta and vg curves.
C = physical_constants();
if fMaxGHz <= fMinGHz
    error('f max must be greater than f min.');
end
fGHz = linspace(fMinGHz, fMaxGHz, samples);
fHz = fGHz * 1e9;
curves = struct('m', {}, 'n', {}, 'fcGHz', {}, 'fGHz', {}, 'beta', {}, 'vgOverC', {}, 'label', {});
for m = 0:maxOrder
    for n = 1:maxOrder
        [tmRoot, teRoot] = bessel_roots(m, n);
        if strcmp(modeType, 'TE')
            root = teRoot;
        else
            root = tmRoot;
        end
        fc = C.c0*root/(2*pi*radius);
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
    'titleText', sprintf('Circular PEC $\\mathrm{%s}$ dispersion: $r=%s\\;\\mathrm{m}$, $f_{\\mathrm{max}}=%s\\;\\mathrm{GHz}$', ...
    modeType, format_sig3(radius), format_sig3(fMaxGHz)));
end
