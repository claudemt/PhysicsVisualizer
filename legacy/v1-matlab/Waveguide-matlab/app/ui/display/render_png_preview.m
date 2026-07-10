function render_png_preview(ax, file_path)
%RENDER_PNG_PREVIEW Display a generated PNG without altering its embedded layout.

img = imread(file_path);
cla(ax);
image(ax, img);
axis(ax, 'image');
ax.XTick = [];
ax.YTick = [];
ax.Visible = 'off';
end
