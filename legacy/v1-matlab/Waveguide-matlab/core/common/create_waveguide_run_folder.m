function folder_path = create_waveguide_run_folder(project_root, family, tag)
%CREATE_WAVEGUIDE_RUN_FOLDER Create a stable cache folder for one GUI selection.

if nargin < 3 || isempty(tag)
    tag = 'run';
end

cache_root = fullfile(project_root, '.cache', 'waveguide', sanitize_waveguide_name(family));
if ~exist(cache_root, 'dir')
    mkdir(cache_root);
end

folder_name = sanitize_waveguide_name(tag);
folder_path = fullfile(cache_root, folder_name);
if ~exist(folder_path, 'dir')
    mkdir(folder_path);
else
    info = dir(fullfile(folder_path, '*.png'));
    for k = 1:numel(info)
        delete(fullfile(folder_path, info(k).name));
    end
end
end
