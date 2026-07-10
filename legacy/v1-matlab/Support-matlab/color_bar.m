function out = color_bar(ax, varargin)
%COLOR_BAR  Visible-spectrum colormap + unified colorbar rules (one-stop).
%
% out = color_bar(ax, 'Name',Value,...)
%

% -------------------------
% Parse inputs
% -------------------------
p = inputParser;
p.addRequired('ax', @(h) ishghandle(h,'axes'));

% Colormap options
p.addParameter('N', 256, @(v) isnumeric(v) && isscalar(v) && v>=2);
p.addParameter('UseVisibleSpectrum', true, @(v) islogical(v) || (isnumeric(v)&&isscalar(v)));
p.addParameter('Colormap', [], @(v) isempty(v) || (isnumeric(v)&&size(v,2)==3));

% Color axis options
p.addParameter('Limits', [], @(v) isempty(v) || (isnumeric(v)&&numel(v)==2 && all(isfinite(v))));
p.addParameter('AutoSymmetric', false, @(v) islogical(v) || (isnumeric(v)&&isscalar(v)));
p.addParameter('Data', [], @(v) isempty(v) || isnumeric(v));  % 用于 AutoSymmetric
p.addParameter('NormalizeToUnit', false, @(v) islogical(v) || (isnumeric(v)&&isscalar(v))); % 若提供 Data，可先归一化再设 limits

% Colorbar options
p.addParameter('CreateColorbar', true, @(v) islogical(v) || (isnumeric(v)&&isscalar(v)));
p.addParameter('Location', 'eastoutside', @(s) ischar(s) || isstring(s));
p.addParameter('Interpreter', 'latex', @(s) ischar(s) || isstring(s));
p.addParameter('Label', '', @(s) ischar(s) || isstring(s));
p.addParameter('LabelInterpreter', '', @(s) ischar(s) || isstring(s));
p.addParameter('Ticks', [], @(v) isempty(v) || isnumeric(v));
p.addParameter('TickLabels', [], @(v) isempty(v) || isstring(v) || iscellstr(v));

p.parse(ax, varargin{:});
opt = p.Results;

% -------------------------
% Build / apply colormap
% -------------------------
if ~isempty(opt.Colormap)
    cmap = opt.Colormap;
else
    if opt.UseVisibleSpectrum
        cmap = viscolormap_local(opt.N);
    else
        cmap = parula(opt.N); %#ok<NASGU> % fallback (rarely used)
        cmap = parula(opt.N);
    end
end
colormap(ax, cmap);

% -------------------------
% Decide clim
% -------------------------
climApplied = [];

% If explicit limits provided, use them
if ~isempty(opt.Limits)
    clim(ax, opt.Limits);
    climApplied = opt.Limits;

% Else if AutoSymmetric, compute symmetric limits
elseif opt.AutoSymmetric
    data = opt.Data;
    if isempty(data)
        data = try_get_axes_cdata(ax);
    end

    if ~isempty(data)
        if opt.NormalizeToUnit
            s = max(abs(data(:)), [], 'omitnan');
            if ~isfinite(s) || s < eps, s = 1; end
            data = data ./ s;
        end
        m = max(abs(data(:)), [], 'omitnan');
        if ~isfinite(m) || m < eps, m = 1; end
        clim(ax, [-m m]);
        climApplied = [-m m];
    end
end

% -------------------------
% Create / format colorbar
% -------------------------
cb = [];
if opt.CreateColorbar
    cb = colorbar(ax, char(opt.Location));
    set(cb, 'TickLabelInterpreter', char(opt.Interpreter));

    if ~isempty(opt.Ticks)
        cb.Ticks = opt.Ticks;
    end
    if ~isempty(opt.TickLabels)
        cb.TickLabels = opt.TickLabels;
    end

    if strlength(string(opt.Label)) > 0
        cb.Label.String = char(opt.Label);
        if strlength(string(opt.LabelInterpreter)) == 0
            cb.Label.Interpreter = char(opt.Interpreter);
        else
            cb.Label.Interpreter = char(opt.LabelInterpreter);
        end
    end
end

% -------------------------
% Return struct
% -------------------------
out = struct();
out.cb = cb;
out.cmap = cmap;
out.clim = climApplied;

end

% ======================================================================
% Local helpers
% ======================================================================
function data = try_get_axes_cdata(ax)
% Try to get numeric CData from the most recent suitable child object
data = [];
kids = ax.Children;
if isempty(kids), return; end

% look for common plot types that carry CData/ZData
for i = 1:numel(kids)
    h = kids(i);
    if isprop(h,'CData')
        cd = h.CData;
        if isnumeric(cd) && ~isempty(cd)
            data = cd;
            return;
        end
    end
    if isprop(h,'ZData')
        zd = h.ZData;
        if isnumeric(zd) && ~isempty(zd)
            data = zd;
            return;
        end
    end
end
end

function cmapOut = viscolormap_local(N)
% Visible-spectrum colormap (380–780nm), gamma-corrected, same as your code
if nargin < 1, N = 256; end
lambda = linspace(380, 780, N);  % nm
rgb = zeros(N, 3);

for ii = 1:N
    l = lambda(ii);

    if l >= 380 && l < 440
        r = -(l - 440) / (440 - 380); g = 0; b = 1;
    elseif l >= 440 && l < 490
        r = 0; g = (l - 440) / (490 - 440); b = 1;
    elseif l >= 490 && l < 510
        r = 0; g = 1; b = -(l - 510) / (510 - 490);
    elseif l >= 510 && l < 580
        r = (l - 510) / (580 - 510); g = 1; b = 0;
    elseif l >= 580 && l < 645
        r = 1; g = -(l - 645) / (645 - 580); b = 0;
    elseif l >= 645 && l <= 780
        r = 1; g = 0; b = 0;
    else
        r = 0; g = 0; b = 0;
    end

    if l >= 380 && l < 420
        f = 0.3 + 0.7*(l - 380)/(420 - 380);
    elseif l >= 420 && l <= 700
        f = 1.0;
    elseif l > 700 && l <= 780
        f = 0.3 + 0.7*(780 - l)/(780 - 700);
    else
        f = 0.0;
    end

    gamma = 0.8;
    rgb(ii, :) = (f .* [r g b]) .^ gamma;
end

cmapOut = max(min(rgb, 1), 0);
end
