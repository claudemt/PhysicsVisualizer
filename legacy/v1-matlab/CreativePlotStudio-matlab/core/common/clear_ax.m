function clear_ax(ax)
%CLEAR_AX Reset axes safely.
if nargin < 1 || isempty(ax) || ~isgraphics(ax)
    figure('Color','w');
    ax = gca;
end
cla(ax,'reset');
hold(ax,'off');
try, ax.UserData = struct(); catch, end
end
