function file_path = export_waveguide_image_montage_png(folder_path, file_name, image_files, layout_spec)
%EXPORT_WAVEGUIDE_IMAGE_MONTAGE_PNG Build a compact high-resolution PNG sheet.
%
% This implementation intentionally avoids MATLAB figure/subplot/tiledlayout
% objects. It reads the already-generated PNGs, trims white margins, preserves
% the original aspect ratio of each panel, and writes the combined sheet with
% IMWRITE. Therefore it cannot pop up one figure window per panel.

if isempty(image_files)
    error('At least one input image is required for montage export.');
end

if nargin < 4 || isempty(layout_spec)
    row_counts = parse_montage_layout('auto', numel(image_files));
elseif isnumeric(layout_spec)
    row_counts = layout_spec(:).';
else
    row_counts = parse_montage_layout(layout_spec, numel(image_files));
end

if sum(row_counts) ~= numel(image_files)
    error('The montage layout does not match the number of image files.');
end

if ~exist(folder_path, 'dir')
    mkdir(folder_path);
end
file_path = fullfile(folder_path, sanitize_waveguide_name(file_name));

% Compact parameters. The rows are dense; images are not stretched.
target_panel_h = 310;   % px after white-margin trimming
outer_margin = 16;      % px
col_gap = 12;           % px
row_gap = 12;           % px
white = uint8(255);

panels = cell(numel(image_files), 1);
widths = zeros(numel(image_files), 1);
heights = zeros(numel(image_files), 1);

for k = 1:numel(image_files)
    img = imread(image_files{k});
    img = normalize_rgb_uint8(img);
    img = trim_white_border(img);

    [h, w, ~] = size(img);
    scale = target_panel_h / max(h, 1);
    new_h = max(1, round(h * scale));
    new_w = max(1, round(w * scale));
    img = resize_nearest_rgb(img, new_h, new_w);

    panels{k} = img;
    [heights(k), widths(k), ~] = size(img);
end

row_widths = zeros(numel(row_counts), 1);
row_heights = zeros(numel(row_counts), 1);
idx = 1;
for r = 1:numel(row_counts)
    n = row_counts(r);
    row_widths(r) = sum(widths(idx:idx+n-1)) + max(0, n-1) * col_gap;
    row_heights(r) = max(heights(idx:idx+n-1));
    idx = idx + n;
end

canvas_w = outer_margin * 2 + max(row_widths);
canvas_h = outer_margin * 2 + sum(row_heights) + max(0, numel(row_counts)-1) * row_gap;
canvas = repmat(white, canvas_h, canvas_w, 3);

idx = 1;
y = outer_margin;
for r = 1:numel(row_counts)
    n = row_counts(r);
    x = outer_margin + floor((max(row_widths) - row_widths(r)) / 2);
    for c = 1:n
        img = panels{idx};
        [h, w, ~] = size(img);
        yy = y + floor((row_heights(r) - h) / 2);
        canvas(yy:yy+h-1, x:x+w-1, :) = img;
        x = x + w + col_gap;
        idx = idx + 1;
    end
    y = y + row_heights(r) + row_gap;
end

imwrite(canvas, file_path, 'png');
end

function img = normalize_rgb_uint8(img)
%NORMALIZE_RGB_UINT8 Return an RGB uint8 image.

if isa(img, 'uint16')
    img = uint8(double(img) / 65535 * 255);
elseif isa(img, 'double') || isa(img, 'single')
    if max(img(:)) <= 1
        img = uint8(img * 255);
    else
        img = uint8(img);
    end
elseif ~isa(img, 'uint8')
    img = uint8(img);
end

if ndims(img) == 2
    img = repmat(img, 1, 1, 3);
elseif size(img, 3) == 4
    alpha = double(img(:, :, 4)) / 255;
    rgb = double(img(:, :, 1:3));
    bg = 255 * ones(size(rgb));
    img = uint8(rgb .* alpha + bg .* (1 - alpha));
elseif size(img, 3) > 3
    img = img(:, :, 1:3);
end
end

function out = trim_white_border(img)
%TRIM_WHITE_BORDER Remove outer white/near-white margins while preserving content.

rgb = double(img(:, :, 1:3));
is_content = any(rgb < 248, 3);

% Keep a little breathing room around axis labels/titles/colorbars.
pad = 5;

rows = find(any(is_content, 2));
cols = find(any(is_content, 1));

if isempty(rows) || isempty(cols)
    out = img;
    return;
end

r1 = max(1, rows(1) - pad);
r2 = min(size(img, 1), rows(end) + pad);
c1 = max(1, cols(1) - pad);
c2 = min(size(img, 2), cols(end) + pad);

out = img(r1:r2, c1:c2, :);
end

function out = resize_nearest_rgb(img, new_h, new_w)
%RESIZE_NEAREST_RGB Resize without Image Processing Toolbox dependency.

[h, w, ch] = size(img);
row_idx = max(1, min(h, round(linspace(1, h, new_h))));
col_idx = max(1, min(w, round(linspace(1, w, new_w))));
out = img(row_idx, col_idx, 1:ch);
end
