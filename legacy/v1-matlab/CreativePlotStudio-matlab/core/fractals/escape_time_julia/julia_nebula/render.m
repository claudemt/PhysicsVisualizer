% Julia Nebula
% This script is executed by the GUI with variables: ax, style.
if ~exist('ax','var') || isempty(ax)
    figure('Color','w');
    ax = gca;
end
if ~exist('style','var') || isempty(style)
    style = 'default';
end
style = char(style);

v = style; if ~any(strcmpi(v,{'default','dragon','spiral'})), v='default'; end; fractals_online_pick(ax,'Julia Nebula',v);

try
    fractals_apply_recommended_view(ax,'Julia Nebula');
catch
end

finalize_project_axes(ax,'Julia Nebula');
