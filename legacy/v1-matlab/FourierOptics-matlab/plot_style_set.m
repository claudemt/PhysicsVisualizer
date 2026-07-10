function varargout = plot_style_set(action, varargin)
%PLOT_STYLE_SET Unified plotting style and 2D map utilities.

if nargin < 1 || isempty(action)
    action = 'defaults';
end
action = lower(string(action));

switch action
    case "defaults"
        set(groot, 'defaultTextInterpreter', 'latex');
        set(groot, 'defaultAxesTickLabelInterpreter', 'latex');
        set(groot, 'defaultLegendInterpreter', 'latex');
        style = localStyle();
        varargout{1} = style;
    case "apply_axes"
        ax = varargin{1};
        kind = char(string(varargin{2}));
        style = localStyle();
        apply_common_axis_style(ax, style);
        apply_colormap(ax, kind, style);
    case "draw_map"
        ax = varargin{1};
        x = varargin{2};
        y = varargin{3};
        data = varargin{4};
        kind = char(string(varargin{5}));
        title_str = varargin{6};
        cbar_label = varargin{7};
        if numel(varargin) >= 8
            opts = varargin{8};
        else
            opts = struct();
        end
        localDrawMap(ax, x, y, data, kind, title_str, cbar_label, opts);
    otherwise
        error('Unknown action: %s', action);
end
end

function style = localStyle()
style = struct();
style.font_name = 'Times New Roman';
style.title_font_size = 16;
style.label_font_size = 12;
style.axis_font_size = 11;
style.line_width = 1.1;
style.intensity_colormap = localHeNeColormap(256);
style.phase_colormap = hsv(256);
style.object_colormap = gray(256);
style.bg_color = [0.975, 0.979, 0.992];
style.intensity_gain = 90;
end

function localDrawMap(ax, x, y, data, kind, title_str, cbar_label, opts)
style = localStyle();
cla(ax);
[xv, yv] = localAxisVectors(x, y, size(data));
plot_data = localPrepareDisplayData(data, kind, style);
imagesc(ax, xv, yv, plot_data);
axis(ax, 'image');
axis(ax, 'xy');
apply_common_axis_style(ax, style);
apply_colormap(ax, kind, style);
localApplyRange(ax, xv, yv, data, kind, opts);
cb = colorbar(ax);
cb.TickLabelInterpreter = 'latex';
cb.Label.Interpreter = 'latex';
cb.Label.String = cbar_label;
title(ax, title_str, 'Interpreter', 'latex', 'FontSize', style.title_font_size);
end

function out = localPrepareDisplayData(data, kind, style)
kind = lower(kind);
out = double(data);
if ismember(kind, {'intensity','spectrum'})
    out = max(out, 0);
    out = out ./ max(out(:) + eps);
    out = log1p(style.intensity_gain .* out) ./ log1p(style.intensity_gain + 1);
elseif ismember(kind, {'object','filter','amplitude'})
    out = max(out, 0);
    out = out ./ max(out(:) + eps);
elseif strcmp(kind, 'phase')
    % keep wrapped phase as-is
else
    out = out ./ max(abs(out(:)) + eps);
end
end

function [xv, yv] = localAxisVectors(x, y, dataSize)
if isvector(x)
    xv = x(:).';
else
    if size(x, 2) == dataSize(2)
        xv = x(1, :);
    elseif size(x, 1) == dataSize(2)
        xv = x(:, 1).';
    else
        xv = 1:dataSize(2);
    end
end

if isvector(y)
    yv = y(:);
else
    if size(y, 1) == dataSize(1)
        yv = y(:, 1);
    elseif size(y, 2) == dataSize(1)
        yv = y(1, :).';
    else
        yv = (1:dataSize(1)).';
    end
end
end

function localApplyRange(ax, xv, yv, data, kind, opts)
opts = localNormalizeOpts(opts);
if ~opts.auto_adjust_range
    xr = opts.fixed_half_range;
    xlim(ax, [-xr, xr]);
    ylim(ax, [-xr, xr]);
    return
end

if strcmpi(kind, 'phase') && ~isempty(opts.support_mask)
    mask = logical(opts.support_mask);
else
    mask = localSupportMask(data, kind);
end

if ~any(mask(:))
    return
end
x_idx = find(any(mask, 1));
y_idx = find(any(mask, 2));
if isempty(x_idx) || isempty(y_idx)
    return
end
x_lo = xv(max(1, x_idx(1)));
x_hi = xv(min(numel(xv), x_idx(end)));
y_lo = yv(max(1, y_idx(1)));
y_hi = yv(min(numel(yv), y_idx(end)));

x_span = max(abs([x_lo, x_hi]));
y_span = max(abs([y_lo, y_hi]));
r = 1.12 * max([x_span, y_span, eps]);
max_r = max([abs(xv(:)); abs(yv(:)); r]);
r = min(r, max_r);
xlim(ax, [-r, r]);
ylim(ax, [-r, r]);
end

function mask = localSupportMask(data, kind)
kind = lower(kind);
d = double(data);
if ismember(kind, {'intensity','spectrum'})
    d = max(d, 0);
    d = d ./ max(d(:) + eps);
    thresh = 0.02;
    mask = d > thresh;
elseif ismember(kind, {'object','filter','amplitude'})
    d = abs(d);
    d = d ./ max(d(:) + eps);
    thresh = 0.01;
    mask = d > thresh;
else
    d = abs(d);
    d = d ./ max(d(:) + eps);
    thresh = 0.01;
    mask = d > thresh;
end
mask = localPadMask(mask, 2);
end

function mask = localPadMask(mask, steps)
for k = 1:steps
    mask = mask | circshift(mask, [1 0]) | circshift(mask, [-1 0]) | circshift(mask, [0 1]) | circshift(mask, [0 -1]);
end
end

function opts = localNormalizeOpts(opts)
if nargin < 1 || isempty(opts)
    opts = struct();
end
if ~isfield(opts, 'auto_adjust_range')
    opts.auto_adjust_range = true;
end
if ~isfield(opts, 'fixed_half_range')
    opts.fixed_half_range = inf;
end
if ~isfield(opts, 'support_mask')
    opts.support_mask = [];
end
end

function apply_common_axis_style(ax, style)
ax.Box = 'on';
ax.LineWidth = style.line_width;
ax.FontName = style.font_name;
ax.FontSize = style.axis_font_size;
ax.XGrid = 'off';
ax.YGrid = 'off';
ax.Color = [1, 1, 1];
ax.Title.Interpreter = 'latex';
ax.XLabel.Interpreter = 'latex';
ax.YLabel.Interpreter = 'latex';
end

function apply_colormap(ax, kind, style)
kind = lower(kind);
switch kind
    case {'phase'}
        colormap(ax, style.phase_colormap);
    case {'filter','object','amplitude'}
        colormap(ax, style.object_colormap);
    otherwise
        colormap(ax, style.intensity_colormap);
end
end

function cmap = localHeNeColormap(n)
if nargin < 1
    n = 256;
end
xp = [0.00 0.08 0.20 0.40 0.70 0.90 1.00];
rp = [0.00 0.10 0.45 0.85 1.00 1.00 1.00];
gp = [0.00 0.01 0.04 0.12 0.42 0.76 0.95];
bp = [0.00 0.00 0.01 0.03 0.08 0.18 0.35];
x = linspace(0, 1, n).';
r = interp1(xp, rp, x, 'pchip');
g = interp1(xp, gp, x, 'pchip');
b = interp1(xp, bp, x, 'pchip');
cmap = [r, g, b];
cmap(1,:) = [0, 0, 0];
end
