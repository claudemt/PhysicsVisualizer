% Duffing Poincare
% This script is executed by the GUI with variables: ax, style.
if ~exist('ax','var') || isempty(ax)
    figure('Color','w');
    ax = gca;
end
if ~exist('style','var') || isempty(style)
    style = 'default';
end
style = char(style);

v = style; if ~any(strcmpi(v,{'default','dark','electric'})), v='default'; end; nonlinear_fractal_physics_pick(ax,'Duffing Poincare',v);

try
    nonlinear_apply_recommended_view(ax,'Duffing Poincare');
catch
end

finalize_project_axes(ax,'Duffing Poincare');
