function export_folder = export_generated_waveguide_files(project_root, generated_files, base_folder)
%EXPORT_GENERATED_WAVEGUIDE_FILES Copy cached PNG output into output/<base>/.
%
% The export folder is intentionally flat:
%   output/rectangular/
%   output/circular/
%   output/planar/
%   output/cylindrical/
%
% No extra run-name subfolder is created.

if isempty(generated_files)
    error('No generated PNG files are available to export.');
end

if nargin < 3 || isempty(base_folder)
    base_folder = 'waveguide';
end

export_folder = fullfile(project_root, 'output', sanitize_waveguide_name(base_folder));
if ~exist(export_folder, 'dir')
    mkdir(export_folder);
else
    info = dir(fullfile(export_folder, '*.png'));
    for k = 1:numel(info)
        delete(fullfile(export_folder, info(k).name));
    end
end

for k = 1:numel(generated_files)
    src = generated_files{k};
    [~, name, ext] = fileparts(src);
    copyfile(src, fullfile(export_folder, [name ext]));
end
end
