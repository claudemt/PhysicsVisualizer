function varargout = image_output(action, varargin)
%IMAGE_OUTPUT Shared image preview, cache, composition, and export helper.

action = lower(char(string(action)));
switch action
    case 'cache_dir'
        varargout{1} = local_cache_dir(varargin{:});
    case 'clear_cache'
        varargout{1} = local_clear_cache(varargin{:});
    case 'reset_preview'
        varargout{1} = local_reset_preview(varargin{:});
    case {'reset_preview_group','reset_axesgrid'}
        varargout{1} = local_reset_preview_group(varargin{:});
    case {'show_preview_group','show_axesgrid'}
        varargout{1} = local_show_preview_group(varargin{:});
    case 'show_preview'
        varargout{1} = local_show_preview(varargin{:});
    case 'bind_preview_list'
        varargout{1} = local_bind_preview_list(varargin{:});
    case 'selected_preview_paths'
        varargout{1} = local_selected_preview_paths(varargin{:});
    case 'all_preview_paths'
        varargout{1} = local_all_preview_paths(varargin{:});
    case 'preview_layout'
        varargout{1} = local_preview_layout(varargin{:});
    case 'select_all'
        varargout{1} = local_select_all(varargin{:});
    case 'select_none'
        varargout{1} = local_select_none(varargin{:});
    case 'delete_selection'
        varargout{1} = local_delete_selection(varargin{:});
    case 'move_selection'
        varargout{1} = local_move_selection(varargin{:});
    case 'preview_composite'
        varargout{1} = local_preview_composite(varargin{:});
    case {'run_core_script','run_script'}
        varargout{1} = local_run_core_script(varargin{:});
    case {'export_preview_bundle','preview_bundle'}
        varargout{1} = local_export_preview_bundle(varargin{:});
    case {'hidden_figures','hide_figures'}
        varargout{1} = local_hidden_figures(varargin{:});
    case {'hidden_figure','new_hidden_figure'}
        varargout{1} = local_hidden_figure(varargin{:});
    case {'export_frame','frame_from_figure'}
        varargout{1} = local_export_frame(varargin{:});
    case {'normalize_video_frame','normalize_frame'}
        varargout{1} = local_normalize_video_frame(varargin{:});
    case 'save_figure'
        varargout{1} = local_save_figure(varargin{:});
    case 'compose_grid'
        varargout{1} = local_compose_grid(varargin{:});
    case 'export_bundle'
        varargout{1} = local_export_bundle(varargin{:});
    case 'output_dir'
        varargout{1} = local_output_dir(varargin{:});
    case 'slug'
        varargout{1} = local_slug(varargin{:});
    case {'indexed_name','export_name'}
        varargout{1} = local_indexed_name(varargin{:});
    case {'layout_rows','parse_layout'}
        varargout{1} = local_layout_rows(varargin{:});
    case 'parse_range'
        varargout{1} = local_parse_range(varargin{:});
    case 'parse_optional_range'
        varargout{1} = local_parse_optional_range(varargin{:});
    case 'crop_limits'
        [varargout{1:nargout}] = local_crop_limits(varargin{:});
    case 'common_3d_limits'
        varargout{1} = local_common_3d_limits(varargin{:});
    case 'clean_label'
        varargout{1} = local_clean_label(varargin{:});
    case 'auto_crop'
        local_auto_crop(varargin{:});
    otherwise
        error('Unknown image_output action: %s', action);
end
end

function dirpath = local_cache_dir(project_root, module_key)
if nargin < 2 || isempty(module_key), module_key = 'preview'; end
dirpath = fullfile(project_root, '.cache', local_slug(module_key));
if exist(dirpath, 'dir') ~= 7
    mkdir(dirpath);
end
end

function dirpath = local_clear_cache(project_root, module_key)
dirpath = local_cache_dir(project_root, module_key);
files = dir(fullfile(dirpath, '*'));
for i = 1:numel(files)
    name = files(i).name;
    if strcmp(name,'.') || strcmp(name,'..'), continue; end
    fp = fullfile(dirpath, name);
    if files(i).isdir
        rmdir(fp, 's');
    else
        delete(fp);
    end
end
end

function out = local_reset_preview(ax, message)
if nargin < 2, message = 'run to generate result'; end
if isempty(ax) || ~isgraphics(ax), out = []; return; end
cla(ax);
ax.Visible = 'on';
ax.XTick = [];
ax.YTick = [];
axis(ax, [0 1 0 1]);
text(ax, 0.5, 0.5, char(string(message)), ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'Interpreter', 'none', ...
    'FontSize', 20, ...
    'Color', [0.35 0.35 0.35]);
out = ax;
end


function out = local_reset_preview_group(container, axes_handles, message)
%LOCAL_RESET_PREVIEW_GROUP Center an empty-state message over a multi-axes preview.
if nargin < 3 || isempty(message), message = 'run to generate result'; end
if nargin < 2, axes_handles = []; end
if isempty(container) || ~isgraphics(container)
    if ~isempty(axes_handles)
        for ax = axes_handles(:)'
            if isgraphics(ax), local_reset_preview(ax, message); end
        end
    end
    out = [];
    return;
end

label = [];
axes_grid = [];
try
    ud = container.UserData;
    if isstruct(ud)
        if isfield(ud, 'empty_label'), label = ud.empty_label; end
        if isfield(ud, 'axes_grid'), axes_grid = ud.axes_grid; end
    end
catch
end

if isempty(label) || ~isgraphics(label)
    label = uilabel(container, ...
        'Text', char(string(message)), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'center', ...
        'FontSize', 12, ...
        'FontColor', [0.35 0.35 0.35]);
    try
        label.Layout.Row = local_grid_span(container, 'row');
        label.Layout.Column = local_grid_span(container, 'column');
    catch
    end
end
try, label.Text = char(string(message)); catch, end
try, label.Visible = 'on'; catch, end

if ~isempty(axes_grid) && isgraphics(axes_grid)
    try, axes_grid.Visible = 'off'; catch, end
end
for ax = axes_handles(:)'
    if isgraphics(ax)
        try, cla(ax, 'reset'); catch, end
        try, ax.Visible = 'off'; catch, end
    end
end
try, container.UserData = struct('empty_label', label, 'axes_grid', axes_grid); catch, end
out = label;
end

function out = local_show_preview_group(container, axes_handles)
%LOCAL_SHOW_PREVIEW_GROUP Reveal a multi-axes preview and hide its empty label.
if nargin == 1
    axes_handles = [];
end
label = [];
axes_grid = [];
if ~isempty(container) && isgraphics(container)
    try
        ud = container.UserData;
        if isstruct(ud)
            if isfield(ud, 'empty_label'), label = ud.empty_label; end
            if isfield(ud, 'axes_grid'), axes_grid = ud.axes_grid; end
        end
    catch
    end
end
if ~isempty(label) && isgraphics(label)
    try, label.Visible = 'off'; catch, end
end
if ~isempty(axes_grid) && isgraphics(axes_grid)
    try, axes_grid.Visible = 'on'; catch, end
end
for ax = axes_handles(:)'
    if isgraphics(ax)
        try, ax.Visible = 'on'; catch, end
    end
end
out = axes_handles;
end

function span = local_grid_span(grid, dim)
span = 1;
try
    if strcmp(dim, 'row')
        n = numel(grid.RowHeight);
    else
        n = numel(grid.ColumnWidth);
    end
    if n > 1
        span = [1 n];
    end
catch
end
end

function out = local_show_preview(ax, paths)
if isempty(ax) || ~isgraphics(ax), out = []; return; end
paths = local_cellstr(paths);
if isempty(paths)
    out = local_reset_preview(ax);
    return;
end
path = paths{1};
if exist(path, 'file') ~= 2
    out = local_reset_preview(ax, 'preview file not found');
    return;
end
img = imread(path);
cla(ax);
image(ax, img);
axis(ax, 'image');
axis(ax, 'off');
out = ax;
end

function out = local_bind_preview_list(listbox, ax, png_paths)
png_paths = local_cellstr(png_paths);
if isempty(listbox) || ~isgraphics(listbox)
    out = {};
    return;
end
meta = local_preview_meta(listbox);
if isempty(png_paths)
    meta.paths = {};
    meta.run_ids = [];
    meta.run_counter = 0;
    listbox.Items = {};
    listbox.Value = {};
    listbox.UserData = meta;
    if nargin >= 2 && ~isempty(ax), local_reset_preview(ax); end
    out = {};
    return;
end
run_id = meta.run_counter + 1;
stored_paths = local_store_preview_paths(meta.project_root, meta.module_key, png_paths, run_id);
names = cellfun(@(pp) sprintf('#%02d  %s', run_id, local_display_name(pp)), stored_paths, 'UniformOutput', false);
old_items = local_cellstr(listbox.Items);
meta.paths = [meta.paths, stored_paths];
meta.run_ids = [meta.run_ids, repmat(run_id, 1, numel(stored_paths))];
meta.run_counter = run_id;
listbox.Items = [old_items, names];
listbox.UserData = meta;
if isempty(names)
    listbox.Value = {};
    if nargin >= 2 && ~isempty(ax), local_reset_preview(ax); end
else
    try
        listbox.Value = names(1);
    catch
        listbox.Value = names{1};
    end
    if nargin >= 2 && ~isempty(ax), local_show_preview(ax, stored_paths(1)); end
end
out = stored_paths;
end

function paths = local_selected_preview_paths(listbox, fallback_paths)
if nargin < 2, fallback_paths = {}; end
fallback_paths = local_cellstr(fallback_paths);
if isempty(listbox) || ~isgraphics(listbox)
    paths = fallback_paths;
    return;
end
all_paths = local_all_preview_paths(listbox);
selected = local_cellstr(listbox.Value);
items = local_cellstr(listbox.Items);
if isempty(selected)
    paths = all_paths;
    return;
end
idx = find(ismember(items, selected));
idx = idx(idx >= 1 & idx <= numel(all_paths));
paths = all_paths(idx);
end

function paths = local_all_preview_paths(listbox)
paths = {};
if isempty(listbox) || ~isgraphics(listbox)
    return;
end
ud = [];
try
    ud = listbox.UserData;
catch
end
if isstruct(ud) && isfield(ud, 'paths')
    paths = local_cellstr(ud.paths);
else
    paths = local_cellstr(ud);
end
end

function layout = local_preview_layout(ui, default_layout)
if nargin < 2, default_layout = 'auto'; end
layout = default_layout;
if isstruct(ui)
    fields = {'preview_layout_edit','preview_layout_field'};
    for k = 1:numel(fields)
        if isfield(ui, fields{k}) && ~isempty(ui.(fields{k})) && isgraphics(ui.(fields{k}))
            try
                layout = char(string(ui.(fields{k}).Value));
                return;
            catch
            end
        end
    end
end
end

function out = local_select_all(listbox)
if isempty(listbox) || ~isgraphics(listbox), out = []; return; end
listbox.Value = listbox.Items;
out = listbox.Value;
end

function out = local_select_none(listbox)
if isempty(listbox) || ~isgraphics(listbox), out = []; return; end
listbox.Value = {};
out = {};
end

function out = local_delete_selection(listbox, ax)
if nargin < 2, ax = []; end
if isempty(listbox) || ~isgraphics(listbox), out = {}; return; end
items = local_cellstr(listbox.Items);
meta = local_preview_meta(listbox);
paths = meta.paths;
run_ids = meta.run_ids;
selected = local_cellstr(listbox.Value);
if isempty(items)
    out = {};
    return;
end
if isempty(selected)
    idx = [];
else
    idx = find(ismember(items, selected));
end
if isempty(idx)
    out = paths;
    return;
end
for ii = idx(:).'
    if ii >= 1 && ii <= numel(paths)
        fp = paths{ii};
        if exist(fp, 'file') == 2
            try
                delete(fp);
            catch
            end
        end
    end
end
keep = true(1, numel(items));
keep(idx) = false;
items = items(keep);
paths = paths(keep);
if ~isempty(run_ids)
    run_ids = run_ids(keep);
end
meta.paths = paths;
meta.run_ids = run_ids;
listbox.Items = items;
listbox.UserData = meta;
if isempty(items)
    listbox.Value = {};
    if ~isempty(ax), local_reset_preview(ax); end
else
    try
        listbox.Value = items(1);
    catch
        listbox.Value = items{1};
    end
    if ~isempty(ax), local_show_preview(ax, paths(1)); end
end
out = paths;
end

function out = local_move_selection(listbox, direction)
if isempty(listbox) || ~isgraphics(listbox), out = []; return; end
items = local_cellstr(listbox.Items);
meta = local_preview_meta(listbox);
paths = meta.paths;
run_ids = meta.run_ids;
sel = local_cellstr(listbox.Value);
if isempty(sel) || isempty(items), out = items; return; end
idx = find(ismember(items, sel));
if isempty(idx), out = items; return; end

if direction < 0
    idx = sort(idx, 'ascend');
    for k = 1:numel(idx)
        i = idx(k);
        if i > 1 && ~ismember(i-1, idx)
            [items{i-1}, items{i}] = deal(items{i}, items{i-1});
            [paths{i-1}, paths{i}] = deal(paths{i}, paths{i-1});
            if ~isempty(run_ids)
                tmp_run_id = run_ids(i-1);
                run_ids(i-1) = run_ids(i);
                run_ids(i) = tmp_run_id;
            end
            idx(k) = i-1;
        end
    end
else
    idx = sort(idx, 'descend');
    for k = 1:numel(idx)
        i = idx(k);
        if i < numel(items) && ~ismember(i+1, idx)
            [items{i+1}, items{i}] = deal(items{i}, items{i+1});
            [paths{i+1}, paths{i}] = deal(paths{i}, paths{i+1});
            if ~isempty(run_ids)
                tmp_run_id = run_ids(i+1);
                run_ids(i+1) = run_ids(i);
                run_ids(i) = tmp_run_id;
            end
            idx(k) = i+1;
        end
    end
end

listbox.Items = items;
meta.paths = paths;
meta.run_ids = run_ids;
listbox.UserData = meta;
listbox.Value = sel;
out = items;
end


function out = local_preview_composite(varargin)
% Supports both signatures:
%   local_preview_composite(ui)
%   local_preview_composite(ax, listbox, project_root, module_key, layout)
if nargin == 1 && isstruct(varargin{1})
    ui = varargin{1};
    paths = local_selected_preview_paths(ui.preview_list, {});
    if isempty(paths)
        out = '';
        return;
    end
    layout = local_preview_layout(ui, 'auto');
    tmp = [tempname, '.png'];
    local_compose_grid(paths, tmp, 'Layout', layout);
    local_show_preview(ui.preview_axes, {tmp});
    out = tmp;
    return;
end

ax = varargin{1};
listbox = varargin{2};
project_root = varargin{3};
module_key = varargin{4};
layout = 'auto';
if nargin >= 5 && ~isempty(varargin{5})
    layout = varargin{5};
end
paths = local_selected_preview_paths(listbox, {});
if isempty(paths)
    error('Select at least one image to preview.');
end
cache_dir = local_cache_dir(project_root, [local_slug(module_key) '_composite']);
out = fullfile(cache_dir, 'preview_composite.png');
local_compose_grid(paths, out, 'Layout', layout);
local_show_preview(ax, {out});
end

function out = local_run_core_script(render_path, ax, style)
%LOCAL_RUN_CORE_SCRIPT Execute a render.m script in a normal function workspace.
% The workspace intentionally exposes ax and style, matching the old project helper.
if nargin < 3 || isempty(style)
    style = 'default';
end
if ~exist(render_path, 'file')
    error('Core render file not found: %s', render_path);
end
run(render_path);
out = ax;
end

function export_info = local_export_preview_bundle(project_root, module_key, axes_handles, axes_names, layout_shape, param_lines, notes_lines, status_lines, dlg)
%LOCAL_EXPORT_PREVIEW_BUNDLE Multi-axes export bridge used by the optics tabs.
if nargin < 9, dlg = []; end %#ok<NASGU>
if isrow(axes_handles), axes_handles = axes_handles(:); end
if isrow(axes_names), axes_names = axes_names(:); end

cache_dir = local_clear_cache(project_root, ['export_' module_key]);
image_paths = cell(numel(axes_handles), 1);
for k = 1:numel(axes_handles)
    filename = local_indexed_name(axes_names{k}, k, '.png');
    image_paths{k} = local_save_figure(axes_handles(k), cache_dir, filename, 300);
end

if nargin < 5 || isempty(layout_shape)
    layout = 'auto';
elseif numel(layout_shape) >= 2
    layout = sprintf('columns:%d', layout_shape(2));
else
    layout = sprintf('columns:%d', layout_shape(1));
end

params = struct('module', module_key, ...
    'parameters', {local_lines(param_lines)}, ...
    'notes', {local_lines(notes_lines)}, ...
    'status', {local_lines(status_lines)});

info = local_export_bundle(project_root, module_key, image_paths, ...
    'Params', params, 'Composite', true, 'Layout', layout);

export_info = struct('bundle_dir', info.output_dir, ...
    'composite_path', info.composite, ...
    'report_path', fullfile(info.output_dir, 'parameters.txt'), ...
    'files', {info.files});
end

function cleanup_obj = local_hidden_figures()
%LOCAL_HIDDEN_FIGURES Temporarily suppress MATLAB figure windows.
old_visibility = get(groot, 'DefaultFigureVisible');
set(groot, 'DefaultFigureVisible', 'off');
cleanup_obj = onCleanup(@() set(groot, 'DefaultFigureVisible', old_visibility));
end

function fig = local_hidden_figure(varargin)
%LOCAL_HIDDEN_FIGURE Create a white, noninteractive, hidden export figure.
p = inputParser;
p.addParameter('Position', [100 100 900 750]);
p.addParameter('Color', 'w');
p.addParameter('Name', '');
p.parse(varargin{:});
opt = p.Results;
fig = figure( ...
    'Visible', 'off', ...
    'HandleVisibility', 'off', ...
    'IntegerHandle', 'off', ...
    'MenuBar', 'none', ...
    'ToolBar', 'none', ...
    'NumberTitle', 'off', ...
    'Name', char(string(opt.Name)), ...
    'Color', opt.Color, ...
    'Position', opt.Position);
set(fig, 'Visible', 'off');
end

function frame = local_export_frame(fig, resolution, target_size)
%LOCAL_EXPORT_FRAME Export a figure to an RGB frame and optionally pad/crop to target_size.
if nargin < 2 || isempty(resolution), resolution = 160; end
if nargin < 3, target_size = []; end
tmp_png = [tempname, '.png'];
try
    exportgraphics(fig, tmp_png, 'Resolution', resolution, 'BackgroundColor', 'white', 'Padding', [5 5 5 5]);
catch
    print(fig, tmp_png, '-dpng', sprintf('-r%d', resolution));
end
frame = imread(tmp_png);
if exist(tmp_png, 'file') == 2
    delete(tmp_png);
end
frame = local_normalize_video_frame(frame, target_size);
end

function frame = local_normalize_video_frame(frame, target_size)
%LOCAL_NORMALIZE_VIDEO_FRAME Ensure VideoWriter frames have one RGB size.
if size(frame, 3) == 1
    frame = repmat(frame, [1 1 3]);
elseif size(frame, 3) > 3
    frame = frame(:,:,1:3);
end
if isempty(target_size)
    return;
end
target_h = target_size(1);
target_w = target_size(2);
[h, w, ~] = size(frame);
if h < target_h
    pad_top = floor((target_h - h)/2);
    pad_bottom = target_h - h - pad_top;
    frame = cat(1, uint8(255)*ones(pad_top, w, 3, 'uint8'), frame, uint8(255)*ones(pad_bottom, w, 3, 'uint8'));
elseif h > target_h
    start_row = floor((h - target_h)/2) + 1;
    frame = frame(start_row:start_row+target_h-1, :, :);
end
[h, w, ~] = size(frame);
if w < target_w
    pad_left = floor((target_w - w)/2);
    pad_right = target_w - w - pad_left;
    frame = cat(2, uint8(255)*ones(h, pad_left, 3, 'uint8'), frame, uint8(255)*ones(h, pad_right, 3, 'uint8'));
elseif w > target_w
    start_col = floor((w - target_w)/2) + 1;
    frame = frame(:, start_col:start_col+target_w-1, :);
end
end

function lines = local_lines(value)
if nargin == 0 || isempty(value)
    lines = {};
elseif iscell(value)
    lines = cellfun(@char, value(:), 'UniformOutput', false);
elseif isstring(value)
    lines = cellstr(value(:));
else
    lines = cellstr(splitlines(string(value)));
end
end

function path = local_save_figure(fig_or_ax, folder_path, file_name, dpi)
if nargin < 4 || isempty(dpi), dpi = 260; end
if exist(folder_path, 'dir') ~= 7, mkdir(folder_path); end
file_name = char(string(file_name));
if isempty(fileparts(file_name)) && isempty(regexp(file_name, '\.(png|jpg|jpeg|tif|tiff|pdf)$', 'once'))
    file_name = [file_name, '.png'];
end
path = fullfile(folder_path, file_name);

if isgraphics(fig_or_ax, 'axes')
    target = fig_or_ax;
elseif isgraphics(fig_or_ax, 'figure')
    target = fig_or_ax;
else
    error('Expected a figure or axes handle.');
end

% Do not hide the parent figure here.  UIAxes belong to the visible app
% window; forcing ancestor(fig,'Visible') = 'off' makes export callbacks
% appear to "flash close" and also prevents uialert/uiprogressdlg from using
% the app figure as their modal host.  Hidden export figures are already
% created hidden by image_output('hidden_figure'), so exportgraphics can write
% them without changing the GUI figure state.
try
    exportgraphics(target, path, 'Resolution', dpi, 'BackgroundColor', 'white', 'Padding', [5 5 5 5]);
catch
    % exportgraphics with Padding may not be supported in older releases.
    try
        exportgraphics(target, path, 'Resolution', dpi, 'BackgroundColor', 'white');
    catch ME
        % Hidden ordinary figures can be printed even when exportgraphics refuses
        % them.  UIAxes should normally succeed above; if neither backend can
        % write the file, keep the original diagnostic.
        try
            if isgraphics(fig_or_ax, 'axes')
                fig = ancestor(fig_or_ax, 'figure');
            else
                fig = fig_or_ax;
            end
            print(fig, path, '-dpng', sprintf('-r%d', dpi));
        catch
            rethrow(ME);
        end
    end
end
local_auto_crop(path);
end

function out_path = local_compose_grid(png_paths, out_path, varargin)
p = inputParser;
p.addParameter('Layout', 'auto');
p.addParameter('Background', uint8(255));
p.addParameter('Padding', 40);
p.parse(varargin{:});
opt = p.Results;

png_paths = local_cellstr(png_paths);
png_paths = png_paths(cellfun(@(p) exist(p,'file') == 2, png_paths));
if isempty(png_paths)
    error('No images to compose.');
end

imgs = cell(size(png_paths));
for i = 1:numel(png_paths)
    img = imread(png_paths{i});
    if size(img,3) == 1, img = repmat(img, [1 1 3]); end
    if size(img,3) > 3, img = img(:,:,1:3); end
    imgs{i} = img;
end

rows = local_layout_rows(opt.Layout, numel(imgs));
nrows = numel(rows);
ncols = max(rows);
cell_h = max(cellfun(@(im) size(im,1), imgs));
cell_w = max(cellfun(@(im) size(im,2), imgs));
pad = opt.Padding;
canvas_h = nrows * cell_h + (nrows+1) * pad;
canvas_w = ncols * cell_w + (ncols+1) * pad;
canvas = uint8(opt.Background) * ones(canvas_h, canvas_w, 3, 'uint8');

idx = 1;
for r = 1:nrows
    cols = rows(r);
    row_w = cols * cell_w + (cols-1) * pad;
    x0 = floor((canvas_w - row_w)/2) + 1;
    for c = 1:cols
        if idx > numel(imgs), break; end
        im = imgs{idx};
        h = size(im,1); w = size(im,2);
        y = pad + (r-1)*(cell_h+pad) + floor((cell_h-h)/2) + 1;
        x = x0 + (c-1)*(cell_w+pad) + floor((cell_w-w)/2);
        canvas(y:y+h-1, x:x+w-1, :) = im;
        idx = idx + 1;
    end
end

if exist(fileparts(out_path), 'dir') ~= 7 && ~isempty(fileparts(out_path))
    mkdir(fileparts(out_path));
end
imwrite(canvas, out_path);
end

function out_dir = local_output_dir(project_root, module_key)
if nargin < 2 || isempty(module_key)
    module_key = 'result';
end
output_root = fullfile(project_root, 'output');
if exist(output_root, 'dir') ~= 7
    mkdir(output_root);
end
stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
base_name = local_slug(module_key);
out_dir = fullfile(output_root, [base_name '_' stamp]);
suffix = 1;
while exist(out_dir, 'dir') == 7
    out_dir = fullfile(output_root, sprintf('%s_%s_%02d', base_name, stamp, suffix));
    suffix = suffix + 1;
end
mkdir(out_dir);
end

function info = local_export_bundle(project_root, module_key, png_paths, varargin)
p = inputParser;
p.addParameter('Params', struct());
p.addParameter('ReproduceCode', '');
p.addParameter('Composite', true);
p.addParameter('Layout', 'auto');
p.addParameter('Filename', '');
p.addParameter('ExtraText', '');
p.parse(varargin{:});
opt = p.Results;

out_root = fullfile(project_root, 'output');
if exist(out_root, 'dir') ~= 7, mkdir(out_root); end
stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
module_key = local_slug(module_key);
out_dir = fullfile(out_root, [module_key, '_', stamp]);
suffix = 1;
while exist(out_dir, 'dir') == 7
    out_dir = fullfile(out_root, sprintf('%s_%s_%02d', module_key, stamp, suffix));
    suffix = suffix + 1;
end
mkdir(out_dir);

png_paths = local_cellstr(png_paths);
files = cell(1, numel(png_paths));
for i = 1:numel(png_paths)
    src = png_paths{i};
    if exist(src, 'file') ~= 2, continue; end
    if isempty(opt.Filename)
        dst_name = local_export_file_name(src, i);
    else
        dst_name = opt.Filename;
        if numel(png_paths) > 1
            dst_name = local_export_file_name(dst_name, i);
        end
    end
    dst = fullfile(out_dir, dst_name);
    copyfile(src, dst, 'f');
    files{i} = dst;
end
files = files(~cellfun(@isempty, files));

composite_path = '';
if opt.Composite && numel(files) > 1
    composite_path = fullfile(out_dir, 'composite.png');
    local_compose_grid(files, composite_path, 'Layout', opt.Layout);
elseif opt.Composite && numel(files) == 1
    composite_path = files{1};
end

params_output('write_with_reproduce', out_dir, opt.Params, opt.ReproduceCode, ...
    'ExtraText', opt.ExtraText);

info = struct('output_dir', out_dir, ...
    'files', {files}, ...
    'composite', composite_path, ...
    'parameters', fullfile(out_dir, 'parameters.txt'), ...
    'reproduce_code', fullfile(out_dir, 'reproduce_code.m'));
end


function dst_name = local_export_file_name(src_or_name, idx)
%LOCAL_EXPORT_FILE_NAME Canonical two-digit export names.
dst_name = local_indexed_name(src_or_name, idx, '.png');
end

function name = local_indexed_name(src_or_label, idx, default_ext)
%LOCAL_INDEXED_NAME Return a shared two-digit file name such as 01_object.png.
if nargin < 3 || isempty(default_ext)
    default_ext = '.png';
end
[src_path, base, ext] = fileparts(char(string(src_or_label))); %#ok<ASGLU>
if isempty(base) && ~isempty(src_path)
    base = src_path;
end
if isempty(ext)
    ext = char(string(default_ext));
end
base = regexprep(base, '^\d{1,4}[_\-\s]+', '');
base = local_clean_label(base);
base = local_slug(base);
if isempty(base)
    base = 'image';
end
name = sprintf('%02d_%s%s', idx, base, ext);
end

function s = local_slug(txt)
s = lower(char(string(txt)));
s = regexprep(s, '[^a-z0-9]+', '_');
s = regexprep(s, '_+', '_');
s = regexprep(s, '^_|_$', '');
if isempty(s), s = 'item'; end
end

function rows = local_layout_rows(layout, n)
if nargin < 2, n = 1; end
if isempty(layout), layout = 'auto'; end
layout = strtrim(lower(char(string(layout))));
if isempty(layout) || strcmp(layout, 'auto')
    r = ceil(sqrt(n));
    c = ceil(n / r);
    rows = c * ones(1, r);
    rows(end) = n - c*(r-1);
    rows = rows(rows > 0);
elseif startsWith(layout, 'columns:')
    c = str2double(extractAfter(layout, 'columns:'));
    c = max(1, round(c));
    rows = c * ones(1, ceil(n/c));
    rows(end) = n - c*(numel(rows)-1);
elseif contains(layout, '+')
    rows = sscanf(strrep(layout, '+', ' '), '%d').';
    rows = rows(rows > 0);
    if sum(rows) < n
        rows(end+1) = n - sum(rows);
    end
elseif ~isnan(str2double(layout))
    c = max(1, round(str2double(layout)));
    rows = c * ones(1, ceil(n/c));
    rows(end) = n - c*(numel(rows)-1);
else
    rows = local_layout_rows('auto', n);
end
end

function v = local_parse_range(txt, default_value)
if nargin < 2, default_value = []; end
s = strtrim(char(string(txt)));
if isempty(s)
    v = default_value;
    return;
end
if startsWith(s, '(') && endsWith(s, ')')
    s = strtrim(s(2:end-1));
end
if contains(s, ':')
    nums = str2double(regexp(s, ':', 'split'));
    if numel(nums) == 2
        v = nums(1):nums(2);
    elseif numel(nums) == 3
        v = nums(1):nums(2):nums(3);
    else
        error('Invalid range syntax.');
    end
else
    v = sscanf(regexprep(s, '[,;]+', ' '), '%f').';
end
if isempty(v)
    v = default_value;
end
end

function v = local_parse_optional_range(txt, default_value)
if nargin < 2, default_value = []; end
s1 = strtrim(char(string(txt)));
s2 = strtrim(char(string(default_value)));
if isempty(s1) && isempty(s2)
    v = [];
elseif ~isempty(s1) && ~isempty(s2) && isempty(regexp(s1, '[,;:\s]', 'once')) && isempty(regexp(s2, '[,;:\s]', 'once'))
    v = [str2double(s1), str2double(s2)];
    if any(~isfinite(v))
        v = local_parse_range(strjoin({s1, s2}, ' '));
    end
elseif isempty(s1)
    v = local_parse_range(s2);
else
    v = local_parse_range(s1);
end
end

function [xlimv, ylimv] = local_crop_limits(x, y, mask)
if isempty(mask) || isstruct(mask) || ischar(mask) || isstring(mask)
    xlimv = [min(x(:)) max(x(:))];
    ylimv = [min(y(:)) max(y(:))];
    return;
end
mask = logical(mask);
[row, col] = find(mask);
if isempty(row)
    xlimv = [min(x(:)) max(x(:))];
    ylimv = [min(y(:)) max(y(:))];
    return;
end
xv = x(:).';
yv = y(:);
xlimv = [xv(max(1,min(col))) xv(min(numel(xv),max(col)))];
ylimv = [yv(max(1,min(row))) yv(min(numel(yv),max(row)))];
end

function lim = local_common_3d_limits(items)
%LOCAL_COMMON_3D_LIMITS Robust common 3-D limits for surface/vector previews.
if isempty(items)
    lim = [-1 1 -1 1 -1 1];
    return;
end
if isstruct(items)
    items = num2cell(items);
end
lim = [inf -inf inf -inf inf -inf];
for k = 1:numel(items)
    it = items{k};
    if ~isstruct(it), continue; end
    [xx, yy, zz] = local_3d_point_arrays(it);
    if ~isempty(xx), lim(1:2) = [min(lim(1), min(xx(:))) max(lim(2), max(xx(:)))]; end
    if ~isempty(yy), lim(3:4) = [min(lim(3), min(yy(:))) max(lim(4), max(yy(:)))]; end
    if ~isempty(zz), lim(5:6) = [min(lim(5), min(zz(:))) max(lim(6), max(zz(:)))]; end
end
defaults = [-1 1 -1 1 -1 1];
bad = ~isfinite(lim) | (lim == inf) | (lim == -inf);
lim(bad) = defaults(bad);
for j = 1:3
    ii = 2*j-1;
    if lim(ii) == lim(ii+1)
        pad = max(1e-6, abs(lim(ii))*0.05 + 1e-6);
        lim(ii:ii+1) = lim(ii) + [-pad pad];
    end
end
end

function [xx, yy, zz] = local_3d_point_arrays(it)
xx = []; yy = []; zz = [];
if isfield(it, 'x'), xx = [xx; it.x(:)]; end
if isfield(it, 'y'), yy = [yy; it.y(:)]; end
if isfield(it, 'z'), zz = [zz; it.z(:)]; end
if isfield(it, 'x_crop'), xx = [xx; it.x_crop(:)]; end
if isfield(it, 'y_crop'), yy = [yy; it.y_crop(:)]; end
if isfield(it, 'z_crop'), zz = [zz; it.z_crop(:)]; end
if isfield(it, 'sphere_x'), xx = [xx; it.sphere_x(:)]; end
if isfield(it, 'sphere_y'), yy = [yy; it.sphere_y(:)]; end
if isfield(it, 'sphere_z'), zz = [zz; it.sphere_z(:)]; end
if isfield(it, 'xq'), xx = [xx; it.xq(:)]; end
if isfield(it, 'yq'), yy = [yy; it.yq(:)]; end
if isfield(it, 'zq'), zz = [zz; it.zq(:)]; end
xx = xx(isfinite(xx)); yy = yy(isfinite(yy)); zz = zz(isfinite(zz));
end

function s = local_clean_label(txt)
s = char(string(txt));
s = regexprep(s, '\$|\\mathrm|\\', '');
s = regexprep(s, '[{}_^]', ' ');
s = strtrim(s);
end

function paths = local_cellstr(paths)
if nargin == 0 || isempty(paths)
    paths = {};
elseif ischar(paths)
    paths = {paths};
elseif isstring(paths)
    paths = cellstr(paths(:));
elseif iscell(paths)
    paths = paths(:).';
else
    paths = cellstr(string(paths));
end
end



function meta = local_preview_meta(listbox)
meta = struct('paths', {{}}, 'run_ids', [], 'project_root', pwd, 'module_key', 'preview', 'run_counter', 0);
if isempty(listbox) || ~isgraphics(listbox)
    return;
end
try
    ud = listbox.UserData;
catch
    ud = [];
end
if isstruct(ud)
    if isfield(ud, 'paths'), meta.paths = local_cellstr(ud.paths); end
    if isfield(ud, 'run_ids') && isnumeric(ud.run_ids), meta.run_ids = double(ud.run_ids(:).'); end
    if isfield(ud, 'project_root') && ~isempty(ud.project_root), meta.project_root = char(string(ud.project_root)); end
    if isfield(ud, 'module_key') && ~isempty(ud.module_key), meta.module_key = char(string(ud.module_key)); end
    if isfield(ud, 'run_counter') && ~isempty(ud.run_counter), meta.run_counter = double(ud.run_counter); end
else
    meta.paths = local_cellstr(ud);
end
if numel(meta.run_ids) ~= numel(meta.paths)
    meta.run_ids = zeros(1, numel(meta.paths));
end
end

function stored_paths = local_store_preview_paths(project_root, module_key, png_paths, run_id)
png_paths = local_cellstr(png_paths);
stored_paths = cell(1, numel(png_paths));
history_dir = fullfile(project_root, '.cache', 'preview_history', local_slug(module_key), sprintf('run_%02d', run_id));
if exist(history_dir, 'dir') ~= 7
    mkdir(history_dir);
end
for i = 1:numel(png_paths)
    src = png_paths{i};
    if exist(src, 'file') ~= 2
        stored_paths{i} = src;
        continue;
    end
    dst_name = local_indexed_name(src, i, '.png');
    dst = fullfile(history_dir, dst_name);
    copyfile(src, dst, 'f');
    stored_paths{i} = dst;
end
end

function name = local_display_name(path)
[~, n, e] = fileparts(path);
name = [n e];
end

function local_auto_crop(path)
%LOCAL_AUTO_CROP Trim whitespace from a PNG image, keeping 5 px margin.
% Detects the bounding box of non-white content and crops tightly.
if nargin < 1 || isempty(path) || exist(path, 'file') ~= 2
    return;
end
try
    img = imread(path);
    if size(img, 3) < 3, return; end
    siz = size(img);
    % Use double arithmetic to avoid uint8 wraparound
    diff = max(abs(double(img) - 255), [], 3);
    mask = diff > 10;
    rows = any(mask, 2);
    cols = any(mask, 1);
    if ~any(rows) || ~any(cols), return; end
    r0 = find(rows, 1, 'first');
    r1 = find(rows, 1, 'last');
    c0 = find(cols, 1, 'first');
    c1 = find(cols, 1, 'last');
    margin = 5;
    r0 = max(1, r0 - margin);
    r1 = min(siz(1), r1 + margin);
    c0 = max(1, c0 - margin);
    c1 = min(siz(2), c1 + margin);
    imwrite(img(r0:r1, c0:c1, :), path);
catch
    % Silently skip on failure
end
end
