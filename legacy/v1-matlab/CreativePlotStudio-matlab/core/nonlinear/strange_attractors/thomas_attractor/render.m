% Thomas Attractor
% This script is executed by the GUI with variables: ax, style.
if ~exist('ax','var') || isempty(ax)
    figure('Color','w');
    ax = gca;
end
if ~exist('style','var') || isempty(style)
    style = 'default';
end
style = char(style);

v = style; if ~any(strcmpi(v,{'default','dark','zoom','minimal','vibrant','neon','detailed','bright'})), v='default'; end; nonlinear_more_math_pick(ax,'Chaotic Attractors','Thomas Attractor',v);

try
    nonlinear_apply_recommended_view(ax,'Thomas Attractor');
catch
end

finalize_project_axes(ax,'Thomas Attractor');
