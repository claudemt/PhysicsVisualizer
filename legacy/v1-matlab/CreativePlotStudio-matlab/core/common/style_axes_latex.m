function style_axes_latex(ax)
%STYLE_AXES_LATEX Apply a Times/LaTeX-like axis style safely.
if nargin < 1 || isempty(ax) || ~isgraphics(ax), return; end
try, ax.FontName = 'Times New Roman'; catch, end
try, ax.TickLabelInterpreter = 'latex'; catch, end
try, ax.LineWidth = 1.0; catch, end
try, ax.Box = 'on'; catch, end
end
