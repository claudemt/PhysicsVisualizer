% Plasma Clouds
% This script is executed by the GUI with variables: ax, style.
if ~exist('ax','var') || isempty(ax)
    figure('Color','w');
    ax = gca;
end
if ~exist('style','var') || isempty(style)
    style = 'default';
end
style = char(style);

art_fractal_physics_pick(ax,'Plasma Clouds','default');

try
    art_apply_recommended_view(ax,'Plasma Clouds');
catch
end

finalize_project_axes(ax,'Plasma Clouds');
