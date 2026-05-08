function main
project_root = fileparts(mfilename('fullpath'));
repo_root = fileparts(fileparts(project_root));
addpath(fullfile(repo_root, 'utils'));
addpath(genpath(fullfile(project_root, 'app')));
addpath(genpath(fullfile(project_root, 'core')));
addpath(genpath(fullfile(project_root, 'docs')));
tab_builders = {@create_crystal_boundary_tab};
launch_gui_studio(project_root, tab_builders, 'StudioName', 'Crystal Boundary Optics Studio');
end
