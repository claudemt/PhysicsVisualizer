function png_paths = render_graphite_levitation_result(mode, data, cache_dir, varargin)
%RENDER_GRAPHITE_LEVITATION_RESULT Render bundled outputs for GraphiteLevitation.
% This renderer deliberately reuses the shared PhysicsVisualizer utils style
% when available: apply_tex_style, render_result('colorbar'), and
% image_output('save_figure').  It does not modify any utils file.

p = inputParser;
p.addParameter('Prefix', '', @(s) ischar(s) || isstring(s)); %#ok<NVREPL>
p.parse(varargin{:}); %#ok<NASGU>

if exist(cache_dir, 'dir') ~= 7
    mkdir(cache_dir);
end

mode = lower(char(string(mode)));
switch mode
    case {'visualization_bundle','visualization','magnetic_potential','potential'}
        if isfield(data, 'results')
            bundle = data;
        else
            bundle = struct('results', {{data}}, 'params', data.params, 'scanned', {{}});
        end
        png_paths = local_render_bundle(bundle, cache_dir);
    otherwise
        error('Unknown render mode: %s', mode);
end
end

function paths = local_render_bundle(bundle, cache_dir)
paths = cell(1,7);
paths{1} = local_save_b2_grid(bundle, cache_dir, '01_B2.png');
paths{2} = local_save_potential_grid(bundle, cache_dir, '02_potential.png');
paths{3} = local_save_chi_grid(bundle, cache_dir, '03_chi.png');
paths{4} = local_save_system_grid(bundle, cache_dir, '04_system.png');
paths{5} = local_save_force_grid(bundle, cache_dir, '05_force_x.png', 'Fx');
paths{6} = local_save_force_grid(bundle, cache_dir, '06_force_y.png', 'Fy');
paths{7} = local_save_force_grid(bundle, cache_dir, '07_force_z.png', 'Fz');
end

function path = local_save_b2_grid(bundle, cache_dir, file_name)
results = bundle.results;
layout = local_scan_layout(bundle);
nr = layout.nr; nc = layout.nc;
fig = local_big_figure(nr, nc, 1, 1);
tl = tiledlayout(fig, nr, nc, 'TileSpacing', 'compact', 'Padding', 'compact');
for k = 1:numel(results)
    r = results{k};
    ax = nexttile(tl, local_tile_index(1, layout.row(k), layout.col(k), nr, nc));
    Z = local_norm_positive(r.B2);
    imagesc(ax, r.x*1e3, r.y*1e3, Z);
    axis(ax, 'image'); set(ax, 'YDir', 'normal');
    colormap(ax, local_visible_colormap());
    hold(ax, 'on'); overlay_magnet_outlines(ax, r.params); hold(ax, 'off');
    local_apply_axes_style(ax, local_variant_title(r), '$x\,[\mathrm{mm}]$', '$y\,[\mathrm{mm}]$', 'image');
    local_apply_clim(ax, [0 1]);
    if layout.col(k) == nc, local_colorbar(ax); end
end
local_layout_title(tl, '$01\quad B^2$');
path = fullfile(cache_dir, file_name);
local_export(fig, path, bundle.params);
close(fig);
end

function path = local_save_potential_grid(bundle, cache_dir, file_name)
results = bundle.results;
layout = local_scan_layout(bundle);
nr = layout.nr; nc = layout.nc;
fig = local_big_figure(nr, nc, 3, 1.05);
tl = tiledlayout(fig, 3*nr, nc, 'TileSpacing', 'compact', 'Padding', 'compact');
for k = 1:numel(results)
    r = results{k};
    row = layout.row(k); col = layout.col(k);

    U0 = local_norm_positive(r.base.U);
    UL = local_norm_positive(r.active.U);
    DU = local_norm_signed(UL - U0);

    ax1 = nexttile(tl, local_tile_index(1,row,col,nr,nc));
    imagesc(ax1, r.base.x*1e3, r.base.y*1e3, U0);
    axis(ax1, 'image'); set(ax1, 'YDir', 'normal');
    colormap(ax1, local_visible_colormap());
    hold(ax1, 'on'); overlay_magnet_outlines(ax1, r.base.params); local_plot_stable(ax1, r.metrics.stableOff, [1 1 1], 'o'); hold(ax1, 'off');
    local_apply_axes_style(ax1, local_variant_title(r), '$x\,[\mathrm{mm}]$', local_row_ylabel('no laser'), 'image');
    local_apply_clim(ax1, [0 1]);
    if col == nc, local_colorbar(ax1); end

    ax2 = nexttile(tl, local_tile_index(2,row,col,nr,nc));
    imagesc(ax2, r.active.x*1e3, r.active.y*1e3, UL);
    axis(ax2, 'image'); set(ax2, 'YDir', 'normal');
    colormap(ax2, local_visible_colormap());
    hold(ax2, 'on'); overlay_magnet_outlines(ax2, r.active.params); local_plot_stable(ax2, r.metrics.stableOn, [1 1 1], 'o'); hold(ax2, 'off');
    local_apply_axes_style(ax2, local_variant_title(r), '$x\,[\mathrm{mm}]$', local_row_ylabel('with laser'), 'image');
    local_apply_clim(ax2, [0 1]);
    if col == nc, local_colorbar(ax2); end

    ax3 = nexttile(tl, local_tile_index(3,row,col,nr,nc));
    imagesc(ax3, r.active.x*1e3, r.active.y*1e3, DU);
    axis(ax3, 'image'); set(ax3, 'YDir', 'normal');
    colormap(ax3, local_visible_colormap());
    hold(ax3, 'on'); overlay_magnet_outlines(ax3, r.active.params); local_plot_stable(ax3, r.metrics.stableOff, [0.2 0.2 0.2], 'o'); local_plot_stable(ax3, r.metrics.stableOn, [1 1 1], '+'); hold(ax3, 'off');
    local_apply_axes_style(ax3, local_variant_title(r), '$x\,[\mathrm{mm}]$', local_row_ylabel('diff'), 'image');
    local_apply_clim(ax3, [-1 1]);
    if col == nc, local_colorbar(ax3); end
end
local_layout_title(tl, '$02\quad U(X,Y)$');
path = fullfile(cache_dir, file_name);
local_export(fig, path, bundle.params);
close(fig);
end

function path = local_save_chi_grid(bundle, cache_dir, file_name)
results = bundle.results;
layout = local_scan_layout(bundle);
nr = layout.nr; nc = layout.nc;
fig = local_big_figure(nr, nc, 3, 1.0);
tl = tiledlayout(fig, 3*nr, nc, 'TileSpacing', 'compact', 'Padding', 'compact');
for k = 1:numel(results)
    r = results{k};
    row = layout.row(k); col = layout.col(k);
    mask = isfinite(r.chi.weight);
    baseChi = ones(size(r.chi.weight)); baseChi(~mask) = NaN;
    activeChi = r.chi.weight;
    baseDisp = local_norm_positive(baseChi);
    activeDisp = local_norm_positive(activeChi);
    deltaDisp = local_norm_signed(activeDisp - baseDisp);

    ax1 = nexttile(tl, local_tile_index(1,row,col,nr,nc));
    imagesc(ax1, r.chi.x*1e3, r.chi.y*1e3, baseDisp);
    axis(ax1, 'image'); set(ax1, 'YDir', 'normal');
    colormap(ax1, local_visible_colormap());
    hold(ax1, 'on'); plot_graphite_outline_local(ax1, r.params.graphite); hold(ax1, 'off');
    local_apply_axes_style(ax1, local_variant_title(r), '$x_s\,[\mathrm{mm}]$', local_row_ylabel('no laser'), 'image');
    local_apply_clim(ax1, [0 1]);
    if col == nc, local_colorbar(ax1); end

    ax2 = nexttile(tl, local_tile_index(2,row,col,nr,nc));
    imagesc(ax2, r.chi.x*1e3, r.chi.y*1e3, activeDisp);
    axis(ax2, 'image'); set(ax2, 'YDir', 'normal');
    colormap(ax2, local_visible_colormap());
    hold(ax2, 'on'); plot_graphite_outline_local(ax2, r.params.graphite); if r.params.laser.enabled, plot(ax2, r.params.laser.spotX*1e3, r.params.laser.spotY*1e3, 'ko', 'MarkerFaceColor', 'w', 'MarkerSize', 4); end; hold(ax2, 'off');
    local_apply_axes_style(ax2, local_variant_title(r), '$x_s\,[\mathrm{mm}]$', local_row_ylabel('with laser'), 'image');
    local_apply_clim(ax2, [0 1]);
    if col == nc, local_colorbar(ax2); end

    ax3 = nexttile(tl, local_tile_index(3,row,col,nr,nc));
    imagesc(ax3, r.chi.x*1e3, r.chi.y*1e3, deltaDisp);
    axis(ax3, 'image'); set(ax3, 'YDir', 'normal');
    colormap(ax3, local_visible_colormap());
    hold(ax3, 'on'); plot_graphite_outline_local(ax3, r.params.graphite); if r.params.laser.enabled, plot(ax3, r.params.laser.spotX*1e3, r.params.laser.spotY*1e3, 'ko', 'MarkerFaceColor', 'w', 'MarkerSize', 4); end; hold(ax3, 'off');
    local_apply_axes_style(ax3, local_variant_title(r), '$x_s\,[\mathrm{mm}]$', local_row_ylabel('diff'), 'image');
    local_apply_clim(ax3, [-1 1]);
    if col == nc, local_colorbar(ax3); end
end
local_layout_title(tl, '$03\quad |\chi|/|\chi_0|$');
path = fullfile(cache_dir, file_name);
local_export(fig, path, bundle.params);
close(fig);
end

function path = local_save_system_grid(bundle, cache_dir, file_name)
results = bundle.results;
layout = local_scan_layout(bundle);
nr = layout.nr; nc = layout.nc;
fig = local_big_figure(nr, nc, 3, 1.05);
tl = tiledlayout(fig, 3*nr, nc, 'TileSpacing', 'compact', 'Padding', 'compact');
for k = 1:numel(results)
    r = results{k};
    row = layout.row(k); col = layout.col(k);

    ax1 = nexttile(tl, local_tile_index(1,row,col,nr,nc));
    local_draw_system_top(ax1, r);
    local_apply_axes_style(ax1, local_variant_title(r), '$x\,[\mathrm{mm}]$', local_row_ylabel('top view'), 'image');

    ax2 = nexttile(tl, local_tile_index(2,row,col,nr,nc));
    local_draw_system_side_x(ax2, r);
    local_apply_axes_style(ax2, local_variant_title(r), '$x\,[\mathrm{mm}]$', local_row_ylabel('side x-z'), '');

    ax3 = nexttile(tl, local_tile_index(3,row,col,nr,nc));
    local_draw_system_side_y(ax3, r);
    local_apply_axes_style(ax3, local_variant_title(r), '$y\,[\mathrm{mm}]$', local_row_ylabel('side y-z'), '');
end
local_layout_title(tl, '$04\quad \mathrm{system\,views}$');
path = fullfile(cache_dir, file_name);
local_export(fig, path, bundle.params);
close(fig);
end

function local_draw_system_top(ax, r)
hold(ax, 'on');
axis(ax, 'image'); set(ax, 'YDir', 'normal');
overlay_magnet_outlines(ax, r.params);
plot_graphite_planform(ax, r.params.graphite, r.metrics.xMinOff, r.metrics.yMinOff, [0.4 0.4 0.4], '--');
plot_graphite_planform(ax, r.params.graphite, r.metrics.xMinOn, r.metrics.yMinOn, [0.85 0.15 0.15], '-');
local_plot_stable(ax, r.metrics.stableOff, [0.35 0.35 0.35], 'o');
local_plot_stable(ax, r.metrics.stableOn, [0.85 0.15 0.15], '+');
if r.params.laser.enabled
    % Laser spot is in graphite-local (rotated) coordinates; rotate to lab frame
    phi = r.params.graphite.rotationDeg * pi / 180;
    spotX_lab =  cos(phi)*r.params.laser.spotX - sin(phi)*r.params.laser.spotY;
    spotY_lab =  sin(phi)*r.params.laser.spotX + cos(phi)*r.params.laser.spotY;
    plot(ax, (r.metrics.xMinOn + spotX_lab)*1e3, (r.metrics.yMinOn + spotY_lab)*1e3, ...
        'ko', 'MarkerFaceColor', 'y', 'MarkerSize', 3.5);
end
end

function local_draw_system_side_x(ax, r)
hold(ax, 'on');
local_draw_magnet_projection_xz(ax, r.magnets);
L = graphite_projected_width(r.params.graphite, 'x');
plot_tilt_segment(ax, r.metrics.xMinOff, r.metrics.zEqOff, L, 0, [0.45 0.45 0.45], '--');
plot_tilt_segment(ax, r.metrics.xMinOn, r.metrics.zEqOff, L, r.metrics.thetaY, [0.85 0.15 0.15], '-');
axis(ax, 'equal');
end

function local_draw_system_side_y(ax, r)
hold(ax, 'on');
local_draw_magnet_projection_yz(ax, r.magnets);
L = graphite_projected_width(r.params.graphite, 'y');
plot_tilt_segment(ax, r.metrics.yMinOff, r.metrics.zEqOff, L, -r.metrics.thetaX, [0.45 0.45 0.45], '--');
plot_tilt_segment(ax, r.metrics.yMinOn, r.metrics.zEqOff, L, -r.metrics.thetaX, [0.85 0.15 0.15], '-');
axis(ax, 'equal');
end

function path = local_save_force_grid(bundle, cache_dir, file_name, forceField)
results = bundle.results;
layout = local_scan_layout(bundle);
nr = layout.nr; nc = layout.nc;
fig = local_big_figure(nr, nc, 3, 1.05);
tl = tiledlayout(fig, 3*nr, nc, 'TileSpacing', 'compact', 'Padding', 'compact');
for k = 1:numel(results)
    r = results{k};
    row = layout.row(k); col = layout.col(k);
    [baseRaw, x, y] = local_force_component_raw(r.base, forceField);
    [actRaw, ~, ~] = local_force_component_raw(r.active, forceField);
    baseMap = local_norm_signed(baseRaw);
    actMap = local_norm_signed(actRaw);
    dMap = local_norm_signed(actRaw - baseRaw);

    ax1 = nexttile(tl, local_tile_index(1,row,col,nr,nc));
    imagesc(ax1, x*1e3, y*1e3, baseMap); axis(ax1,'image'); set(ax1,'YDir','normal');
    colormap(ax1, local_visible_colormap()); hold(ax1,'on'); overlay_magnet_outlines(ax1, r.base.params); hold(ax1,'off');
    local_apply_axes_style(ax1, local_variant_title(r), '$x\,[\mathrm{mm}]$', local_row_ylabel('no laser'), 'image');
    local_apply_clim(ax1, [-1 1]);
    if col == nc, local_colorbar(ax1); end

    ax2 = nexttile(tl, local_tile_index(2,row,col,nr,nc));
    imagesc(ax2, x*1e3, y*1e3, actMap); axis(ax2,'image'); set(ax2,'YDir','normal');
    colormap(ax2, local_visible_colormap()); hold(ax2,'on'); overlay_magnet_outlines(ax2, r.active.params); hold(ax2,'off');
    local_apply_axes_style(ax2, local_variant_title(r), '$x\,[\mathrm{mm}]$', local_row_ylabel('with laser'), 'image');
    local_apply_clim(ax2, [-1 1]);
    if col == nc, local_colorbar(ax2); end

    ax3 = nexttile(tl, local_tile_index(3,row,col,nr,nc));
    imagesc(ax3, x*1e3, y*1e3, dMap); axis(ax3,'image'); set(ax3,'YDir','normal');
    colormap(ax3, local_visible_colormap()); hold(ax3,'on'); overlay_magnet_outlines(ax3, r.active.params); hold(ax3,'off');
    local_apply_axes_style(ax3, local_variant_title(r), '$x\,[\mathrm{mm}]$', local_row_ylabel('diff'), 'image');
    local_apply_clim(ax3, [-1 1]);
    if col == nc, local_colorbar(ax3); end
end
local_layout_title(tl, local_force_title(forceField));
path = fullfile(cache_dir, file_name);
local_export(fig, path, bundle.params);
close(fig);
end

function [M, x, y] = local_force_component_raw(mapStruct, forceField)
U = mapStruct.U;
x = mapStruct.x; y = mapStruct.y;
[Gy, Gx] = gradient(U, y, x);
Fx = -Gx;
Fy = -Gy;
Fz = mapStruct.Fz;
switch lower(forceField)
    case 'fx'
        M = Fx;
    case 'fy'
        M = Fy;
    case 'fz'
        M = Fz;
    otherwise
        M = U;
end
end

function idx = local_tile_index(block, row, col, nr, nc)
idx = (block-1)*nr*nc + (row-1)*nc + col;
end

function layout = local_scan_layout(bundle)
results = bundle.results;
n = numel(results);
scanned = {};
try, scanned = bundle.scanned; catch, end
if ischar(scanned) || isstring(scanned), scanned = cellstr(scanned); end
scanned = scanned(:).';
if isempty(scanned)
    layout = struct('nr', 1, 'nc', max(1,n), 'row', ones(1,n), 'col', 1:n);
    return;
end
vals = struct();
for i = 1:numel(scanned)
    nm = scanned{i};
    v = [];
    try
        if isfield(bundle, 'sweep') && isfield(bundle.sweep, nm)
            v = bundle.sweep.(nm);
        end
    catch
    end
    if isempty(v)
        tmp = nan(1,n);
        for k = 1:n
            try, tmp(k) = results{k}.variant.(nm); catch, end
        end
        v = unique(tmp(isfinite(tmp)), 'stable');
    end
    vals.(nm) = v(:).';
end
if numel(scanned) == 1
    colVar = scanned{1};
    nc = max(1, numel(vals.(colVar)));
    nr = 1;
    row = ones(1,n);
    col = ones(1,n);
    for k = 1:n
        try, col(k) = local_value_index(vals.(colVar), results{k}.variant.(colVar)); catch, col(k)=k; end
    end
    layout = struct('nr', nr, 'nc', nc, 'row', row, 'col', col);
    return;
end
colVar = scanned{end};
rowVars = scanned(1:end-1);
nc = max(1, numel(vals.(colVar)));
rowCounts = zeros(1, numel(rowVars));
for j = 1:numel(rowVars), rowCounts(j) = max(1, numel(vals.(rowVars{j}))); end
nr = max(1, prod(rowCounts));
row = ones(1,n); col = ones(1,n);
for k = 1:n
    try, col(k) = local_value_index(vals.(colVar), results{k}.variant.(colVar)); catch, col(k)=1; end
    idx = ones(1, numel(rowVars));
    for j = 1:numel(rowVars)
        nm = rowVars{j};
        try, idx(j) = local_value_index(vals.(nm), results{k}.variant.(nm)); catch, idx(j)=1; end
    end
    r = 1;
    for j = 1:numel(rowVars)
        tail = 1;
        if j < numel(rowVars), tail = prod(rowCounts(j+1:end)); end
        r = r + (idx(j)-1) * tail;
    end
    row(k) = r;
end
layout = struct('nr', nr, 'nc', nc, 'row', row, 'col', col);
end

function idx = local_value_index(values, v)
if isempty(values), idx = 1; return; end
[~, idx] = min(abs(values - v));
idx = max(1, idx);
end

function Z = local_norm_positive(M)
Z = M;
vals = M(isfinite(M));
if isempty(vals), return; end
mx = max(vals(:));
if ~isfinite(mx) || abs(mx) < eps, return; end
Z = M ./ mx;
end

function Z = local_norm_signed(M)
Z = M;
vals = M(isfinite(M));
if isempty(vals), return; end
mx = max(abs(vals(:)));
if ~isfinite(mx) || mx < eps, return; end
Z = M ./ mx;
end

function fig = local_big_figure(nr, nc, nblocks, hscale)
if nargin < 4, hscale = 1; end
w = max(1400, 360*nc + 120);
h = max(900, round(290*nr*nblocks*hscale + 120));
fig = image_output('hidden_figure', 'Position', [80 60 w h]);
end

function local_apply_axes_style(ax, ttl, xl, yl, axisMode)
if nargin < 5, axisMode = ''; end
if exist('apply_tex_style','file') == 2
    try
        apply_tex_style(ax, 'Title', ttl, 'XLabel', xl, 'YLabel', yl, ...
            'AxisMode', axisMode, 'Interpreter', 'latex', 'TickInterpreter', 'latex', ...
            'Grid', 'off', 'Box', 'on', 'FontSize', 10, 'TitleFontSize', 11);
        return;
    catch
    end
end
try, title(ax, ttl, 'Interpreter', 'latex', 'FontWeight', 'normal'); catch, title(ax, local_plain_from_tex(ttl), 'Interpreter', 'none'); end
try, xlabel(ax, xl, 'Interpreter', 'latex'); catch, xlabel(ax, local_plain_from_tex(xl), 'Interpreter', 'none'); end
try, ylabel(ax, yl, 'Interpreter', 'latex'); catch, ylabel(ax, local_plain_from_tex(yl), 'Interpreter', 'none'); end
try, ax.TickLabelInterpreter = 'latex'; catch, end
try, box(ax, 'on'); catch, end
try, grid(ax, 'off'); catch, end
if ~isempty(axisMode), try, axis(ax, axisMode); catch, end, end
end

function local_layout_title(tl, txt)
try
    title(tl, txt, 'Interpreter', 'latex', 'FontWeight', 'normal');
catch
    try, title(tl, local_plain_from_tex(txt), 'Interpreter', 'none'); catch, end
end
end

function local_apply_clim(ax, lim)
if any(~isfinite(lim)) || numel(lim)~=2 || lim(1)==lim(2)
    return;
end
try
    clim(ax, lim);
catch
    caxis(ax, lim);
end
end

function out = local_colorbar(ax)
if exist('render_result','file') == 2
    try
        out = render_result('colorbar', ax, 'Label', '$ $');
        return;
    catch
    end
end
cb = colorbar(ax, 'eastoutside');
try, cb.TickLabelInterpreter = 'latex'; catch, end
try, cb.Label.String = '$ $'; cb.Label.Interpreter = 'latex'; catch, end
out = cb;
end

function cmap = local_visible_colormap()
if exist('render_result','file') == 2
    try
        cmap = render_result('colormap_interp', [ ...
            68 1 84; ...
            59 82 139; ...
            33 145 140; ...
            94 201 98; ...
            253 231 37; ...
            249 167 37; ...
            220 50 32] / 255, 256);
        return;
    catch
    end
end
anchors = [ ...
    68 1 84; ...
    59 82 139; ...
    33 145 140; ...
    94 201 98; ...
    253 231 37; ...
    249 167 37; ...
    220 50 32] / 255;
xi = linspace(0,1,size(anchors,1));
xq = linspace(0,1,256);
cmap = interp1(xi, anchors, xq, 'pchip');
end

function ttl = local_variant_title(r)
ttl = '$ $';
try
    ttl = local_label_to_latex(r.variantLabel);
catch
end
end

function s = local_label_to_latex(label)
raw = strtrim(char(string(label)));
if isempty(raw) || strcmpi(raw, 'single run')
    s = '$ $';
    return;
end
parts = regexp(raw, '\s*,\s*', 'split');
out = {};
for i = 1:numel(parts)
    kv = regexp(parts{i}, '^\s*([A-Za-z]+)\s*=\s*(.+?)\s*$', 'tokens', 'once');
    if isempty(kv), continue; end
    key = kv{1};
    val = kv{2};
    switch key
        case 'chi'
            out{end+1} = ['\chi=' val]; %#ok<AGROW>
        otherwise
            out{end+1} = [key '=' val]; %#ok<AGROW>
    end
end
if isempty(out)
    s = ['$\mathrm{' local_escape_latex(raw) '}$'];
else
    joined = out{1};
    for jj = 2:numel(out)
        joined = [joined ',\,' out{jj}]; %#ok<AGROW>
    end
    s = ['$' joined '$'];
end
end

function y = local_row_ylabel(label)
switch lower(char(string(label)))
    case 'no laser'
        y = '$\mathrm{no\,laser}$';
    case 'with laser'
        y = '$\mathrm{with\,laser}$';
    case 'diff'
        y = '$\mathrm{diff}$';
    case 'top view'
        y = '$\mathrm{top\,view}$';
    otherwise
        safe = local_escape_latex(char(string(label)));
        y = ['$\mathrm{' safe '}$'];
end
end

function txt = local_force_title(forceField)
switch lower(forceField)
    case 'fx'
        txt = '$05\quad F_x$';
    case 'fy'
        txt = '$06\quad F_y$';
    otherwise
        txt = '$07\quad F_z$';
end
end

function local_plot_stable(ax, stable, colorVal, marker)
try
    if stable.count <= 0, return; end
    plot(ax, stable.x*1e3, stable.y*1e3, marker, 'Color', colorVal, ...
        'MarkerSize', 4.5, 'LineWidth', 1.0, 'MarkerFaceColor', 'none');
catch
end
end

function plot_graphite_planform(ax, graphite, xc, yc, colorVal, lineStyle)
if strcmpi(char(string(graphite.shape)), 'circle')
    t = linspace(0, 2*pi, 240);
    x = graphite.radius*cos(t);
    y = graphite.radius*sin(t);
else
    s = graphite.side/2;
    xy = [-s -s; s -s; s s; -s s; -s -s];
    phi = graphite.rotationDeg*pi/180;
    Rz = [cos(phi) -sin(phi); sin(phi) cos(phi)];
    rot = (Rz * xy(:,1:2).').';
    x = rot(:,1); y = rot(:,2);
end
plot(ax, (x+xc)*1e3, (y+yc)*1e3, 'Color', colorVal, 'LineStyle', lineStyle, 'LineWidth', 1.2);
end

function w = graphite_projected_width(graphite, axisName)
if strcmpi(char(string(graphite.shape)), 'circle')
    w = 2*graphite.radius;
else
    s = graphite.side/2;
    xy = [-s -s; s -s; s s; -s s; -s -s];
    phi = graphite.rotationDeg*pi/180;
    Rz = [cos(phi) -sin(phi); sin(phi) cos(phi)];
    rot = (Rz * xy(:,1:2).').';
    if strcmpi(axisName, 'x')
        w = max(rot(:,1)) - min(rot(:,1));
    else
        w = max(rot(:,2)) - min(rot(:,2));
    end
end
end

function plot_tilt_segment(ax, centerCoord, zc, width, theta, colorVal, lineStyle)
halfW = 0.5*width;
u = linspace(-halfW, halfW, 120);
v = tan(theta) * u;
plot(ax, (centerCoord + u)*1e3, (zc + v)*1e3, 'Color', colorVal, 'LineWidth', 1.6, 'LineStyle', lineStyle);
end

function local_draw_magnet_projection_xz(ax, magnets)
a = magnets.a; c = magnets.c;
xs = unique(magnets.x(:));
for i = 1:numel(xs)
    rectangle(ax, 'Position', [(xs(i)-a/2)*1e3, -c*1e3, a*1e3, c*1e3], 'FaceColor', [0.85 0.85 0.88], 'EdgeColor', [0.35 0.35 0.35], 'LineWidth', 0.5);
end
end

function local_draw_magnet_projection_yz(ax, magnets)
b = magnets.b; c = magnets.c;
ys = unique(magnets.y(:));
for i = 1:numel(ys)
    rectangle(ax, 'Position', [(ys(i)-b/2)*1e3, -c*1e3, b*1e3, c*1e3], 'FaceColor', [0.85 0.85 0.88], 'EdgeColor', [0.35 0.35 0.35], 'LineWidth', 0.5);
end
end

function overlay_magnet_outlines(ax, params)
params = validate_graphite_levitation_params(params);
a = params.magnet.a*1e3; b = params.magnet.b*1e3;
xs = ((1:params.array.nx) - (params.array.nx+1)/2) * a;
ys = ((1:params.array.ny) - (params.array.ny+1)/2) * b;
for ix = 1:numel(xs)
    for iy = 1:numel(ys)
        rectangle(ax, 'Position', [xs(ix)-a/2, ys(iy)-b/2, a, b], 'EdgeColor', [0.15 0.15 0.15], 'LineWidth', 0.5, 'LineStyle', '-');
    end
end
end

function plot_graphite_outline_local(ax, graphite)
if strcmpi(char(string(graphite.shape)), 'circle')
    t = linspace(0, 2*pi, 240);
    plot(ax, graphite.radius*1e3*cos(t), graphite.radius*1e3*sin(t), 'k-', 'LineWidth', 0.8);
else
    s = graphite.side/2;
    xy = [-s -s; s -s; s s; -s s; -s -s];
    phi = graphite.rotationDeg*pi/180;
    Rz = [cos(phi) -sin(phi); sin(phi) cos(phi)];
    rot = (Rz * xy(:,1:2).').';
    plot(ax, rot(:,1)*1e3, rot(:,2)*1e3, 'k-', 'LineWidth', 0.8);
end
end

function s = local_escape_latex(s)
s = strrep(s, '\', '\\');
s = strrep(s, '_', '\_');
s = strrep(s, '%', '\%');
s = strrep(s, '#', '\#');
s = strrep(s, '&', '\&');
s = strrep(s, '{', '\{');
s = strrep(s, '}', '\}');
s = strrep(s, ' ', '\,');
end

function s = local_plain_from_tex(s)
s = char(string(s));
s = regexprep(s, '[$\\{}]', '');
end

function local_export(fig, path, params)
dpi = 300;
try, dpi = params.render.dpi; catch, end
[folder, name, ext] = fileparts(path);
image_output('save_figure', fig, folder, [name ext], dpi);
end
