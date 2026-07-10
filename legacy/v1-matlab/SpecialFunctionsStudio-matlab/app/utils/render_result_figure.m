function render_result_figure(result, output_png, varargin)
p = inputParser;
p.addParameter('Crop', []);
p.addParameter('DPI', 180);
p.addParameter('RenderOptions', struct());
p.addParameter('LegendLocation', 'northwest');
p.addParameter('TitlePosition', 1.06);
p.addParameter('FontName', 'Times New Roman');
p.parse(varargin{:});
opt = p.Results;

render_options = opt.RenderOptions;
if ~isstruct(render_options)
    render_options = struct();
end
if ~isfield(render_options, 'legend_location') || isempty(render_options.legend_location)
    render_options.legend_location = opt.LegendLocation;
end
if ~isfield(render_options, 'title_position') || isempty(render_options.title_position)
    render_options.title_position = opt.TitlePosition;
end
if ~isfield(render_options, 'font_name') || isempty(render_options.font_name)
    render_options.font_name = opt.FontName;
end

set(groot,'defaultTextInterpreter','latex');
set(groot,'defaultAxesTickLabelInterpreter','latex');
set(groot,'defaultLegendInterpreter','latex');

kind = lower(char(result.kind));
switch kind
    case '1d'
        local_render_1d(result, output_png, opt.Crop, opt.DPI, render_options);
    case {'2d','heatmap','map'}
        local_render_heatmap(result, output_png, opt.DPI, render_options);
    case '3d'
        local_render_3d(result, output_png, opt.DPI, render_options);
    otherwise
        error('Unknown result kind: %s', result.kind);
end
end

function local_render_1d(result, output_png, crop, dpi, render_options)
fig = figure('Visible','off','Color','w','Position',[20 20 1250 800]);
ax = axes(fig);
hold(ax,'on');

allx = [];
ally = [];

for k = 1:numel(result.curves)
    c = result.curves{k};
    plot(ax,c.x,c.y,'LineWidth',1.8,'DisplayName',c.label);
    allx = [allx c.x(:).']; %#ok<AGROW>
    ally = [ally c.y(:).']; %#ok<AGROW>
end

[xl,yl] = image_output('crop_limits', allx, ally, crop);
xlim(ax,xl);
ylim(ax,yl);

grid(ax,'on');
box(ax,'on');

ax.FontName = render_options.font_name;
ax.FontSize = 14;
ax.LineWidth = 1.0;

xlabel(ax,result.xlabel,'Interpreter','latex','FontSize',16);
ylabel(ax,result.ylabel,'Interpreter','latex','FontSize',16);
title(ax,result.title,'Interpreter','latex','FontSize',18);

lgd = legend(ax,'Location',render_options.legend_location,'Interpreter','latex');
lgd.FontSize = 14;

if numel(result.curves) > 8
    lgd.NumColumns = 2;
else
    lgd.NumColumns = 1;
end

local_ensure_parent(output_png);
exportgraphics(fig,output_png,'Resolution',dpi,'BackgroundColor','white');
close(fig);
end

function local_render_heatmap(result, output_png, dpi, render_options)
fig = figure('Visible','off','Color','w','Position',[20 20 1000 820]);
ax = axes(fig);
args = {};
if isfield(result, 'normalize'), args = [args, {'Normalize', result.normalize}]; end
if isfield(result, 'clim'), args = [args, {'CLim', result.clim}]; end
if isfield(result, 'mask'), args = [args, {'Mask', result.mask}]; end
if isfield(result, 'colormap'), args = [args, {'Colormap', result.colormap}]; end
if isfield(result, 'colorbar_label'), args = [args, {'ColorbarLabel', result.colorbar_label}]; end
if isfield(result, 'zero_contour'), args = [args, {'ZeroContour', result.zero_contour}]; end
apply_heatmap_style(ax, result.x, result.y, result.Z, ...
    'Title', local_get_field(result, 'title', ''), ...
    'XLabel', local_get_field(result, 'xlabel', '$x$'), ...
    'YLabel', local_get_field(result, 'ylabel', '$y$'), ...
    args{:});
local_ensure_parent(output_png);
exportgraphics(fig, output_png, 'Resolution', dpi, 'BackgroundColor', 'white');
close(fig);
end

function local_render_3d(result, output_png, dpi, render_options)
N = numel(result.items);
layout_text = char(string(local_get_field(result, 'layout_text', '4')));
row_counts = image_output('parse_layout', layout_text, N);
rows = numel(row_counts);

if isempty(strtrim(char(string(layout_text)))) || strcmp(strtrim(char(string(layout_text))),'4')
    cols = 4;
else
    cols = max(row_counts);
end

panel_w = 170;
panel_h = 520;
outer_w = 14;
outer_h = 30;

fig_w = max(420, outer_w + cols * panel_w);
fig_h = max(600, outer_h + rows * panel_h);

fig = figure('Visible','off','Color','w','Position',[20 20 fig_w fig_h]);

left_margin   = 0.010;
right_margin  = 0.010;
top_margin    = 0.045;
bottom_margin = 0.020;
hgap          = 0.004;
vgap          = 0.040;

cell_w = (1 - left_margin - right_margin - (cols-1)*hgap) / cols;
cell_h = (1 - top_margin - bottom_margin - (rows-1)*vgap) / rows;

if isfield(result,'common_limits') && numel(result.common_limits) == 3
    XLim = result.common_limits{1};
    YLim = result.common_limits{2};
    ZLim = result.common_limits{3};
else
    limits = image_output('common_3d_limits', result.items);
    XLim = limits{1};
    YLim = limits{2};
    ZLim = limits{3};
end

item_idx = 1;

for r = 1:rows
    y_cell = 1 - top_margin - r*cell_h - (r-1)*vgap;
    n_this = row_counts(r);

    for c = 1:cols
        x_cell = left_margin + (c-1) * (cell_w + hgap);

        if c <= n_this && item_idx <= N
            item = result.items{item_idx};

            cell_slot = [x_cell, y_cell, cell_w, cell_h];

            ax = axes('Parent',fig,'Units','normalized');

            try
                ax.PositionConstraint = 'outerposition';
            catch
                ax.ActivePositionProperty = 'outerposition';
            end

            ax.OuterPosition = cell_slot;

            local_draw_one_3d(ax,item);

            axis(ax,'equal');
            xlim(ax,XLim);
            ylim(ax,YLim);
            zlim(ax,ZLim);

            view(ax,[-37.5 24]);
            grid(ax,'on');
            box(ax,'on');

            ax.FontName = render_options.font_name;
            ax.FontSize = 10.2;
            ax.LineWidth = 0.8;
            ax.TickLabelInterpreter = 'latex';

            xlabel(ax,'');
            ylabel(ax,'');
            zlabel(ax,'');

            th = title(ax,item.title, ...
                'Interpreter','latex', ...
                'FontSize',11.5, ...
                'FontName',render_options.font_name);

            th.Units = 'normalized';
            th.Position(2) = render_options.title_position;

            item_idx = item_idx + 1;
        end
    end
end

local_ensure_parent(output_png);
exportgraphics(fig,output_png,'Resolution',dpi,'BackgroundColor','white');
close(fig);
end

function local_draw_one_3d(ax,item)
switch item.kind
    case 'surface'
        surf(ax,item.x,item.y,item.z,item.c, ...
            'EdgeColor','none', ...
            'FaceAlpha',1.0);

        axes(ax); %#ok<LAXES>
        shading interp;
        colormap(ax,parula(256));
        camlight headlight;
        lighting gouraud;

    case 'vectorfield'
        surf(ax,item.sphere_x,item.sphere_y,item.sphere_z,item.c, ...
            'EdgeColor','none', ...
            'FaceAlpha',0.88);

        hold(ax,'on');

        quiver3(ax,item.xq,item.yq,item.zq, ...
            item.uq,item.vq,item.wq,0.75, ...
            'LineWidth',0.8, ...
            'Color',[0.10 0.10 0.10]);

        axes(ax); %#ok<LAXES>
        shading interp;
        colormap(ax,turbo(256));
        camlight headlight;
        lighting gouraud;

    otherwise
        error('Unknown 3D item kind: %s',item.kind);
end
end

function local_ensure_parent(pathname)
folder = fileparts(pathname);
if ~isempty(folder) && exist(folder, 'dir') ~= 7
    mkdir(folder);
end
end

function v = local_get_field(s, name, default_value)
if isfield(s, name)
    v = s.(name);
else
    v = default_value;
end
end
