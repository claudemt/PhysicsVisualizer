% Mandelbrot Garden
% This script is executed by the GUI with variables: ax, style.
if ~exist('ax','var') || isempty(ax)
    figure('Color','w');
    ax = gca;
end
if ~exist('style','var') || isempty(style)
    style = 'default';
end
style = char(style);

v = style; if ~any(strcmpi(v,{'default','deep zoom','seahorse valley'})), v='default'; end; fractals_online_pick(ax,'Mandelbrot Garden',v);

try
    fractals_apply_recommended_view(ax,'Mandelbrot Garden');
catch
end

finalize_project_axes(ax,'Mandelbrot Garden');
