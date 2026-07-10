function out = apply_tex_style(target, varargin)
if ischar(target) || isstring(target)
    cmd = lower(char(target));
    switch cmd
        case {'text','tex'}
            out = local_tex_text(varargin{1});
            return;
        case {'raw'}
            out = varargin{1};
            return;
    end
end

p = inputParser;
p.addParameter('Title', '');
p.addParameter('XLabel', '');
p.addParameter('YLabel', '');
p.addParameter('ZLabel', '');
p.addParameter('FontSize', 12);
p.addParameter('LineWidth', 1.0);
p.addParameter('AxisMode', '');
p.addParameter('Grid', false);
p.addParameter('Box', true);
p.addParameter('Legend', 'off');
p.addParameter('LegendLocation', 'best');
p.addParameter('LegendNumColumns', 1);
p.addParameter('LegendBox', true);
p.addParameter('LegendLabels', {});
p.addParameter('TitleOffset', []);
p.parse(varargin{:});
opt = p.Results;

if ishghandle(target, 'figure')
    set(target, 'DefaultTextInterpreter', 'latex', 'DefaultAxesTickLabelInterpreter', 'latex', 'DefaultLegendInterpreter', 'latex');
    ax_list = findall(target, 'Type', 'axes');
    for k = 1:numel(ax_list)
        local_apply_axes(ax_list(k), opt);
    end
    out = [];
    return;
end

if ishghandle(target, 'axes')
    ax = target;
    local_apply_axes(ax, opt);
    if local_has_text(opt.Title)
        th = title(ax, local_tex_text(opt.Title), 'Interpreter', 'latex');
        if ~isempty(opt.TitleOffset)
            try
                th.Units = 'normalized';
                pos = th.Position;
                pos(2) = opt.TitleOffset;
                th.Position = pos;
            catch
            end
        end
    end
    if local_has_text(opt.XLabel)
        xlabel(ax, local_tex_text(opt.XLabel), 'Interpreter', 'latex');
    end
    if local_has_text(opt.YLabel)
        ylabel(ax, local_tex_text(opt.YLabel), 'Interpreter', 'latex');
    end
    if local_has_text(opt.ZLabel)
        zlabel(ax, local_tex_text(opt.ZLabel), 'Interpreter', 'latex');
    end
    local_apply_legend(ax, opt);
    out = [];
    return;
end

error('Invalid target.');
end

function local_apply_axes(ax, opt)
try ax.TickLabelInterpreter = 'latex'; catch, end
try ax.FontSize = opt.FontSize; catch, end
try ax.LineWidth = opt.LineWidth; catch, end
try ax.Box = local_onoff(opt.Box); catch, end
try ax.Toolbar.Visible = 'off'; catch, end
if opt.Grid
    grid(ax, 'on');
else
    grid(ax, 'off');
end
switch lower(char(opt.AxisMode))
    case 'image'
        axis(ax, 'image');
    case 'equal'
        axis(ax, 'equal');
    case 'tight'
        axis(ax, 'tight');
end
end

function local_apply_legend(ax, opt)
mode = lower(char(opt.Legend));
if strcmp(mode, 'off') || strcmp(mode, 'none')
    return;
end
if ~isempty(opt.LegendLabels)
    labels = local_cellstr(opt.LegendLabels);
    lgd = legend(ax, labels, 'Interpreter', 'latex');
else
    lgd = legend(ax, 'show');
end
try lgd.Location = char(opt.LegendLocation); catch, end
try lgd.NumColumns = opt.LegendNumColumns; catch, end
try lgd.Box = local_onoff(opt.LegendBox); catch, end
try lgd.Interpreter = 'latex'; catch, end
try lgd.FontSize = opt.FontSize; catch, end
end

function tf = local_has_text(x)
tf = ~isempty(x) && strlength(string(x)) > 0;
end

function s = local_tex_text(raw)
if iscell(raw)
    raw = strjoin(local_cellstr(raw), ' ');
end
raw = char(string(raw));
trimmed = strtrim(raw);
if isempty(trimmed)
    s = '';
    return;
end
if contains(trimmed, '$') || contains(trimmed, '\') || contains(trimmed, '^') || contains(trimmed, '_') || contains(trimmed, '{') || contains(trimmed, '}')
    s = raw;
    return;
end
raw = strrep(raw, '\', '\\');
raw = strrep(raw, '_', '\_');
raw = strrep(raw, ' ', '\ ');
s = ['$\mathrm{' raw '}$'];
end

function c = local_cellstr(x)
if ischar(x)
    c = {x};
elseif isstring(x)
    c = cellstr(x);
elseif iscell(x)
    c = cellfun(@char, x, 'UniformOutput', false);
else
    c = cellstr(string(x));
end
end

function s = local_onoff(tf)
if ischar(tf) || isstring(tf)
    s = char(tf);
elseif tf
    s = 'on';
else
    s = 'off';
end
end
