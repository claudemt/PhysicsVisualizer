function export_info = export_preview_bundle(project_root, module_key, axes_handles, axes_names, layout_shape, param_lines, notes_lines, status_lines, dlg)
%EXPORT_PREVIEW_BUNDLE Export current preview axes to a timestamped output bundle.

if nargin < 9
    dlg = [];
end

param_lines = normalize_lines(param_lines);
notes_lines = normalize_lines(notes_lines);
status_lines = normalize_lines(status_lines);

output_root = fullfile(project_root, 'output');
if ~exist(output_root, 'dir')
    mkdir(output_root);
end

update_progress_dialog(dlg, 0.08, 'creating output folder');
timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
bundle_dir = fullfile(output_root, timestamp);
suffix = 1;
while exist(bundle_dir, 'dir')
    bundle_dir = fullfile(output_root, sprintf('%s_%02d', timestamp, suffix));
    suffix = suffix + 1;
end
mkdir(bundle_dir);

if isrow(axes_handles)
    axes_handles = axes_handles(:);
end
if isrow(axes_names)
    axes_names = axes_names(:);
end

image_paths = cell(numel(axes_handles), 1);
trimmed_images = cell(numel(axes_handles), 1);
for k = 1:numel(axes_handles)
    update_progress_dialog(dlg, 0.10 + 0.45 * k / max(numel(axes_handles), 1), ['exporting ' axes_names{k}]);
    image_paths{k} = fullfile(bundle_dir, sprintf('%s_%02d_%s.png', module_key, k, axes_names{k}));
    drawnow;
    exportgraphics(axes_handles(k), image_paths{k}, 'Resolution', 360, 'BackgroundColor', 'white');
    trimmed_images{k} = trim_white_borders(imread(image_paths{k}));
    imwrite(trimmed_images{k}, image_paths{k});
end

update_progress_dialog(dlg, 0.62, 'building composite preview');
composite_image = compose_preview_image(trimmed_images, layout_shape);
composite_path = fullfile(bundle_dir, sprintf('%s_preview_composite.png', module_key));
imwrite(composite_image, composite_path);

update_progress_dialog(dlg, 0.82, 'writing parameter report');
report_path = fullfile(bundle_dir, sprintf('%s_params.txt', module_key));
write_text_report(report_path, module_key, param_lines, status_lines, notes_lines);

export_info = struct();
export_info.bundle_dir = bundle_dir;
export_info.composite_path = composite_path;
export_info.report_path = report_path;
update_progress_dialog(dlg, 1.00, 'export complete');
end

function canvas = compose_preview_image(image_list, layout_shape)
rows = layout_shape(1);
cols = layout_shape(2);
pad = 12;
background_value = uint8(255);

max_h = 1;
max_w = 1;
for k = 1:numel(image_list)
    img = ensure_rgb_uint8(image_list{k});
    image_list{k} = img;
    max_h = max(max_h, size(img, 1));
    max_w = max(max_w, size(img, 2));
end

canvas_h = rows * max_h + (rows + 1) * pad;
canvas_w = cols * max_w + (cols + 1) * pad;
canvas = background_value * ones(canvas_h, canvas_w, 3, 'uint8');

for k = 1:min(numel(image_list), rows * cols)
    r = floor((k - 1) / cols) + 1;
    c = mod(k - 1, cols) + 1;
    img = image_list{k};
    h = size(img, 1);
    w = size(img, 2);
    y0 = pad + (r - 1) * (max_h + pad) + floor((max_h - h) / 2) + 1;
    x0 = pad + (c - 1) * (max_w + pad) + floor((max_w - w) / 2) + 1;
    canvas(y0:y0 + h - 1, x0:x0 + w - 1, :) = img;
end
end

function rgb = ensure_rgb_uint8(img)
if isa(img, 'double')
    img = uint8(max(0, min(255, round(255 * img))));
elseif isa(img, 'single')
    img = uint8(max(0, min(255, round(255 * double(img)))));
end

if ndims(img) == 2
    rgb = repmat(img, 1, 1, 3);
else
    rgb = img;
end
end

function write_text_report(report_path, module_key, param_lines, status_lines, notes_lines)
fid = fopen(report_path, 'w');
if fid < 0
    error('Could not open report file for writing: %s', report_path);
end
cleanup_obj = onCleanup(@() fclose(fid));

fprintf(fid, 'module: %s\n', module_key);
fprintf(fid, 'timestamp: %s\n\n', datestr(now, 31));

fprintf(fid, '[parameters]\n');
for k = 1:numel(param_lines)
    fprintf(fid, '%s\n', param_lines{k});
end

fprintf(fid, '\n[status]\n');
for k = 1:numel(status_lines)
    fprintf(fid, '%s\n', status_lines{k});
end

fprintf(fid, '\n[notes]\n');
for k = 1:numel(notes_lines)
    fprintf(fid, '%s\n', notes_lines{k});
end

clear cleanup_obj;
end

function lines = normalize_lines(lines)
if isempty(lines)
    lines = {};
elseif isstring(lines)
    lines = cellstr(lines);
elseif ischar(lines)
    lines = {lines};
end
end
