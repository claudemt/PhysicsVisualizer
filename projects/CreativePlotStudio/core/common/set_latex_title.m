function set_latex_title(ax, txt)
%SET_LATEX_TITLE Compact title for CreativePlotStudio previews.
% Live previews keep a lightweight axes title. Exports use image_output's
% title-band path so smart cropping cannot cut the title away.
if nargin < 1 || isempty(ax) || ~isgraphics(ax), return; end
if nargin < 2, txt = ''; end
if isstring(txt), txt = char(txt); end
clean = char(txt);
clean = regexprep(clean,'[\\{}_^$%#&~]','');
style = studio_style('tokens');

try, title(ax, ''); catch, end
try, delete(findall(ax,'Tag','CPSPlotTitle')); catch, end
try, delete(findall(ancestor(ax,'figure'),'Tag','CPSFigureTitle')); catch, end
if isempty(strtrim(clean)), return; end

try
    fig = ancestor(ax, 'figure');
    if ~isempty(fig) && isgraphics(fig)
        setappdata(fig, 'CPSExportTitle', clean);
    end
catch
end

try
    oldUnits = ax.Units;
    ax.Units = 'normalized';
    pos = ax.Position;
    if numel(pos) >= 4
        topLimit = 0.82;
        minHeight = 0.24;
        pos(2) = max(pos(2), 0.08);
        pos(4) = max(minHeight, topLimit - pos(2));
        ax.Position = pos;
        try, ax.PositionConstraint = 'innerposition'; catch, end
    end
    ax.Units = oldUnits;
catch
end

try
    text(ax, 0.5, 1.018, clean, ...
        'Units','normalized', ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', ...
        'Interpreter','none', ...
        'FontName',style.axesFontName, ...
        'FontSize',style.axesFontSize, ...
        'FontWeight','normal', ...
        'Color',[0.08 0.08 0.08], ...
        'Tag','CPSPlotTitle', ...
        'Clipping','off');
catch
end

try
    fig = ancestor(ax, 'figure');
    if ~isempty(fig) && isgraphics(fig)
        annotation(fig, 'textbox', [0.02 0.875 0.96 0.085], ...
            'String', clean, ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','middle', ...
            'Interpreter','none', ...
            'FontName',style.axesFontName, ...
            'FontSize',style.axesFontSize, ...
            'FontWeight','normal', ...
            'Color',[0.08 0.08 0.08], ...
            'LineStyle','none', ...
            'Tag','CPSFigureTitle');
    end
catch
end
end
