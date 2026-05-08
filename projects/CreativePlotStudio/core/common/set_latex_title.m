function set_latex_title(ax, txt)
%SET_LATEX_TITLE Compact in-axes title for CreativePlotStudio previews.
% The original algorithms are preserved, but the old external axes title was
% clipped by the unified preview panel.  This title is drawn inside the axes
% so it remains visible after zoom/rotate/export.
if nargin < 1 || isempty(ax) || ~isgraphics(ax), return; end
if nargin < 2, txt = ''; end
if isstring(txt), txt = char(txt); end
clean = char(txt);
clean = regexprep(clean,'[\\{}_^$%#&~]','');

try, title(ax, ''); catch, end
try, delete(findall(ax,'Tag','CPSPlotTitle')); catch, end
if isempty(strtrim(clean)), return; end

try
    text(ax, 0.5, 0.985, clean, ...
        'Units','normalized', ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','top', ...
        'Interpreter','none', ...
        'FontName','Times New Roman', ...
        'FontSize',14, ...
        'FontWeight','normal', ...
        'Color',[0.08 0.08 0.08], ...
        'Tag','CPSPlotTitle', ...
        'Clipping','off');
catch
    try
        title(ax, clean, 'Interpreter','none', 'FontName','Times New Roman', 'FontSize',14, 'FontWeight','normal');
    catch
    end
end
end
