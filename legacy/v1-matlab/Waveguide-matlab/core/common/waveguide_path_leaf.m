function name = waveguide_path_leaf(folder_path)
%WAVEGUIDE_PATH_LEAF Return a folder leaf without losing dotted numeric tags.

clean_path = char(string(folder_path));
while ~isempty(clean_path) && (clean_path(end) == filesep || clean_path(end) == '/' || clean_path(end) == char(92))
    clean_path(end) = [];
end
[~, stem, suffix] = fileparts(clean_path);
name = [stem suffix];
if isempty(name)
    name = 'waveguide_run';
end
end
