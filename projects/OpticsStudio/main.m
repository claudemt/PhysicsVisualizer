function main
project_root = fileparts(mfilename('fullpath'));
repo_root = fileparts(fileparts(project_root));
addpath(fullfile(repo_root, 'utils'));
addpath(genpath(fullfile(project_root, 'app')));
addpath(genpath(fullfile(project_root, 'core')));
addpath(genpath(fullfile(project_root, 'docs')));
	tab_builders = {@create_fourier_studio_tab, @create_imaging_tab, ...
	                 @create_interference_tab, @create_ray_optics_tab, ...
	                 @create_tomography_tab, @create_wave_optics_tab};
launch_gui_studio(project_root, tab_builders, 'StudioName', 'Optics Studio');
end
