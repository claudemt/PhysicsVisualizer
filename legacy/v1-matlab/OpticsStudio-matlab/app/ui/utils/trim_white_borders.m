function trimmed = trim_white_borders(image_data)
%TRIM_WHITE_BORDERS Trim near-white borders from exported images.

if ndims(image_data) == 2
    mask = image_data < 250;
else
    mask = any(image_data < 250, 3);
end

rows = find(any(mask, 2));
cols = find(any(mask, 1));

if isempty(rows) || isempty(cols)
    trimmed = image_data;
    return;
end

trimmed = image_data(rows(1):rows(end), cols(1):cols(end), :);
end
