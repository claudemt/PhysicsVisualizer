function [Uf, limits, mode, info] = static_field_for_display(U, doNormalize, varargin)
%STATIC_FIELD_FOR_DISPLAY Prepare static displacement heat-map scaling.
%
% Static responses are not modal eigenvectors: their sign is set by the load.
% A one-sided response is therefore displayed as a one-sided amplitude map
% abs(w)/A using the same visible-spectrum colormap as the eigenmode plots.
% A signed/divergent map is used
% only when the minority sign occupies a meaningful area AND carries meaningful
% energy, so small truncation ripples do not waste half of the colorbar.
%
% mode is one of: 'positive', 'negative', 'signed', or 'flat'.

if nargin < 2 || isempty(doNormalize), doNormalize = true; end

p = inputParser;
p.addParameter('Percentile', 98, @(v) isnumeric(v) && isscalar(v) && v > 50 && v <= 100);
p.addParameter('Gamma', 1.0, @(v) isnumeric(v) && isscalar(v) && v > 0 && isfinite(v));
p.addParameter('SignedAmpRatio', 0.08, @(v) isnumeric(v) && isscalar(v) && v >= 0);
p.addParameter('SignedEnergyRatio', 0.01, @(v) isnumeric(v) && isscalar(v) && v >= 0);
p.addParameter('SignedAreaRatio', 0.01, @(v) isnumeric(v) && isscalar(v) && v >= 0);
p.parse(varargin{:});
opt = p.Results;

vals = U(:);
vals = vals(isfinite(vals));
if isempty(vals)
    Uf = U;
    limits = [0 1];
    mode = 'flat';
    info = default_info(opt);
    return;
end

stats = static_sign_stats(vals, opt);
mode = classify_static_sign(stats, opt);

if doNormalize
    switch mode
        case 'signed'
            scale = robust_amplitude_scale(vals, opt.Percentile);
            amp = min(abs(U) ./ scale, 1);
            Uf = sign(U) .* amp .^ opt.Gamma;
            limits = [-1 1];
        case {'positive','negative'}
            % One-sided static maps show magnitude only.  Direction is retained
            % in mode/info; the visible-spectrum color scale is shared with eigenmodes.
            scale = robust_amplitude_scale(vals, opt.Percentile);
            amp = min(abs(U) ./ scale, 1);
            Uf = amp .^ opt.Gamma;
            limits = [0 1];
        otherwise
            scale = 1.0;
            Uf = zeros(size(U));
            limits = [0 1];
    end
else
    switch mode
        case 'signed'
            scale = max([abs(min(vals)), abs(max(vals)), stats.noiseTol]);
            Uf = U;
            limits = [-scale scale];
        case {'positive','negative'}
            scale = robust_amplitude_scale(vals, opt.Percentile);
            Uf = abs(U);
            limits = [0 scale];
        otherwise
            scale = 1.0;
            Uf = zeros(size(U));
            limits = [0 1];
    end
end

info = stats;
info.scale = scale;
info.gamma = opt.Gamma;
info.percentile = opt.Percentile;
info.mode = mode;
end

function info = default_info(opt)
info = struct('scale',1,'gamma',opt.Gamma,'percentile',opt.Percentile, ...
    'mode','flat','noiseTol',0,'posAmp',0,'negAmp',0,'posRobust',0, ...
    'negRobust',0,'posArea',0,'negArea',0,'posEnergy',0,'negEnergy',0);
end

function stats = static_sign_stats(vals, opt)
absMax = max(abs(vals));
noiseTol = max(1000 * eps(max(1, absMax)), 1e-10 * max(1, absMax));

posVals = vals(vals > noiseTol);
negVals = -vals(vals < -noiseTol);
mainScale = robust_amplitude_scale(vals, opt.Percentile);
areaThr = max(noiseTol, 0.01 * mainScale);

posAreaVals = vals(vals > areaThr);
negAreaVals = -vals(vals < -areaThr);

n = max(1, numel(vals));
stats = struct();
stats.noiseTol = noiseTol;
stats.posAmp = max_or_zero(posVals);
stats.negAmp = max_or_zero(negVals);
stats.posRobust = quantile_or_zero(posVals, 0.98);
stats.negRobust = quantile_or_zero(negVals, 0.98);
stats.posArea = numel(posAreaVals) / n;
stats.negArea = numel(negAreaVals) / n;
stats.posEnergy = sum(posVals.^2);
stats.negEnergy = sum(negVals.^2);
stats.mainScale = mainScale;
stats.areaThr = areaThr;
end

function mode = classify_static_sign(stats, opt)
posPresent = stats.posAmp > stats.noiseTol;
negPresent = stats.negAmp > stats.noiseTol;

if ~posPresent && ~negPresent
    mode = 'flat';
    return;
elseif posPresent && ~negPresent
    mode = 'positive';
    return;
elseif negPresent && ~posPresent
    mode = 'negative';
    return;
end

mainRobust = max(stats.posRobust, stats.negRobust);
minorRobust = min(stats.posRobust, stats.negRobust);
mainArea = max(stats.posArea, stats.negArea);
minorArea = min(stats.posArea, stats.negArea);
mainEnergy = max(stats.posEnergy, stats.negEnergy);
minorEnergy = min(stats.posEnergy, stats.negEnergy);

ampOK = mainRobust > stats.noiseTol && minorRobust >= opt.SignedAmpRatio * mainRobust;
areaOK = minorArea >= opt.SignedAreaRatio && minorArea >= 0.03 * max(mainArea, eps);
energyOK = mainEnergy > 0 && minorEnergy >= opt.SignedEnergyRatio * mainEnergy;

% Require at least two independent pieces of evidence for a truly sign-changing
% static field.  This rejects narrow opposite-sign rings caused by truncation.
if ampOK && (areaOK || energyOK)
    mode = 'signed';
elseif stats.posRobust >= stats.negRobust
    mode = 'positive';
else
    mode = 'negative';
end
end

function scale = robust_amplitude_scale(vals, percentile)
absVals = abs(vals(:));
absVals = absVals(isfinite(absVals) & absVals > 0);
if isempty(absVals)
    scale = 1.0;
    return;
end
absVals = sort(absVals);
maxAmp = absVals(end);
q = sorted_quantile(absVals, percentile / 100);
if ~isfinite(q) || q <= 0, q = maxAmp; end
scale = max(q, eps(max(1, maxAmp)));
end

function v = max_or_zero(x)
if isempty(x), v = 0; else, v = max(x); end
end

function q = quantile_or_zero(x, p)
if isempty(x), q = 0; else, q = sorted_quantile(sort(x(:)), p); end
end

function q = sorted_quantile(sortedVals, p)
n = numel(sortedVals);
idx = max(1, min(n, ceil(p * n)));
q = sortedVals(idx);
end
