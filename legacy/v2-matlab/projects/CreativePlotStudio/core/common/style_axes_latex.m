function style_axes_latex(ax)
%STYLE_AXES_LATEX Apply a Times/LaTeX-like axis style safely.
if nargin < 1 || isempty(ax) || ~isgraphics(ax), return; end
studio_style('apply_axes', ax, 'Box', 'on');
end
