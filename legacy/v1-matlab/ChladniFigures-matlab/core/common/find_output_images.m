function files = find_output_images(folder_path)
%FIND_OUTPUT_IMAGES Return all generated PNG files in mode order.

info = dir(fullfile(folder_path, '*.png'));
if isempty(info)
    files = {};
    return;
end

names = {info.name};
keys = zeros(numel(names), 3);
for i = 1:numel(names)
    keys(i, :) = local_mode_sort_key(names{i}, i);
end
[~, ord] = sortrows(keys, [1 2 3]);
info = info(ord);
files = cell(1, numel(info));
for i = 1:numel(info)
    files{i} = fullfile(folder_path, info(i).name);
end
end

function key = local_mode_sort_key(name, fallbackIndex)
tokPair = regexp(name, 'mode(\d+),(\d+)', 'tokens', 'once');
if ~isempty(tokPair)
    key = [0, str2double(tokPair{1}), str2double(tokPair{2})];
    return;
end

tokSingle = regexp(name, 'mode(\d+)', 'tokens', 'once');
if ~isempty(tokSingle)
    key = [1, str2double(tokSingle{1}), 0];
    return;
end

key = [2, fallbackIndex, 0];
end
