% Gray-Scott Coral
% This script is executed by the GUI with variables: ax, style.
if ~exist('ax','var') || isempty(ax)
    figure('Color','w');
    ax = gca;
end
if ~exist('style','var') || isempty(style)
    style = 'default';
end
style = char(style);

v = style; if ~any(strcmpi(v,{'default','mitosis','worms'})), v='default'; end; fractals_online_pick(ax,'Gray-Scott Coral',v);

try
    fractals_apply_recommended_view(ax,'Gray Scott Coral');
catch
end

finalize_project_axes(ax,'Gray-Scott Coral');
