function R = rectangular_cutoff_map(modeType, a, b, maxOrder)
%RECTANGULAR_CUTOFF_MAP Cutoff-frequency matrix for rectangular PEC guide.
C = physical_constants();
mList = 0:maxOrder;
nList = 0:maxOrder;
fcGHz = nan(numel(mList), numel(nList));
for ii = 1:numel(mList)
    m = mList(ii);
    for jj = 1:numel(nList)
        n = nList(jj);
        if m == 0 && n == 0, continue; end
        if strcmp(modeType, 'TM') && (m == 0 || n == 0), continue; end
        fcGHz(ii,jj) = C.c0/2 * sqrt((m/a)^2 + (n/b)^2) / 1e9;
    end
end
R = struct('mList', mList, 'nList', nList, 'fcGHz', fcGHz, ...
    'titleText', sprintf('Rectangular PEC $\\mathrm{%s}$ cutoff map: $a=%s\\;\\mathrm{m}$, $b=%s\\;\\mathrm{m}$', ...
    modeType, format_sig3(a), format_sig3(b)));
end
