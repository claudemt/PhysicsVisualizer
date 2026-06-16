function out = apply_tex_style(target, varargin)
%APPLY_TEX_STYLE Apply the older studio visual style to axes/figures.
%
% This version intentionally keeps the earlier projects' details:
% white figure background, left-to-right axes handling, LaTeX text,
% explicit grid on/off, optional axis mode, and compact legend formatting.

p = inputParser;
p.addParameter('Title', '', @(v) true);
p.addParameter('XLabel', '', @(v) true);
p.addParameter('YLabel', '', @(v) true);
p.addParameter('ZLabel', '', @(v) true);
p.addParameter('FontSize', 26, @(v) isnumeric(v) && isscalar(v));
p.addParameter('TitleFontSize', 30, @(v) isnumeric(v) && isscalar(v));
p.addParameter('Legend', '', @(s) ischar(s) || isstring(s));
p.addParameter('LegendLocation', 'best', @(s) ischar(s) || isstring(s));
p.addParameter('LegendNumColumns', 1, @(v) isnumeric(v) && isscalar(v));
p.addParameter('Box', 'on', @(s) ischar(s) || isstring(s) || islogical(s));
p.addParameter('Grid', 'off', @(s) ischar(s) || isstring(s));
p.addParameter('AxisMode', '', @(s) ischar(s) || isstring(s));
p.addParameter('Interpreter', 'latex', @(s) ischar(s) || isstring(s));
p.addParameter('TickInterpreter', 'latex', @(s) ischar(s) || isstring(s));
p.parse(varargin{:});
opt = p.Results;

fig = [];
axs = [];
if isempty(target)
    out = struct('figure', fig, 'axes', axs);
    return;
end

if isgraphics(target, 'figure')
    fig = target;
    axs = findall(fig, 'Type', 'axes');
else
    axs = target;
    try
        fig = ancestor(target, 'figure');
    catch
        fig = [];
    end
end

if ~isempty(fig) && isgraphics(fig)
    try, fig.Color = [1 1 1]; catch, end
    try, fig.InvertHardcopy = 'off'; catch, end
    try, set(fig, 'DefaultTextInterpreter', char(string(opt.Interpreter))); catch, end
    try, set(fig, 'DefaultAxesTickLabelInterpreter', char(string(opt.TickInterpreter))); catch, end
    try, set(fig, 'DefaultLegendInterpreter', char(string(opt.Interpreter))); catch, end
    try, set(fig, 'DefaultColorbarTickLabelInterpreter', char(string(opt.TickInterpreter))); catch, end
end

for i = 1:numel(axs)
    ax = axs(i);
    if ~isgraphics(ax), continue; end

    try, ax.Box = opt.Box; catch, end
    try, ax.TickLabelInterpreter = char(string(opt.TickInterpreter)); catch, end
    try, ax.FontSize = opt.FontSize; catch, end
    try, ax.LineWidth = 1.0; catch, end
    try, ax.Toolbar.Visible = 'off'; catch, end
    try, ax.Clipping = 'on'; catch, end

    try
        if strcmpi(char(string(opt.Grid)), 'on')
            grid(ax, 'on');
        elseif strcmpi(char(string(opt.Grid)), 'off')
            grid(ax, 'off');
        elseif strlength(string(opt.Grid)) > 0
            grid(ax, char(string(opt.Grid)));
        end
    catch
    end

    if strlength(string(opt.AxisMode)) > 0
        try, axis(ax, char(string(opt.AxisMode))); catch, end
    end

    if ~isempty(opt.Title)
        try
            title(ax, opt.Title, ...
                'Interpreter', char(string(opt.Interpreter)), ...
                'FontSize', opt.TitleFontSize, ...
                'FontWeight', 'normal');
            ax.Title.Units = 'normalized';
            ax.Title.Position(2) = ax.Title.Position(2) + 0.040;
            % Shrink data area height ~8% to create room at top for the
            % raised title, keeping it inside OuterPosition / UIAxes bounds.
            % Skipped when axes is inside a TiledChartLayout (not supported).
            if isempty(ancestor(ax, 'tiledlayout'))
                try
                    ax.Units = 'normalized';
                    p = ax.Position;
                    ax.Position = [p(1), p(2), p(3), p(4) * 0.92];
                catch, end
            end
        catch
            title(ax, regexprep(char(string(opt.Title)), '[$\\{}]', ''), ...
                'FontSize', opt.TitleFontSize, ...
                'FontWeight', 'normal');
            try
                ax.Title.Units = 'normalized';
                ax.Title.Position(2) = ax.Title.Position(2) + 0.040;
            catch, end
        end
    end

    if ~isempty(opt.XLabel)
        try
            xlabel(ax, opt.XLabel, 'Interpreter', char(string(opt.Interpreter)));
        catch
            xlabel(ax, char(string(opt.XLabel)));
        end
    end
    try, ax.XLabel.FontSize = opt.FontSize; catch, end

    if ~isempty(opt.YLabel)
        try
            ylabel(ax, opt.YLabel, 'Interpreter', char(string(opt.Interpreter)));
        catch
            ylabel(ax, char(string(opt.YLabel)));
        end
    end
    try, ax.YLabel.FontSize = opt.FontSize; catch, end

    if ~isempty(opt.ZLabel)
        try
            zlabel(ax, opt.ZLabel, 'Interpreter', char(string(opt.Interpreter)));
        catch
            zlabel(ax, char(string(opt.ZLabel)));
        end
    end
    try, ax.ZLabel.FontSize = opt.FontSize; catch, end

    if strlength(string(opt.Legend)) > 0 && ~strcmpi(char(string(opt.Legend)), 'none')
        try
            lgd = legend(ax, 'show');
            local_apply_legend_style(lgd, ...
                'Location', opt.LegendLocation, ...
                'NumColumns', opt.LegendNumColumns, ...
                'FontSize', opt.FontSize, ...
                'Interpreter', opt.Interpreter);
        catch
        end
    end
end

out = struct('figure', fig, 'axes', axs);
end

function lgd = local_apply_legend_style(lgd, varargin)
p = inputParser;
p.addParameter('Location', '', @(s) ischar(s) || isstring(s));
p.addParameter('Interpreter', 'latex', @(s) ischar(s) || isstring(s));
p.addParameter('FontSize', 26, @(v) isnumeric(v) && isscalar(v));
p.addParameter('NumColumns', [], @(v) isempty(v) || (isnumeric(v) && isscalar(v)));
p.parse(varargin{:});
opt = p.Results;

if nargin < 1 || isempty(lgd)
    lgd = legend('show');
elseif isgraphics(lgd, 'axes')
    lgd = legend(lgd, 'show');
end
if isempty(lgd) || ~isgraphics(lgd), return; end
try, lgd.Interpreter = char(string(opt.Interpreter)); catch, end
try, lgd.FontSize = opt.FontSize; catch, end
if strlength(string(opt.Location)) > 0
    try, lgd.Location = char(string(opt.Location)); catch, end
end
if ~isempty(opt.NumColumns)
    try, lgd.NumColumns = opt.NumColumns; catch, end
end
end
