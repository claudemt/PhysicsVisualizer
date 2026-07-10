function out = apply_heatmap_style(ax, x, y, Z, varargin)
p = inputParser;
p.addRequired('ax');
p.addRequired('x');
p.addRequired('y');
p.addRequired('Z');
p.addParameter('Normalize', 'none');
p.addParameter('CLim', []);
p.addParameter('AutoSymmetric', false);
p.addParameter('Mask', []);
p.addParameter('Colormap', 'visible');
p.addParameter('NColor', 256);
p.addParameter('ShowColorbar', true);
p.addParameter('ColorbarLabel', '');
p.addParameter('Title', '');
p.addParameter('XLabel', '$x$');
p.addParameter('YLabel', '$y$');
p.addParameter('AxisMode', 'image');
p.addParameter('ZeroContour', false);
p.addParameter('ContourColor', 'k');
p.addParameter('ContourWidth', 1.0);
p.addParameter('Legend', 'off');
p.addParameter('LegendLocation', 'best');
p.parse(ax, x, y, Z, varargin{:});
opt = p.Results;

[Zplot, clim_values, scale_value] = local_normalize(Z, opt.Normalize, opt.CLim, opt.AutoSymmetric);
if ~isempty(opt.Mask)
    mask = logical(opt.Mask);
    alpha_data = double(mask);
    Zplot(~mask) = NaN;
else
    alpha_data = double(isfinite(Zplot));
end

cla(ax);
h = imagesc(ax, x, y, Zplot, 'AlphaData', alpha_data);
ax.YDir = 'normal';
hold(ax, 'on');
local_colormap(ax, opt.Colormap, opt.NColor);
if ~isempty(clim_values)
    try
        clim(ax, clim_values);
    catch
        caxis(ax, clim_values);
    end
end
if opt.ZeroContour
    try
        contour(ax, x, y, Z, [0 0], 'Color', opt.ContourColor, 'LineWidth', opt.ContourWidth);
    catch
    end
end

apply_tex_style(ax, 'Title', opt.Title, 'XLabel', opt.XLabel, 'YLabel', opt.YLabel, 'AxisMode', opt.AxisMode, 'Legend', opt.Legend, 'LegendLocation', opt.LegendLocation);

cb = [];
if opt.ShowColorbar
    cb = colorbar(ax, 'eastoutside');
    cb.TickLabelInterpreter = 'latex';
    if strlength(string(opt.ColorbarLabel)) > 0
        cb.Label.String = apply_tex_style('text', opt.ColorbarLabel);
        cb.Label.Interpreter = 'latex';
    end
end

out = struct();
out.image = h;
out.colorbar = cb;
out.clim = clim_values;
out.scale = scale_value;
out.Zplot = Zplot;
end

function [Zplot, clim_values, scale_value] = local_normalize(Z, mode, user_clim, auto_symmetric)
mode = lower(char(mode));
scale_value = 1;
switch mode
    case {'signed','signed-unit','unit-signed'}
        scale_value = max(abs(Z(:)), [], 'omitnan');
        if ~isfinite(scale_value) || scale_value < eps
            scale_value = 1;
        end
        Zplot = Z ./ scale_value;
        clim_values = [-1 1];
    case {'positive','positive-unit','unit-positive'}
        scale_value = max(abs(Z(:)), [], 'omitnan');
        if ~isfinite(scale_value) || scale_value < eps
            scale_value = 1;
        end
        Zplot = Z ./ scale_value;
        clim_values = [0 1];
    case {'range','minmax'}
        zmin = min(Z(:), [], 'omitnan');
        zmax = max(Z(:), [], 'omitnan');
        if ~isfinite(zmin) || ~isfinite(zmax) || zmax <= zmin
            Zplot = zeros(size(Z));
        else
            Zplot = (Z - zmin) ./ (zmax - zmin);
        end
        clim_values = [0 1];
    case {'none','raw'}
        Zplot = Z;
        if ~isempty(user_clim)
            clim_values = user_clim(:).';
        elseif auto_symmetric
            m = max(abs(Z(:)), [], 'omitnan');
            if ~isfinite(m) || m < eps
                m = 1;
            end
            clim_values = [-m m];
        else
            clim_values = [];
        end
    otherwise
        error('Unknown normalization mode.');
end
if ~isempty(user_clim)
    clim_values = user_clim(:).';
end
end

function local_colormap(ax, cmap_spec, n_color)
if isnumeric(cmap_spec)
    colormap(ax, cmap_spec);
    return;
end
name = lower(char(cmap_spec));
switch name
    case {'visible','spectrum','vis'}
        colormap(ax, local_visible_colormap(n_color));
    case 'turbo'
        colormap(ax, turbo(n_color));
    case 'parula'
        colormap(ax, parula(n_color));
    case 'gray'
        colormap(ax, gray(n_color));
    case 'hot'
        colormap(ax, hot(n_color));
    case 'hsv'
        colormap(ax, hsv(n_color));
    otherwise
        try
            colormap(ax, feval(name, n_color));
        catch
            colormap(ax, parula(n_color));
        end
end
end

function cmap = local_visible_colormap(N)
if nargin < 1 || isempty(N)
    N = 256;
end
lambda = linspace(380, 780, N);
rgb = zeros(N, 3);
for i = 1:N
    l = lambda(i);
    if l >= 380 && l < 440
        r = -(l - 440) / 60; g = 0; b = 1;
    elseif l >= 440 && l < 490
        r = 0; g = (l - 440) / 50; b = 1;
    elseif l >= 490 && l < 510
        r = 0; g = 1; b = -(l - 510) / 20;
    elseif l >= 510 && l < 580
        r = (l - 510) / 70; g = 1; b = 0;
    elseif l >= 580 && l < 645
        r = 1; g = -(l - 645) / 65; b = 0;
    elseif l >= 645 && l <= 780
        r = 1; g = 0; b = 0;
    else
        r = 0; g = 0; b = 0;
    end
    if l >= 380 && l < 420
        f = 0.3 + 0.7 * (l - 380) / 40;
    elseif l >= 420 && l <= 700
        f = 1;
    elseif l > 700 && l <= 780
        f = 0.3 + 0.7 * (780 - l) / 80;
    else
        f = 0;
    end
    rgb(i, :) = (f * [r g b]).^0.8;
end
cmap = max(min(rgb, 1), 0);
end
