function varargout = image_output(action, varargin)
switch lower(char(action))
    case 'ensure_cache'
        varargout{1} = local_ensure_cache(varargin{:});
    case 'ensure_output'
        varargout{1} = local_ensure_output(varargin{:});
    case 'save_cache'
        varargout{1} = local_save_cache(varargin{:});
    case 'save_cache_batch'
        varargout{1} = local_save_cache_batch(varargin{:});
    case 'show_preview'
        local_show_preview(varargin{:});
        varargout = {};
    case 'bind_preview_list'
        local_bind_preview_list(varargin{:});
        varargout = {};
    case 'preview_selection'
        varargout{1} = local_preview_selection(varargin{:});
    case 'compose_grid'
        varargout{1} = local_compose_grid(varargin{:});
    case 'export_bundle'
        varargout{1} = local_export_bundle(varargin{:});
    case 'copy_to_output'
        varargout{1} = local_copy_to_output(varargin{:});
    case 'parse_range'
        varargout{1} = local_parse_range(varargin{:});
    case 'parse_optional_range'
        varargout{1} = local_parse_optional_range(varargin{:});
    case 'crop_limits'
        [varargout{1:nargout}] = local_crop_limits(varargin{:});
    case 'parse_layout'
        varargout{1} = local_parse_layout(varargin{:});
    case 'slug'
        varargout{1} = local_slug(varargin{:});
    case 'clean_label'
        varargout{1} = local_clean_label(varargin{:});
    case 'common_3d_limits'
        varargout{1} = local_common_3d_limits(varargin{:});
    otherwise
        error('Unknown image_output action.');
end
end

function cache_dir = local_ensure_cache(project_root, module_key)
if nargin < 2 || isempty(module_key)
    cache_dir = fullfile(project_root, '.cache');
else
    cache_dir = fullfile(project_root, '.cache', char(module_key));
end
if exist(cache_dir, 'dir') ~= 7
    mkdir(cache_dir);
end
end

function output_dir = local_ensure_output(project_root)
output_dir = fullfile(project_root, 'output');
if exist(output_dir, 'dir') ~= 7
    mkdir(output_dir);
end
end

function png_path = local_save_cache(project_root, module_key, fig_or_ax, file_name, dpi)
if nargin < 5 || isempty(dpi)
    dpi = 220;
end
if nargin < 4 || isempty(file_name)
    file_name = 'preview.png';
end
cache_dir = local_ensure_cache(project_root, module_key);
png_path = fullfile(cache_dir, char(file_name));
exportgraphics(fig_or_ax, png_path, 'Resolution', dpi, 'BackgroundColor', 'white');
end

function paths = local_save_cache_batch(project_root, module_key, handles, names, dpi)
if nargin < 5 || isempty(dpi)
    dpi = 220;
end
if ~iscell(handles)
    handles = num2cell(handles);
end
if nargin < 4 || isempty(names)
    names = cell(1, numel(handles));
    for k = 1:numel(handles)
        names{k} = sprintf('preview_%03d.png', k);
    end
else
    names = local_cellstr(names);
end
paths = cell(1, numel(handles));
for k = 1:numel(handles)
    paths{k} = local_save_cache(project_root, module_key, handles{k}, names{k}, dpi);
end
end

function local_show_preview(ax, png_path)
if isempty(ax) || ~ishandle(ax)
    return;
end
if exist(png_path, 'file') ~= 2
    error('Preview file not found.');
end
img = imread(png_path);
cla(ax);
image(ax, img);
axis(ax, 'image');
ax.XTick = [];
ax.YTick = [];
ax.Visible = 'off';
try ax.Toolbar.Visible = 'off'; catch, end
drawnow;
end

function local_bind_preview_list(ui_or_list, varargin)
if isstruct(ui_or_list)
    ui = ui_or_list;
    list = ui.preview_list;
    ax = ui.preview_axes;
    if isempty(varargin)
        paths = {};
        rest = {};
    else
        paths = varargin{1};
        rest = varargin(2:end);
    end
else
    list = ui_or_list;
    if numel(varargin) < 2
        error('bind_preview_list requires list, axes, and paths.');
    end
    ax = varargin{1};
    paths = varargin{2};
    rest = varargin(3:end);
end
p = inputParser;
p.addParameter('Labels', {});
p.addParameter('Select', 'all');
p.parse(rest{:});
opt = p.Results;

paths = local_cellstr(paths);
labels = local_cellstr(opt.Labels);
if isempty(labels)
    labels = local_default_labels(paths);
end
labels = local_unique_labels(labels);

if isempty(list) || ~ishandle(list)
    if ~isempty(paths)
        local_show_preview(ax, paths{1});
    end
    return;
end

list.Items = labels;
list.UserData = struct('paths', {paths}, 'labels', {labels}, 'force_empty', false);
if isempty(labels)
    try list.Value = {}; catch, end
else
    switch lower(char(opt.Select))
        case 'first'
            list.Value = labels{1};
        case 'none'
            try list.Value = {}; catch, list.Value = labels{1}; end
        otherwise
            if strcmp(list.Multiselect, 'on')
                list.Value = labels;
            else
                list.Value = labels{1};
            end
    end
end
list.ValueChangedFcn = @(~,~) local_preview_list_changed(list, ax);
local_preview_list_changed(list, ax);

if isstruct(ui_or_list)
    try ui.preview_up_button.ButtonPushedFcn = @(~,~) local_move_selection(list, ax, -1); catch, end
    try ui.preview_down_button.ButtonPushedFcn = @(~,~) local_move_selection(list, ax, 1); catch, end
    try ui.preview_all_button.ButtonPushedFcn = @(~,~) local_select_all(list, ax); catch, end
    try ui.preview_none_button.ButtonPushedFcn = @(~,~) local_select_none(list); catch, end
    try ui.preview_composite_button.ButtonPushedFcn = @(~,~) local_preview_composite(ui); catch, end
end
end

function info = local_preview_selection(ui_or_list)
if isstruct(ui_or_list)
    list = ui_or_list.preview_list;
else
    list = ui_or_list;
end
info = struct('paths', {{}}, 'labels', {{}}, 'indices', []);
if isempty(list) || ~ishandle(list)
    return;
end
ud = list.UserData;
if ~isstruct(ud) || ~isfield(ud, 'paths')
    return;
end
items = local_cellstr(list.Items);
values = local_cellstr(list.Value);
if isfield(ud, 'force_empty') && ud.force_empty
    return;
end
if isempty(values)
    values = items;
end
indices = [];
for k = 1:numel(items)
    if any(strcmp(values, items{k}))
        indices(end+1) = k; %#ok<AGROW>
    end
end
indices = indices(indices >= 1 & indices <= numel(ud.paths));
info.indices = indices;
info.paths = ud.paths(indices);
info.labels = items(indices);
end

function local_preview_list_changed(list, ax)
ud = list.UserData;
if isstruct(ud)
    ud.force_empty = false;
    list.UserData = ud;
end
info = local_preview_selection(list);
if isempty(info.paths)
    return;
end
local_show_preview(ax, info.paths{1});
end

function local_move_selection(list, ax, direction)
if isempty(list.Items)
    return;
end
items = local_cellstr(list.Items);
values = local_cellstr(list.Value);
if isempty(values)
    return;
end
ud = list.UserData;
paths = ud.paths;
selected = find(ismember(items, values));
if isempty(selected)
    return;
end
if direction < 0
    for k = 1:numel(selected)
        i = selected(k);
        if i > 1 && ~ismember(i-1, selected)
            [items{i-1}, items{i}] = deal(items{i}, items{i-1});
            [paths{i-1}, paths{i}] = deal(paths{i}, paths{i-1});
            selected(k) = i - 1;
        end
    end
else
    for k = numel(selected):-1:1
        i = selected(k);
        if i < numel(items) && ~ismember(i+1, selected)
            [items{i+1}, items{i}] = deal(items{i}, items{i+1});
            [paths{i+1}, paths{i}] = deal(paths{i}, paths{i+1});
            selected(k) = i + 1;
        end
    end
end
list.Items = items;
list.UserData = struct('paths', {paths}, 'labels', {items}, 'force_empty', false);
if strcmp(list.Multiselect, 'on')
    list.Value = values;
else
    list.Value = values{1};
end
local_preview_list_changed(list, ax);
end

function local_select_all(list, ax)
items = local_cellstr(list.Items);
if isempty(items)
    return;
end
if strcmp(list.Multiselect, 'on')
    list.Value = items;
else
    list.Value = items{1};
end
local_preview_list_changed(list, ax);
end

function local_select_none(list)
ud = list.UserData;
if isstruct(ud)
    ud.force_empty = true;
    list.UserData = ud;
end
try
    old_fcn = list.ValueChangedFcn;
    list.ValueChangedFcn = [];
    list.Value = {};
    list.ValueChangedFcn = old_fcn;
catch
end
end

function local_preview_composite(ui)
info = local_preview_selection(ui);
if isempty(info.paths)
    return;
end
layout = 'auto';
try
    if isfield(ui, 'preview_layout_field') && ~isempty(ui.preview_layout_field)
        layout = char(string(ui.preview_layout_field.Value));
    end
catch
end
try
    cache_dir = local_ensure_cache(ui.project_root, 'composite_preview');
catch
    cache_dir = tempdir;
end
stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss_SSS'));
out_png = fullfile(cache_dir, ['composite_' stamp '.png']);
local_compose_grid(info.paths, out_png, 'Layout', layout);
local_show_preview(ui.preview_axes, out_png);
end

function composite_path = local_compose_grid(png_paths, output_png, varargin)
p = inputParser;
p.addParameter('Layout', 'auto');
p.addParameter('Padding', 18);
p.addParameter('BackgroundColor', [255 255 255]);
p.addParameter('CenterRows', true);
p.parse(varargin{:});
opt = p.Results;
png_paths = local_cellstr(png_paths);
if isempty(png_paths)
    error('No images to compose.');
end
layout = local_parse_layout(opt.Layout, numel(png_paths));
img = local_compose_images(png_paths, layout, opt.Padding, opt.BackgroundColor, opt.CenterRows);
folder = fileparts(output_png);
if ~isempty(folder) && exist(folder, 'dir') ~= 7
    mkdir(folder);
end
imwrite(img, output_png);
composite_path = output_png;
end

function info = local_copy_to_output(project_root, module_key, png_paths, varargin)
p = inputParser;
p.addParameter('OutputDir', '');
p.addParameter('ParamLines', {});
p.addParameter('ReproduceCode', '');
p.parse(varargin{:});
opt = p.Results;
png_paths = local_cellstr(png_paths);
output_dir = char(opt.OutputDir);
if isempty(output_dir)
    output_dir = local_new_output_dir(project_root, module_key);
elseif exist(output_dir, 'dir') ~= 7
    mkdir(output_dir);
end
files = local_copy_files(png_paths, output_dir);
if ~isempty(opt.ParamLines)
    params_output('write_lines', output_dir, opt.ParamLines);
end
if strlength(string(opt.ReproduceCode)) > 0
    params_output('write_reproduce', output_dir, opt.ReproduceCode);
end
info = struct('output_dir', output_dir, 'files', {files});
end

function info = local_export_bundle(project_root, module_key, png_paths, varargin)
p = inputParser;
p.addParameter('Params', struct());
p.addParameter('ParamLines', {});
p.addParameter('RunFunction', '');
p.addParameter('ReproduceCode', '');
p.addParameter('ProjectRoot', project_root);
p.addParameter('Composite', true);
p.addParameter('Layout', 'auto');
p.addParameter('CompositeName', 'composite.png');
p.addParameter('ExtraCode', '');
p.addParameter('OutputDir', '');
p.parse(varargin{:});
opt = p.Results;
png_paths = local_cellstr(png_paths);
if isempty(png_paths)
    error('No images to export.');
end
if isempty(char(opt.OutputDir))
    output_dir = local_new_output_dir(project_root, module_key);
else
    output_dir = char(opt.OutputDir);
    if exist(output_dir, 'dir') ~= 7
        mkdir(output_dir);
    end
end
copied = local_copy_files(png_paths, output_dir);
composite_path = '';
if opt.Composite && numel(copied) > 1
    composite_path = fullfile(output_dir, char(opt.CompositeName));
    local_compose_grid(copied, composite_path, 'Layout', opt.Layout);
end
params = opt.Params;
if isstruct(params)
    params.output_dir = output_dir;
    params.output_layout = char(opt.Layout);
end
if ~isempty(opt.ParamLines)
    parameters_path = params_output('write_lines', output_dir, opt.ParamLines);
else
    parameters_path = params_output('write', output_dir, params);
end
if strlength(string(opt.ReproduceCode)) > 0
    reproduce_code = char(string(opt.ReproduceCode));
else
    reproduce_code = params_output('reproduce_code', params, ...
        'RunFunction', opt.RunFunction, ...
        'ProjectRoot', opt.ProjectRoot, ...
        'ExtraCode', opt.ExtraCode);
end
reproduce_path = params_output('write_reproduce', output_dir, reproduce_code);
info = struct();
info.output_dir = output_dir;
info.files = copied;
info.composite_path = composite_path;
info.parameters_path = parameters_path;
info.reproduce_path = reproduce_path;
info.reproduce_code = reproduce_code;
end

function output_dir = local_new_output_dir(project_root, module_key)
root = local_ensure_output(project_root);
stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
base = sprintf('%s_%s', char(module_key), stamp);
output_dir = fullfile(root, base);
i = 1;
while exist(output_dir, 'dir') == 7
    output_dir = fullfile(root, sprintf('%s_%02d', base, i));
    i = i + 1;
end
mkdir(output_dir);
end

function copied = local_copy_files(paths, output_dir)
paths = local_cellstr(paths);
copied = cell(1, numel(paths));
for k = 1:numel(paths)
    src = paths{k};
    if exist(src, 'file') ~= 2
        error('Source image not found: %s', src);
    end
    [~, name, ext] = fileparts(src);
    dst = fullfile(output_dir, sprintf('%02d_%s%s', k, name, ext));
    copyfile(src, dst);
    copied{k} = dst;
end
end

function img = local_compose_images(paths, layout, padding, bg, center_rows)
if nargin < 5 || isempty(center_rows)
    center_rows = true;
end
imgs = cell(1, numel(paths));
max_h = 0;
max_w = 0;
for k = 1:numel(paths)
    im = imread(paths{k});
    if ndims(im) == 2
        im = repmat(im, 1, 1, 3);
    end
    if size(im, 3) == 4
        im = im(:, :, 1:3);
    end
    im = local_to_uint8(im);
    imgs{k} = im;
    max_h = max(max_h, size(im, 1));
    max_w = max(max_w, size(im, 2));
end
max_cols = max(layout);
rows = numel(layout);
bg = local_bg(bg);
canvas_h = rows * max_h + (rows + 1) * padding;
canvas_w = max_cols * max_w + (max_cols + 1) * padding;
img = repmat(reshape(bg, 1, 1, 3), canvas_h, canvas_w, 1);
idx = 1;
for r = 1:rows
    n_this = layout(r);
    row_w = n_this * max_w + (n_this - 1) * padding;
    if center_rows
        x0 = round((canvas_w - row_w) / 2) + 1;
    else
        x0 = padding + 1;
    end
    y0 = padding + (r - 1) * (max_h + padding) + 1;
    for c = 1:n_this
        if idx > numel(imgs)
            return;
        end
        im = imgs{idx};
        h = size(im, 1);
        w = size(im, 2);
        cell_x = x0 + (c - 1) * (max_w + padding);
        x = cell_x + floor((max_w - w) / 2);
        y = y0 + floor((max_h - h) / 2);
        img(y:y+h-1, x:x+w-1, :) = im;
        idx = idx + 1;
    end
end
end

function layout = local_parse_layout(spec, n)
if nargin < 2 || isempty(n)
    n = 1;
end
if isnumeric(spec)
    if isscalar(spec)
        cols = max(1, round(spec));
        layout = local_default_row_counts(n, cols);
    else
        layout = round(spec(:).');
    end
elseif ischar(spec) || isstring(spec)
    txt = strtrim(char(string(spec)));
    if isempty(txt) || strcmpi(txt, 'auto')
        cols = 4;
        layout = local_default_row_counts(n, cols);
        return;
    end
    if ~isempty(regexp(txt, '^\d+$', 'once'))
        cols = max(1, round(str2double(txt)));
        layout = local_default_row_counts(n, cols);
        return;
    end
    txt = strrep(txt, '+', ',');
    txt = strrep(txt, 'x', ',');
    txt = strrep(txt, 'X', ',');
    txt = regexprep(txt, '\s+', ',');
    parts = regexp(txt, ',', 'split');
    nums = [];
    for k = 1:numel(parts)
        p = strtrim(parts{k});
        if isempty(p)
            continue;
        end
        v = str2double(p);
        if ~isnan(v) && isfinite(v) && v > 0
            nums(end+1) = round(v); %#ok<AGROW>
        end
    end
    if isempty(nums)
        layout = local_default_row_counts(n, 4);
    else
        layout = nums(:).';
    end
else
    layout = local_default_row_counts(n, 4);
end
layout = layout(isfinite(layout) & layout > 0);
if isempty(layout)
    layout = local_default_row_counts(n, 4);
end
if sum(layout) < n
    extra = n - sum(layout);
    cols = max(layout);
    layout = [layout local_default_row_counts(extra, cols)]; %#ok<AGROW>
elseif sum(layout) > n
    total = 0;
    keep = [];
    for k = 1:numel(layout)
        if total + layout(k) < n
            keep(end+1) = layout(k); %#ok<AGROW>
            total = total + layout(k);
        else
            last = n - total;
            if last > 0
                keep(end+1) = last; %#ok<AGROW>
            end
            break;
        end
    end
    layout = keep;
end
end

function row_counts = local_default_row_counts(N, cols)
if N <= 0
    row_counts = [];
    return;
end
cols = max(1, round(cols));
rows = ceil(N / cols);
row_counts = cols * ones(1, rows);
row_counts(end) = N - cols * (rows - 1);
end


function im = local_to_uint8(im)
if isa(im, 'uint8')
    return;
end
if isa(im, 'uint16')
    im = uint8(double(im) / 257);
elseif isfloat(im)
    if max(im(:)) <= 1
        im = uint8(max(0, min(1, im)) * 255);
    else
        im = uint8(max(0, min(255, im)));
    end
else
    im = uint8(im);
end
end

function labels = local_default_labels(paths)
labels = cell(1, numel(paths));
for k = 1:numel(paths)
    [~, name, ext] = fileparts(paths{k});
    labels{k} = sprintf('%s%s', name, ext);
end
end

function labels = local_unique_labels(labels)
labels = local_cellstr(labels);
for k = 1:numel(labels)
    labels{k} = sprintf('%02d  %s', k, labels{k});
end
end

function c = local_cellstr(x)
if isempty(x)
    c = {};
elseif ischar(x)
    c = {x};
elseif isstring(x)
    c = cellstr(x);
elseif iscell(x)
    c = cell(size(x));
    for k = 1:numel(x)
        c{k} = char(string(x{k}));
    end
else
    c = cellstr(string(x));
end
end

function bg = local_bg(x)
if isnumeric(x)
    if max(x) <= 1
        x = round(255 * x);
    end
    bg = uint8(reshape(x(1:3), 1, 3));
else
    switch lower(char(x))
        case 'black'
            bg = uint8([0 0 0]);
        otherwise
            bg = uint8([255 255 255]);
    end
end
end


function range = local_parse_range(text_value, default_range)
if nargin < 2 || isempty(default_range)
    default_range = [0 1];
end
s = strtrim(char(string(text_value)));
if isempty(s)
    range = default_range;
    return;
end
s = regexprep(s, '^[\[\(]\s*', '');
s = regexprep(s, '\s*[\]\)]$', '');
parts = regexp(s, '[,;\s]+', 'split');
parts = parts(~cellfun(@isempty, parts));
vals = str2double(parts);
vals = vals(isfinite(vals));
if numel(vals) >= 2 && vals(2) > vals(1)
    range = vals(1:2).';
else
    range = default_range;
end
end

function [xl, yl] = local_crop_limits(allx, ally, crop)
allx = allx(isfinite(allx));
ally = ally(isfinite(ally));
if isempty(allx), allx = [0 1]; end
if isempty(ally), ally = [0 1]; end
xmin = min(allx); xmax = max(allx);
ymin = min(ally); ymax = max(ally);
if xmax <= xmin, xmin = xmin - 1; xmax = xmax + 1; end
if ymax <= ymin, ymin = ymin - 1; ymax = ymax + 1; end
dx = xmax - xmin; dy = ymax - ymin;
xl = [xmin - 0.03*dx, xmax + 0.03*dx];
yl = [ymin - 0.06*dy, ymax + 0.06*dy];
if nargin < 3 || isempty(crop)
    return;
end
if isnumeric(crop) && numel(crop) == 4
    xl = crop(1:2);
    yl = crop(3:4);
    return;
end
if isstruct(crop)
    if isfield(crop, 'xlim') && numel(crop.xlim) == 2
        xl = crop.xlim;
    end
    if isfield(crop, 'ylim') && numel(crop.ylim) == 2
        yl = crop.ylim;
    end
    if isfield(crop, 'mode') && strcmpi(char(crop.mode), 'yrange') && isfield(crop, 'y_range') && numel(crop.y_range) == 2
        yl = crop.y_range;
    end
end
end

function slug = local_slug(text_value)
slug = lower(char(string(text_value)));
slug = regexprep(slug, '\$|\\mathrm\{|\}', '');
slug = regexprep(slug, '\\[a-zA-Z]+', '');
slug = regexprep(slug, '[^a-zA-Z0-9]+', '_');
slug = regexprep(slug, '^_+|_+$', '');
if isempty(slug)
    slug = 'item';
end
end

function label = local_clean_label(label)
label = char(string(label));
label = regexprep(label, '\$|\\mathrm\{|\}', '');
label = regexprep(label, '\\[a-zA-Z]+', '');
label = regexprep(label, '[^a-zA-Z0-9_\-\. ]+', '');
label = strtrim(label);
if isempty(label)
    label = 'image';
end
end

function common_limits = local_common_3d_limits(items)
allx = [];
ally = [];
allz = [];

for k = 1:numel(items)
    item = items{k};

    if isfield(item,'x_crop')
        allx = [allx item.x_crop(:).']; %#ok<AGROW>
    elseif isfield(item,'x')
        allx = [allx item.x(:).']; %#ok<AGROW>
    elseif isfield(item,'sphere_x')
        allx = [allx item.sphere_x(:).']; %#ok<AGROW>
    end

    if isfield(item,'y_crop')
        ally = [ally item.y_crop(:).']; %#ok<AGROW>
    elseif isfield(item,'y')
        ally = [ally item.y(:).']; %#ok<AGROW>
    elseif isfield(item,'sphere_y')
        ally = [ally item.sphere_y(:).']; %#ok<AGROW>
    end

    if isfield(item,'z_crop')
        allz = [allz item.z_crop(:).']; %#ok<AGROW>
    elseif isfield(item,'z')
        allz = [allz item.z(:).']; %#ok<AGROW>
    elseif isfield(item,'sphere_z')
        allz = [allz item.sphere_z(:).']; %#ok<AGROW>
    end
end

if isempty(allx), allx = [-1 1]; end
if isempty(ally), ally = [-1 1]; end
if isempty(allz), allz = [-1 1]; end

xmin = min(allx);
xmax = max(allx);
ymin = min(ally);
ymax = max(ally);
zmin = min(allz);
zmax = max(allz);

cx = mean([xmin xmax]);
cy = mean([ymin ymax]);
cz = mean([zmin zmax]);

span = max([xmax-xmin, ymax-ymin, zmax-zmin]);
if span <= 0
    span = 2;
end

half = 0.54 * span;
common_limits = {[cx-half cx+half], [cy-half cy+half], [cz-half cz+half]};
end


function range = local_parse_optional_range(a, b)
a = strtrim(char(string(a)));
b = strtrim(char(string(b)));
if isempty(a) || isempty(b)
    range = [];
    return;
end
lo = str2double(a);
hi = str2double(b);
if isfinite(lo) && isfinite(hi) && hi > lo
    range = [lo hi];
else
    range = [];
end
end
