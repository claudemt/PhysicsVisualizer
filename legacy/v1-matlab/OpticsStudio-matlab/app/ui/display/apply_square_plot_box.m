function apply_square_plot_box(ax)
%APPLY_SQUARE_PLOT_BOX Keep the visible plotting box square while allowing content scaling.

try
    pbaspect(ax, [1 1 1]);
catch
    try
        ax.PlotBoxAspectRatio = [1 1 1];
        ax.PlotBoxAspectRatioMode = 'manual';
    catch
    end
end

try
    ax.DataAspectRatioMode = 'auto';
catch
end
end
