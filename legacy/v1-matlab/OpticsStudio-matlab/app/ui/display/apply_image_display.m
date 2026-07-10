function apply_image_display(ax, image_data, cmap_name, scaling_mode, fixed_clim, axis_mode)
%APPLY_IMAGE_DISPLAY Display image data with switchable auto/fixed scaling.

if nargin < 6 || isempty(axis_mode)
    axis_mode = 'image';
end
if nargin < 5
    fixed_clim = [];
end
if nargin < 4 || isempty(scaling_mode)
    scaling_mode = 'fixed';
end
if nargin < 3
    cmap_name = 'gray';
end

imagesc(ax, image_data);
if strcmpi(axis_mode, 'tight')
    axis(ax, 'tight');
else
    axis(ax, 'tight');
end
apply_square_plot_box(ax);
colormap(ax, cmap_name);

if strcmpi(scaling_mode, 'fixed') && ~isempty(fixed_clim)
    if fixed_clim(1) == fixed_clim(end)
        delta = max(1e-6, abs(fixed_clim(1)) * 1e-6 + 1e-6);
        fixed_clim = [fixed_clim(1) - delta, fixed_clim(end) + delta];
    end
    clim(ax, fixed_clim);
else
    clim(ax, 'auto');
end
end
