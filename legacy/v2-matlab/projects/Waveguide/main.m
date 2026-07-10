function main
project_root = fileparts(mfilename('fullpath'));
repo_root = fileparts(fileparts(project_root));
addpath(fullfile(repo_root, 'utils'));
addpath(genpath(fullfile(project_root, 'app')));
addpath(genpath(fullfile(project_root, 'core')));
addpath(genpath(fullfile(project_root, 'docs')));
tab_builders = {@create_metal_guides_tab, @create_planar_dielectric_tab, @create_cylindrical_dielectric_tab};
launch_gui_studio(project_root, tab_builders, 'StudioName', 'Waveguide Studio');
end
