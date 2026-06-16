function varargout = render_result(action, varargin)
%RENDER_RESULT Shared result-block creation and rendering.
%
% This old-style revision keeps the 8-file architecture while restoring the
% earlier projects' visual details: visible-spectrum heatmaps by default,
% signed/positive normalization aliases, old heatmap overlay parameters,
% label-first curve legends, crop/render options, and 3-D result support.

action = lower(char(string(action)));
switch action
    case {'heatmap','map','field','2d'}
        varargout{1} = local_heatmap_block(varargin{:});
    case {'streamline','stream','vectorstream'}
        varargout{1} = local_streamline_block(varargin{:});
    case {'curve','1d'}
        varargout{1} = local_curve_block(varargin{:});
    case 'bundle'
        varargout{1} = local_bundle(varargin{:});
    case {'render','figure','to_file'}
        varargout{1} = local_render_to_target(varargin{:});
    case {'axes','draw','render_axes'}
        local_render_axes(varargin{:});
        varargout = {};
    case {'style_heatmap','apply_heatmap_style'}
        info = local_draw_heatmap(varargin{:});
        if nargout > 0, varargout{1} = info; end
    case {'image_display','apply_image_display'}
        info = local_image_display(varargin{:});
        if nargout > 0, varargout{1} = info; end
    case {'colormap_interp','color_interp','palette_interp'}
        varargout{1} = local_colormap_interp(varargin{:});
    case {'colorbar','style_colorbar'}
        varargout{1} = local_style_colorbar(varargin{:});
    case {'legend','style_legend'}
        varargout{1} = local_style_legend(varargin{:});
    case 'make_curve_result'
        varargout{1} = local_make_curve_result(varargin{:});
    case 'arg_matrix'
        varargout{1} = local_arg_matrix(varargin{:});
    case 'column'
        varargout{1} = local_column(varargin{:});
    otherwise
        error('Unknown render_result action: %s', action);
end
end

% -------------------------------------------------------------------------
% Block constructors
% -------------------------------------------------------------------------

function item = local_heatmap_block(x, y, Z, varargin)
p = inputParser;
p.addParameter('Title', '');
p.addParameter('XLabel', '$x$');
p.addParameter('YLabel', '$y$');
p.addParameter('ColorbarLabel', '');
p.addParameter('ColorbarLocation', 'eastoutside');
p.addParameter('Normalize', 'none');
p.addParameter('AutoSymmetric', false);
p.addParameter('Mask', []);
p.addParameter('ZeroContour', false);
p.addParameter('CLim', []);
p.addParameter('Colormap', []);
p.addParameter('SourcePoints', []);
p.addParameter('CircleRadii', []);
p.addParameter('OverlayCircleRadius', []);
p.addParameter('BoundaryZeroEdges', []);
p.addParameter('OverlayLines', []);
p.addParameter('Trajectory', []);
p.addParameter('AxisMode', 'image');
p.addParameter('Filename', '');
p.parse(varargin{:});
opt = p.Results;

radii = opt.CircleRadii;
if isempty(radii)
    radii = opt.OverlayCircleRadius;
end

item = struct();
item.kind = 'heatmap';
item.x = x;
item.y = y;
item.Z = Z;
item.title = opt.Title;
item.xlabel = opt.XLabel;
item.ylabel = opt.YLabel;
item.colorbarLabel = opt.ColorbarLabel;
item.colorbarLocation = opt.ColorbarLocation;
item.normalize = opt.Normalize;
item.autoSymmetric = opt.AutoSymmetric;
item.mask = opt.Mask;
item.zeroContour = opt.ZeroContour;
item.CLim = opt.CLim;
item.colormap = opt.Colormap;
item.sourcePoints = opt.SourcePoints;
item.circleRadii = radii;
item.boundaryZeroEdges = opt.BoundaryZeroEdges;
item.overlayLines = opt.OverlayLines;
item.trajectory = opt.Trajectory;
item.axisMode = opt.AxisMode;
item.filename = opt.Filename;
end

function item = local_streamline_block(x, y, C, U, V, varargin)
p = inputParser;
p.addParameter('Title', '');
p.addParameter('XLabel', '$x$');
p.addParameter('YLabel', '$y$');
p.addParameter('ColorbarLabel', '');
p.addParameter('ColorbarLocation', 'eastoutside');
p.addParameter('Normalize', 'none');
p.addParameter('AutoSymmetric', false);
p.addParameter('Mask', []);
p.addParameter('CLim', []);
p.addParameter('Colormap', []);
p.addParameter('SeedPoints', []);
p.addParameter('SeedRadius', []);
p.addParameter('SeedCount', 64);
p.addParameter('SourcePoints', []);
p.addParameter('Trajectory', []);
p.addParameter('LineWidth', 1.25);
p.addParameter('AxisMode', 'image');
p.addParameter('Filename', '');
p.parse(varargin{:});
opt = p.Results;

item = struct();
item.kind = 'streamline';
item.x = x;
item.y = y;
item.C = C;
item.Z = C;
item.U = U;
item.V = V;
item.title = opt.Title;
item.xlabel = opt.XLabel;
item.ylabel = opt.YLabel;
item.colorbarLabel = opt.ColorbarLabel;
item.colorbarLocation = opt.ColorbarLocation;
item.normalize = opt.Normalize;
item.autoSymmetric = opt.AutoSymmetric;
item.mask = opt.Mask;
item.CLim = opt.CLim;
item.colormap = opt.Colormap;
item.seedPoints = opt.SeedPoints;
item.seedRadius = opt.SeedRadius;
item.seedCount = opt.SeedCount;
item.sourcePoints = opt.SourcePoints;
item.trajectory = opt.Trajectory;
item.lineWidth = opt.LineWidth;
item.axisMode = opt.AxisMode;
item.filename = opt.Filename;
end

function item = local_curve_block(curves, varargin)
p = inputParser;
p.addParameter('Title', '');
p.addParameter('XLabel', '$x$');
p.addParameter('YLabel', '$y$');
p.addParameter('XLim', []);
p.addParameter('YLim', []);
p.addParameter('LegendLocation', 'best');
p.addParameter('Legend', 'show');
p.addParameter('Filename', '');
p.parse(varargin{:});
opt = p.Results;

item = struct();
item.kind = 'curve';
item.curves = curves;
item.title = opt.Title;
item.xlabel = opt.XLabel;
item.ylabel = opt.YLabel;
item.xLim = opt.XLim;
item.yLim = opt.YLim;
item.legendLocation = opt.LegendLocation;
item.legend = opt.Legend;
item.filename = opt.Filename;
end

function bundle = local_bundle(items)
if nargin == 0
    items = {};
end
if isstruct(items) && ~iscell(items)
    items = num2cell(items);
end
bundle = struct('kind','bundle','items',{items});
end

% -------------------------------------------------------------------------
% Rendering
% -------------------------------------------------------------------------

function png_paths = local_render_to_target(result, out_target, varargin)
p = inputParser;
p.addParameter('DPI', 260);
p.addParameter('Prefix', 'result');
p.addParameter('LegendLocation', 'best');
p.addParameter('Layout', 'auto');
p.addParameter('Crop', []);
p.addParameter('RenderOptions', struct());
p.parse(varargin{:});
opt = p.Results;

if nargin < 2 || isempty(out_target), out_target = pwd; end
out_target = char(string(out_target));
[folder, ~, ext] = fileparts(out_target);
is_single_file = ~isempty(ext) && any(strcmpi(ext, {'.png','.jpg','.jpeg','.tif','.tiff','.pdf'}));

if is_single_file
    if isempty(folder), folder = pwd; end
    if exist(folder, 'dir') ~= 7, mkdir(folder); end
    local_render_file(result, out_target, opt);
    png_paths = {out_target};
    return;
end

out_dir = out_target;
if exist(out_dir, 'dir') ~= 7, mkdir(out_dir); end
jobs = local_render_jobs(result, opt.Prefix);
png_paths = cell(1, numel(jobs));
for i = 1:numel(jobs)
    item = jobs{i};
    name = local_get(item, 'filename', '');
    if isempty(name)
        name = image_output('indexed_name', opt.Prefix, i, '.png');
    end
    png_paths{i} = fullfile(out_dir, name);
    local_render_file(item, png_paths{i}, opt);
end
end

function jobs = local_render_jobs(result, prefix)
kind = lower(char(string(local_get(result, 'kind', ''))));
if isstruct(result) && strcmp(kind, '3d') && isfield(result, 'items')
    items = local_cell_items(result.items);
    common_limits = local_common_3d_limits_cell(items);
    jobs = cell(1, numel(items));
    for k = 1:numel(items)
        single_item = items{k};
        item = struct('kind', '3d', 'items', {{single_item}}, 'layout_text', '1', 'common_limits', {common_limits});
        label = image_output('clean_label', local_get(single_item, 'title', sprintf('item_%d', k)));
        item.filename = image_output('indexed_name', [prefix '_' label], k, '.png');
        jobs{k} = item;
    end
elseif isstruct(result) && isfield(result, 'items') && ~strcmp(kind, '3d')
    jobs = local_cell_items(result.items);
    for kk = 1:numel(jobs)
        if isempty(local_get(jobs{kk}, 'filename', ''))
            title_text = local_get(jobs{kk}, 'title', '');
            if ~isempty(title_text)
                jobs{kk}.filename = image_output('indexed_name', image_output('clean_label', title_text), kk, '.png');
            end
        end
    end
elseif iscell(result)
    jobs = result;
else
    default_name = local_get(result, 'filename', '');
    if isempty(default_name)
        title_text = local_get(result, 'title', '');
        if ~isempty(title_text)
            default_name = image_output('indexed_name', image_output('clean_label', title_text), 1, '.png');
        else
            default_name = sprintf('01_%s.png', image_output('slug', prefix));
        end
    end
    result.filename = default_name;
    jobs = {result};
end
end

function local_render_file(result, output_path, opt)
fig = image_output('hidden_figure', 'Position', [100 100 1000 780]);
cleanup = onCleanup(@() local_safe_close(fig));
kind = lower(char(string(local_get(result, 'kind', 'heatmap'))));
try
    switch kind
        case {'1d','curve'}
            ax = axes('Parent', fig);
            local_draw_curve(ax, result, opt);
        case {'heatmap','map','field','2d'}
            ax = axes('Parent', fig);
            local_draw_heatmap(ax, result);
        case {'streamline','stream','vectorstream'}
            ax = axes('Parent', fig);
            local_draw_streamline(ax, result);
        case {'3d'}
            clf(fig);
            local_render_3d(fig, result, opt);
        case {'surface','vectorfield'}
            ax = axes('Parent', fig);
            local_draw_one_3d(ax, result);
            local_finish_3d_axes(ax, result, opt);
        otherwise
            ax = axes('Parent', fig);
            text(ax, 0.05, 0.95, sprintf('Unsupported result kind: %s', kind), 'Units', 'normalized');
            apply_tex_style(ax);
    end
    drawnow;
    try
        exportgraphics(fig, output_path, 'Resolution', opt.DPI, 'BackgroundColor', 'white', 'Padding', [5 5 5 5]);
    catch
        print(fig, output_path, '-dpng', sprintf('-r%d', opt.DPI));
    end
    image_output('auto_crop', output_path);
catch ME
    clear cleanup
    local_safe_close(fig);
    rethrow(ME);
end
clear cleanup
local_safe_close(fig);
end

function local_render_axes(ax, result, opt)
if nargin < 3, opt = struct(); end
kind = lower(char(string(local_get(result, 'kind', 'heatmap'))));
switch kind
    case {'heatmap','map','field','2d'}
        local_draw_heatmap(ax, result);
    case {'streamline','stream','vectorstream'}
        local_draw_streamline(ax, result);
    case {'curve','1d'}
        local_draw_curve(ax, result, opt);
    case {'surface','vectorfield'}
        local_draw_one_3d(ax, result);
        local_finish_3d_axes(ax, result, opt);
    case {'3d'}
        items = local_cell_items(local_get(result, 'items', {}));
        if ~isempty(items)
            local_draw_one_3d(ax, items{1});
            local_finish_3d_axes(ax, items{1}, opt);
        end
    otherwise
        error('Unsupported result kind: %s', kind);
end
end

% -------------------------------------------------------------------------
% Heatmap and streamline
% -------------------------------------------------------------------------

function info = local_draw_heatmap(ax, varargin)
% local_draw_heatmap(ax, block) or local_draw_heatmap(ax, x, y, Z, ...)
if numel(varargin) == 1 && isstruct(varargin{1})
    item = varargin{1};
else
    item = local_heatmap_block(varargin{:});
end

x = local_get(item, 'x', []);
y = local_get(item, 'y', []);
Z = local_get(item, 'Z', []);
Zraw = real(Z);
normalize_mode = local_get(item, 'Normalize', local_get(item, 'normalize', 'none'));
auto_symmetric = local_get(item, 'AutoSymmetric', local_get(item, 'autoSymmetric', false));
fixed_clim = local_get(item, 'CLim', []);
[Zplot, clim] = local_prepare_scalar(Z, normalize_mode, auto_symmetric, fixed_clim);

mask = local_get(item, 'Mask', local_get(item, 'mask', []));
if ~isempty(mask)
    mask = logical(mask);
    Zplot(~mask) = NaN;
end

[xv, yv] = local_axis_vectors(x, y, Zplot);
cla(ax);
hold(ax, 'on');
h = imagesc(ax, xv, yv, Zplot);
set(ax, 'YDir', 'normal');
if ~isempty(mask)
    try
        set(h, 'AlphaData', double(mask), 'AlphaDataMapping', 'none');
    catch
    end
end

cmap = local_get(item, 'Colormap', local_get(item, 'colormap', []));
if ~isempty(cmap)
    colormap(ax, cmap);
else
    colormap(ax, local_visible_colormap(256));
end
if ~isempty(clim)
    local_clim(ax, clim);
end

colorbar_location = local_get(item, 'ColorbarLocation', local_get(item, 'colorbarLocation', 'eastoutside'));
if ~strcmpi(char(string(colorbar_location)), 'none')
    cb = colorbar(ax, char(string(colorbar_location)));
    cb.TickLabelInterpreter = 'latex';
    cb.FontSize = 26;
    label = local_get(item, 'ColorbarLabel', local_get(item, 'colorbarLabel', local_get(item, 'colorbar_label', '')));
    if ~isempty(label)
        cb.Label.String = local_latex_label(label);
        cb.Label.Interpreter = 'latex';
        cb.Label.FontSize = 30;
    end
else
    cb = [];
end

zero = local_get(item, 'ZeroContour', local_get(item, 'zeroContour', local_get(item, 'zero_contour', false)));
if logical(zero) && local_has_zero(Zraw, mask)
    try, contour(ax, xv, yv, Zraw, [0 0], 'k-', 'LineWidth', 1.0); catch, end
end

boundary_edges = local_get(item, 'BoundaryZeroEdges', local_get(item, 'boundaryZeroEdges', []));
if ~isempty(boundary_edges)
    local_draw_boundary_edges(ax, xv, yv, boundary_edges);
end

radii = local_get(item, 'OverlayCircleRadius', local_get(item, 'circleRadii', local_get(item, 'CircleRadii', [])));
if ~isempty(radii)
    th = linspace(0, 2*pi, 800);
    for r = radii(:).'
        plot(ax, r*cos(th), r*sin(th), 'k-', 'LineWidth', 1.0);
    end
end

overlay = local_get(item, 'overlayLines', []);
if ~isempty(overlay) && iscell(overlay)
    for kk = 1:numel(overlay)
        pts = overlay{kk};
        if size(pts,2) >= 2
            plot(ax, pts(:,1), pts(:,2), 'k-', 'LineWidth', 1.0);
        end
    end
end

source = local_get(item, 'SourcePoints', local_get(item, 'sourcePoints', []));
if ~isempty(source) && size(source,2) >= 2
    plot(ax, source(:,1), source(:,2), 'ko', 'MarkerFaceColor', 'w', 'MarkerSize', 5);
end

traj = local_get(item, 'Trajectory', local_get(item, 'trajectory', []));
if ~isempty(traj) && size(traj,2) >= 2
    plot(ax, traj(:,1), traj(:,2), 'k-', 'LineWidth', 1.0);
end

axis_mode = local_get(item, 'AxisMode', local_get(item, 'axisMode', 'image'));
try, axis(ax, char(string(axis_mode))); catch, end
apply_tex_style(ax, ...
    'Title', local_get(item, 'Title', local_get(item, 'title', '')), ...
    'XLabel', local_get(item, 'XLabel', local_get(item, 'xlabel', '$x$')), ...
    'YLabel', local_get(item, 'YLabel', local_get(item, 'ylabel', '$y$')), ...
    'AxisMode', axis_mode, ...
    'Box', 'on');
hold(ax, 'off');

info = struct('image', h, 'colorbar', cb, 'CLim', clim, 'ax', ax);
end

function info = local_draw_streamline(ax, item)
C = local_get(item, 'C', local_get(item, 'Z', []));
x = local_get(item, 'x', []);
y = local_get(item, 'y', []);
U = local_get(item, 'U', []);
V = local_get(item, 'V', []);
[xv, yv] = local_axis_vectors(x, y, C);

heat = item;
heat.kind = 'heatmap';
heat.Z = C;
info = local_draw_heatmap(ax, heat);
hold(ax, 'on');

U0 = real(U);
V0 = real(V);
U0(~isfinite(U0)) = 0;
V0(~isfinite(V0)) = 0;
mag = hypot(U0, V0);
ref = local_finite_quantile(mag, 0.98);
if ~isfinite(ref) || ref <= 0
    ref = local_finite_max(mag);
end
if isfinite(ref) && ref > 0
    Uplot = U0 ./ max(mag, ref*0.02);
    Vplot = V0 ./ max(mag, ref*0.02);
else
    Uplot = U0;
    Vplot = V0;
end

seed_points = local_get(item, 'SeedPoints', local_get(item, 'seedPoints', []));
if isempty(seed_points)
    seed_points = local_default_seeds(item, xv, yv);
end

try
    streams = stream2(xv, yv, Uplot, Vplot, seed_points(:,1), seed_points(:,2));
catch
    streams = {};
end

line_width = local_get(item, 'LineWidth', local_get(item, 'lineWidth', 1.25));
for i = 1:numel(streams)
    xy = streams{i};
    if size(xy,1) < 2, continue; end
    xi = xy(:,1);
    yi = xy(:,2);
    ci = interp2(xv, yv, C, xi, yi, 'linear', NaN);
    good = isfinite(ci);
    if nnz(good) < 2, continue; end
    xi = xi(good);
    yi = yi(good);
    ci = ci(good);
    surface(ax, [xi xi], [yi yi], zeros(numel(xi),2), [ci ci], ...
        'FaceColor', 'none', ...
        'EdgeColor', 'interp', ...
        'LineWidth', line_width);
end
hold(ax, 'off');
end

function seed_points = local_default_seeds(item, xv, yv)
source = local_get(item, 'SourcePoints', local_get(item, 'sourcePoints', []));
n = local_get(item, 'SeedCount', local_get(item, 'seedCount', 64));
radius = local_get(item, 'SeedRadius', local_get(item, 'seedRadius', []));
if isempty(radius)
    radius = 0.08 * max([range(xv), range(yv), 1]);
end
if ~isempty(source) && size(source,2) >= 2
    center = source(1,1:2);
    th = linspace(0, 2*pi, n+1).';
    th(end) = [];
    seed_points = [center(1) + radius*cos(th), center(2) + radius*sin(th)];
else
    nx = max(6, ceil(sqrt(n)));
    ny = max(6, ceil(n/nx));
    sx = linspace(min(xv), max(xv), nx);
    sy = linspace(min(yv), max(yv), ny);
    [SX, SY] = meshgrid(sx, sy);
    seed_points = [SX(:), SY(:)];
end
end

function [Z, clim] = local_prepare_scalar(Z, normalize_mode, auto_symmetric, fixed_clim)
Z = real(Z);
Z(~isfinite(Z)) = NaN;
clim = fixed_clim;
mode = lower(char(string(normalize_mode)));

switch mode
    case {'signed','signed-unit','maxabs'}
        m = max(abs(Z(:)), [], 'omitnan');
        if ~isfinite(m) || m < eps, m = 1; end
        Z = Z ./ m;
        if isempty(clim), clim = [-1 1]; end
    case {'positive','positive-unit'}
        m = max(abs(Z(:)), [], 'omitnan');
        if ~isfinite(m) || m < eps, m = 1; end
        Z = Z ./ m;
        if isempty(clim), clim = [0 1]; end
    case {'max','unit'}
        m = max(Z(:), [], 'omitnan');
        if isfinite(m) && m > 0, Z = Z ./ m; end
        if isempty(clim), clim = [0 1]; end
    case 'log'
        if auto_symmetric
            A = abs(Z);
            ref = local_finite_quantile(A, 0.998);
            if ~isfinite(ref) || ref <= 0, ref = local_finite_max(A); end
            if isfinite(ref) && ref > 0
                A = log1p(40 * min(A, ref) / ref) / log1p(40);
            end
            Z = sign(Z).*A;
            if isempty(clim), clim = [-1 1]; end
        else
            Z(Z < 0) = 0;
            ref = local_finite_quantile(Z, 0.998);
            if ~isfinite(ref) || ref <= 0, ref = local_finite_max(Z); end
            if isfinite(ref) && ref > 0
                Z = log1p(40 * min(Z, ref) / ref) / log1p(40);
            end
            if isempty(clim), clim = [0 1]; end
        end
    otherwise
        % none
end

if ~isempty(fixed_clim)
    clim = fixed_clim;
elseif auto_symmetric && isempty(clim)
    m = max(abs(Z(:)), [], 'omitnan');
    if ~isfinite(m) || m <= 0, m = 1; end
    clim = [-m m];
elseif isempty(clim)
    mn = min(Z(:), [], 'omitnan');
    mx = max(Z(:), [], 'omitnan');
    if isfinite(mn) && isfinite(mx) && mn ~= mx
        clim = [mn mx];
    end
end
end

function tf = local_has_zero(Z, mask)
if isempty(mask)
    vals = Z(isfinite(Z));
else
    vals = Z(logical(mask) & isfinite(Z));
end
if isempty(vals)
    tf = false;
else
    tf = min(vals) <= 0 && max(vals) >= 0;
end
end

function local_draw_boundary_edges(ax, x, y, edges)
if isstruct(edges)
    if isfield(edges, 'left') && edges.left, plot(ax, [x(1) x(1)], [y(1) y(end)], 'k-', 'LineWidth', 1.0); end
    if isfield(edges, 'right') && edges.right, plot(ax, [x(end) x(end)], [y(1) y(end)], 'k-', 'LineWidth', 1.0); end
    if isfield(edges, 'bottom') && edges.bottom, plot(ax, [x(1) x(end)], [y(1) y(1)], 'k-', 'LineWidth', 1.0); end
    if isfield(edges, 'top') && edges.top, plot(ax, [x(1) x(end)], [y(end) y(end)], 'k-', 'LineWidth', 1.0); end
end
end

function local_clim(ax, limits)
try
    clim(ax, limits);
catch
    caxis(ax, limits);
end
end

function cmap = local_visible_colormap(n)
%LOCAL_VISIBLE_COLORMAP Visible-spectrum colormap (380--780 nm), gamma corrected.
% Matches the project-visible-spectrum rule used in the original heatmap
% utilities rather than MATLAB's parula default.
if nargin < 1 || isempty(n), n = 256; end
lambda = linspace(380, 780, n);
rgb = zeros(n, 3);

for ii = 1:n
    l = lambda(ii);

    if l >= 380 && l < 440
        r = -(l - 440) / (440 - 380); g = 0; b = 1;
    elseif l >= 440 && l < 490
        r = 0; g = (l - 440) / (490 - 440); b = 1;
    elseif l >= 490 && l < 510
        r = 0; g = 1; b = -(l - 510) / (510 - 490);
    elseif l >= 510 && l < 580
        r = (l - 510) / (580 - 510); g = 1; b = 0;
    elseif l >= 580 && l < 645
        r = 1; g = -(l - 645) / (645 - 580); b = 0;
    elseif l >= 645 && l <= 780
        r = 1; g = 0; b = 0;
    else
        r = 0; g = 0; b = 0;
    end

    if l >= 380 && l < 420
        f = 0.3 + 0.7*(l - 380)/(420 - 380);
    elseif l >= 420 && l <= 700
        f = 1.0;
    elseif l > 700 && l <= 780
        f = 0.3 + 0.7*(780 - l)/(780 - 700);
    else
        f = 0.0;
    end

    gamma = 0.8;
    rgb(ii, :) = (f .* [r g b]) .^ gamma;
end
cmap = rgb;
end

function s = local_latex_label(s)
s = char(string(s));
s = strrep(s, '\\', '\');
end

% -------------------------------------------------------------------------
% Curves
% -------------------------------------------------------------------------

function local_draw_curve(ax, result, opt)
cla(ax);
hold(ax, 'on');
curves = local_get(result, 'curves', {});
curves = local_cell_items(curves);
allx = [];
ally = [];
legend_entries = {};
for i = 1:numel(curves)
    c = curves{i};
    if ~isstruct(c), continue; end
    if isfield(c,'x'), x = c.x; else, x = 1:numel(c.y); end
    if isfield(c,'y'), y = c.y; else, continue; end
    if isfield(c,'style'), style = c.style; else, style = '-'; end
    line_width = local_get(c,'LineWidth', local_get(c,'lineWidth',1.6));
    name = '';
    if isfield(c, 'label') && ~isempty(c.label)
        name = c.label;
    elseif isfield(c, 'name') && ~isempty(c.name)
        name = c.name;
    end
    if isempty(name)
        plot(ax, x, y, style, 'LineWidth', line_width);
    else
        plot(ax, x, y, style, 'LineWidth', line_width, 'DisplayName', name);
        legend_entries{end+1} = name; %#ok<AGROW>
    end
    allx = [allx x(:).']; %#ok<AGROW>
    ally = [ally y(:).']; %#ok<AGROW>
end
hold(ax, 'off');

if isstruct(opt) && isfield(opt, 'Crop') && ~isempty(opt.Crop) && ~isempty(allx) && ~isempty(ally)
    [xl, yl, do_crop] = local_curve_crop_limits(allx, ally, opt.Crop);
    if do_crop
        xlim(ax, xl);
        ylim(ax, yl);
    end
end

xl = local_get(result, 'xLim', []);
if ~isempty(xl)
    xlim(ax, xl);
end
yl = local_get(result, 'yLim', []);
if ~isempty(yl)
    ylim(ax, yl);
end

legend_location = local_get(result, 'legendLocation', local_get(opt, 'LegendLocation', 'best'));
if isstruct(opt) && isfield(opt, 'RenderOptions') && isstruct(opt.RenderOptions) && isfield(opt.RenderOptions, 'legend_location')
    legend_location = opt.RenderOptions.legend_location;
end
legend_mode = local_get(result, 'legend', iff(isempty(legend_entries), 'none', 'show'));
num_cols = 1;
if numel(curves) > 8
    num_cols = 2;
end
apply_tex_style(ax, ...
    'Title', local_get(result,'title',''), ...
    'XLabel', local_get(result,'xlabel','$x$'), ...
    'YLabel', local_get(result,'ylabel','$y$'), ...
    'Grid', 'on', ...
    'Legend', legend_mode, ...
    'LegendLocation', legend_location, ...
    'LegendNumColumns', num_cols);
end

% -------------------------------------------------------------------------
% 3-D rendering
% -------------------------------------------------------------------------

function local_render_3d(fig, result, opt)
items = local_cell_items(local_get(result, 'items', {}));
N = numel(items);
layout_text = local_get(result, 'layout_text', local_get(opt, 'Layout', 'auto'));
if isempty(layout_text), layout_text = local_get(opt, 'Layout', 'auto'); end
row_counts = image_output('layout_rows', layout_text, N);
rows = max(1, numel(row_counts));
cols = max(1, max(row_counts));

fig.Position = [100 100 max(520, 260*cols) max(520, 330*rows)];

if isfield(result,'common_limits') && numel(result.common_limits) == 3
    limits = result.common_limits;
else
    limits = local_common_3d_limits_cell(items);
end

idx = 1;
for r = 1:rows
    for c = 1:cols
        if idx > N || c > row_counts(r), continue; end
        ax = subplot(rows, cols, idx, 'Parent', fig);
        item = items{idx};
        local_draw_one_3d(ax, item);
        local_finish_3d_axes(ax, item, opt, limits);
        idx = idx + 1;
    end
end
end

function local_draw_one_3d(ax,item)
cla(ax);
switch lower(char(string(local_get(item, 'kind', 'surface'))))
    case 'surface'
        cdata = local_get(item, 'c', local_get(item, 'z', []));
        surf(ax, item.x, item.y, item.z, cdata, ...
            'EdgeColor','none', ...
            'FaceAlpha',1.0);
        shading(ax, 'interp');
        colormap(ax, parula(256));
        camlight(ax, 'headlight');
        lighting(ax, 'gouraud');
    case 'vectorfield'
        surf(ax, item.sphere_x, item.sphere_y, item.sphere_z, item.c, ...
            'EdgeColor','none', ...
            'FaceAlpha',0.88);
        hold(ax,'on');
        quiver3(ax, item.xq, item.yq, item.zq, ...
            item.uq, item.vq, item.wq, 0.75, ...
            'LineWidth',0.8, ...
            'Color',[0.10 0.10 0.10]);
        hold(ax,'off');
        shading(ax, 'interp');
        try, colormap(ax, turbo(256)); catch, colormap(ax, parula(256)); end
        camlight(ax, 'headlight');
        lighting(ax, 'gouraud');
    otherwise
        error('Unknown 3D item kind: %s', local_get(item, 'kind', ''));
end
end

function local_finish_3d_axes(ax, item, opt, limits)
axis(ax, 'equal');
if nargin >= 4 && ~isempty(limits) && numel(limits) == 3
    try, xlim(ax, limits{1}); catch, end
    try, ylim(ax, limits{2}); catch, end
    try, zlim(ax, limits{3}); catch, end
end
view(ax, [-37.5 24]);
grid(ax, 'on');
box(ax, 'on');
try, ax.TickLabelInterpreter = 'latex'; catch, end
xlabel(ax, '');
ylabel(ax, '');
zlabel(ax, '');
title(ax, local_get(item, 'title', ''), 'Interpreter', 'latex', 'FontWeight', 'normal');
end


function info = local_image_display(ax, image_data, cmap_name, scaling_mode, fixed_clim, axis_mode)
%LOCAL_IMAGE_DISPLAY Shared optics-style image preview helper.
if nargin < 6 || isempty(axis_mode), axis_mode = 'image'; end
if nargin < 5, fixed_clim = []; end
if nargin < 4 || isempty(scaling_mode), scaling_mode = 'fixed'; end
if nargin < 3 || isempty(cmap_name), cmap_name = 'gray'; end
cla(ax, 'reset');
imagesc(ax, image_data);
if strcmpi(char(string(axis_mode)), 'tight')
    axis(ax, 'tight');
else
    axis(ax, 'image');
end
set(ax, 'YDir', 'normal');
colormap(ax, local_semantic_colormap(cmap_name, 256));
if strcmpi(char(string(scaling_mode)), 'fixed') && ~isempty(fixed_clim)
    local_clim(ax, fixed_clim);
else
    local_clim(ax, 'auto');
end
apply_tex_style(ax, 'Box', 'on');
info = struct('ax', ax, 'CLim', local_get_clim(ax));
end


function cmap = local_semantic_colormap(name, n)
%LOCAL_SEMANTIC_COLORMAP Map optics/field roles to a consistent visual style.
if nargin < 2 || isempty(n), n = 256; end
if isnumeric(name)
    cmap = name;
    return;
end
key = lower(strtrim(char(string(name))));
switch key
    case {'amplitude','amp','object','mask','binary','gray','grey'}
        cmap = gray(n);
    case {'intensity','power','spectrum','energy','hot'}
        cmap = hot(n);
    case {'phase','phase_wrapped','hsv','cyclic'}
        cmap = hsv(n);
    case {'signed','field','wavefront','error','visible','visible_spectrum','old'}
        cmap = local_visible_colormap(n);
    case {'parula'}
        cmap = parula(n);
    otherwise
        try
            cmap = feval(key, n);
        catch
            cmap = local_visible_colormap(n);
        end
end
end

function cmap = local_colormap_interp(stops, n)
%LOCAL_COLORMAP_INTERP Interpolate RGB control points into an n-row colormap.
if nargin < 2 || isempty(n), n = 256; end
stops = double(stops);
if isempty(stops)
    cmap = parula(n);
    return;
end
if max(stops(:)) > 1
    stops = stops ./ 255;
end
x = linspace(0, 1, size(stops, 1));
q = linspace(0, 1, n);
cmap = [interp1(x, stops(:,1), q, 'linear')', ...
        interp1(x, stops(:,2), q, 'linear')', ...
        interp1(x, stops(:,3), q, 'linear')'];
cmap = max(0, min(1, cmap));
end

function v = local_get_clim(ax)
try
    v = clim(ax);
catch
    v = caxis(ax);
end
end


function out = local_style_colorbar(ax, varargin)
%LOCAL_STYLE_COLORBAR Shared colorbar style and limits helper.
p = inputParser;
p.addParameter('N', 256, @(v) isnumeric(v) && isscalar(v) && v >= 2);
p.addParameter('UseVisibleSpectrum', true, @(v) islogical(v) || isnumeric(v));
p.addParameter('Colormap', [], @(v) isempty(v) || (isnumeric(v) && size(v,2) == 3) || ischar(v) || isstring(v));
p.addParameter('Limits', [], @(v) isempty(v) || (isnumeric(v) && numel(v) == 2));
p.addParameter('AutoSymmetric', false, @(v) islogical(v) || isnumeric(v));
p.addParameter('Data', [], @(v) isempty(v) || isnumeric(v));
p.addParameter('NormalizeToUnit', false, @(v) islogical(v) || isnumeric(v));
p.addParameter('CreateColorbar', true, @(v) islogical(v) || isnumeric(v));
p.addParameter('Location', 'eastoutside', @(s) ischar(s) || isstring(s));
p.addParameter('Interpreter', 'latex', @(s) ischar(s) || isstring(s));
p.addParameter('Label', '', @(s) ischar(s) || isstring(s));
p.addParameter('LabelInterpreter', '', @(s) ischar(s) || isstring(s));
p.addParameter('Ticks', [], @(v) isempty(v) || isnumeric(v));
p.addParameter('TickLabels', [], @(v) isempty(v) || isstring(v) || iscellstr(v));
p.addParameter('FontSize', 26, @(v) isnumeric(v) && isscalar(v) && v > 0);
p.addParameter('LabelFontSize', 30, @(v) isnumeric(v) && isscalar(v) && v > 0);
p.parse(varargin{:});
opt = p.Results;

if ~isempty(opt.Colormap)
    colormap(ax, opt.Colormap);
elseif opt.UseVisibleSpectrum
    colormap(ax, local_visible_colormap(opt.N));
else
    colormap(ax, parula(opt.N));
end

clim_applied = [];
if ~isempty(opt.Limits)
    local_clim(ax, opt.Limits);
    clim_applied = opt.Limits;
elseif opt.AutoSymmetric
    data = opt.Data;
    if isempty(data), data = local_try_get_cdata(ax); end
    if ~isempty(data)
        if opt.NormalizeToUnit
            s = max(abs(data(:)), [], 'omitnan');
            if ~isfinite(s) || s < eps, s = 1; end
            data = data ./ s;
        end
        m = max(abs(data(:)), [], 'omitnan');
        if ~isfinite(m) || m < eps, m = 1; end
        local_clim(ax, [-m m]);
        clim_applied = [-m m];
    end
end

cb = [];
if opt.CreateColorbar
    cb = colorbar(ax, char(string(opt.Location)));
    try, cb.TickLabelInterpreter = char(string(opt.Interpreter)); catch, end
    try, cb.FontSize = opt.FontSize; catch, end
    if ~isempty(opt.Ticks), cb.Ticks = opt.Ticks; end
    if ~isempty(opt.TickLabels), cb.TickLabels = opt.TickLabels; end
    if strlength(string(opt.Label)) > 0
        cb.Label.String = local_latex_label(opt.Label);
        if strlength(string(opt.LabelInterpreter)) == 0
            cb.Label.Interpreter = char(string(opt.Interpreter));
        else
            cb.Label.Interpreter = char(string(opt.LabelInterpreter));
        end
        try, cb.Label.FontSize = opt.LabelFontSize; catch, end
    end
end
out = struct('cb', cb, 'cmap', colormap(ax), 'clim', clim_applied);
end

function lgd = local_style_legend(lgd, varargin)
p = inputParser;
p.addParameter('Location', '', @(s) ischar(s) || isstring(s));
p.addParameter('Interpreter', 'latex', @(s) ischar(s) || isstring(s));
p.addParameter('FontSize', 26, @(v) isnumeric(v) && isscalar(v));
p.addParameter('NumColumns', [], @(v) isempty(v) || (isnumeric(v) && isscalar(v)));
p.parse(varargin{:});
opt = p.Results;
if nargin < 1 || isempty(lgd)
    lgd = legend('show');
elseif isgraphics(lgd, 'axes')
    lgd = legend(lgd, 'show');
end
if isempty(lgd) || ~isgraphics(lgd), return; end
try, lgd.Interpreter = char(string(opt.Interpreter)); catch, end
try, lgd.FontSize = opt.FontSize; catch, end
if strlength(string(opt.Location)) > 0
    try, lgd.Location = char(string(opt.Location)); catch, end
end
if ~isempty(opt.NumColumns)
    try, lgd.NumColumns = opt.NumColumns; catch, end
end
end

function data = local_try_get_cdata(ax)
data = [];
kids = ax.Children;
for ii = 1:numel(kids)
    h = kids(ii);
    if isprop(h, 'CData') && isnumeric(h.CData) && ~isempty(h.CData)
        data = h.CData;
        return;
    end
    if isprop(h, 'ZData') && isnumeric(h.ZData) && ~isempty(h.ZData)
        data = h.ZData;
        return;
    end
end
end

% -------------------------------------------------------------------------
% Compatibility actions
% -------------------------------------------------------------------------

function out = local_make_curve_result(curves, varargin)
%LOCAL_MAKE_CURVE_RESULT Small compatibility constructor used by the special-function kernels.
% Accept both the old positional form (curves,title,xlabel,ylabel) and
% name-value form so that tab wrappers cannot trigger "too many input
% arguments" when they pass a legend/location option in the future.
ttl = '';
xl = '$x$';
yl = '$f(x)$';
legend_location = 'best';
if numel(varargin) >= 1, ttl = varargin{1}; end
if numel(varargin) >= 2, xl = varargin{2}; end
if numel(varargin) >= 3, yl = varargin{3}; end
if numel(varargin) > 3
    extra = varargin(4:end);
    if mod(numel(extra),2) == 0
        for ii = 1:2:numel(extra)
            key = lower(char(string(extra{ii})));
            val = extra{ii+1};
            switch key
                case {'title'}
                    ttl = val;
                case {'xlabel','x_label'}
                    xl = val;
                case {'ylabel','y_label'}
                    yl = val;
                case {'legendlocation','legend_location'}
                    legend_location = val;
            end
        end
    end
end
out = struct('kind','curve','curves',{curves},'title',ttl,'xlabel',xl,'ylabel',yl, ...
    'legendLocation', legend_location);
end

function out = local_arg_matrix(params)
if isfield(params,'arg_matrix')
    out = params.arg_matrix;
else
    out = zeros(1,0);
end
end

function out = local_column(params, idx, default_value)
A = local_arg_matrix(params);
if isempty(A)
    out = default_value;
elseif size(A,2) < idx
    out = repmat(default_value, size(A,1), 1);
else
    out = A(:,idx);
end
end

% -------------------------------------------------------------------------
% Small helpers
% -------------------------------------------------------------------------

function [xv, yv] = local_axis_vectors(x, y, Z)
if isempty(x)
    xv = 1:size(Z,2);
elseif isvector(x)
    xv = x(:).';
else
    xv = x(1,:);
end
if isempty(y)
    yv = 1:size(Z,1);
elseif isvector(y)
    yv = y(:).';
else
    yv = y(:,1).';
end
end

function value = local_get(s, field, default_value)
if isstruct(s) && isfield(s, field) && ~isempty(s.(field))
    value = s.(field);
else
    value = default_value;
end
end

function items = local_cell_items(items)
if isempty(items)
    items = {};
elseif iscell(items)
    items = items(:).';
elseif isstruct(items)
    items = num2cell(items);
else
    items = {items};
end
end

function [xl, yl, do_crop] = local_curve_crop_limits(x, y, crop)
do_crop = false;
xl = [];
yl = [];
x = x(isfinite(x));
y = y(isfinite(y));
if isempty(x) || isempty(y)
    return;
end
xl = [min(x(:)) max(x(:))];
if xl(1) == xl(2)
    xl = xl + [-1 1];
end
if isstruct(crop)
    mode = 'auto';
    if isfield(crop, 'mode') && ~isempty(crop.mode)
        mode = lower(char(string(crop.mode)));
    end
    switch mode
        case {'none','off','manual_x_only'}
            return;
        case {'yrange','y_range','manual'}
            if isfield(crop, 'y_range') && isnumeric(crop.y_range) && numel(crop.y_range) >= 2
                yl = double(crop.y_range(1:2));
                if yl(1) == yl(2), yl = yl + [-1 1]; end
                do_crop = true;
                return;
            end
        otherwise
            % fall through to automatic y limits
    end
elseif isnumeric(crop) && numel(crop) >= 2
    yl = double(crop(1:2));
    if yl(1) == yl(2), yl = yl + [-1 1]; end
    do_crop = true;
    return;
end
yl = [min(y(:)) max(y(:))];
if yl(1) == yl(2)
    pad = max(1e-9, abs(yl(1))*0.05 + 1e-9);
    yl = yl + [-pad pad];
else
    pad = 0.06 * diff(yl);
    yl = yl + [-pad pad];
end
do_crop = true;
end

function limits = local_common_3d_limits_cell(items)
lim = image_output('common_3d_limits', items);
if iscell(lim)
    limits = lim;
    return;
end
if isnumeric(lim) && numel(lim) >= 6
    limits = {lim(1:2), lim(3:4), lim(5:6)};
else
    limits = {[-1 1], [-1 1], [-1 1]};
end
end

function v = local_finite_max(A)
a = A(isfinite(A));
if isempty(a), v = NaN; else, v = max(a(:)); end
end

function q = local_finite_quantile(A, p)
a = A(isfinite(A));
if isempty(a), q = NaN; return; end
a = sort(a(:));
idx = max(1, min(numel(a), round(p*numel(a))));
q = a(idx);
end

function out = iff(cond, a, b)
if cond, out = a; else, out = b; end
end

function local_safe_close(fig)
try
    if ~isempty(fig) && isgraphics(fig)
        close(fig);
    end
catch
end
end
