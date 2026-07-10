% Clifford Attractor
% This script is executed by the GUI with variables: ax, style.
if ~exist('ax','var') || isempty(ax)
    figure('Color','w');
    ax = gca;
end
if ~exist('style','var') || isempty(style)
    style = 'default';
end
style = char(style);

nonlinear_online_pick(ax,'Clifford Attractor','default');

try
    nonlinear_apply_recommended_view(ax,'Clifford Attractor');
catch
end

finalize_project_axes(ax,'Clifford Attractor');
