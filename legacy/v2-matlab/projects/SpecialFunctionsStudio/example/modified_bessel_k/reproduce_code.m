export_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(fileparts(export_dir));
addpath(genpath(project_root));

% Reproduce run 01
params = struct();
params.family = 'bessel';
params.variant = 'k';
params.param_text = '(0:5)';
params.arg_matrix = [0;1;2;3;4;5];
params.xmin = 0;
params.xmax = 5;
params.crop.mode = 'yrange';
params.crop.y_range = [0 1];
params.layout_text = 'auto';
params.render_options.legend_location = 'northeast';
out_01 = parse_special_functions_params('render_from_params', params);
run_files_01 = out_01.files;

copyfile(run_files_01{1}, fullfile(export_dir, '01_modified_bessel_function_k_n_x.png'), 'f');
