%STATIC_POINTS_EXAMPLE Multiple static point/Gaussian sources.
clear; clc;
project_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(genpath(project_root));

params = struct();
params.type = 'rect';
params.boundary = 'SSSS';
params.nu = 0.30;
params.xi0 = 0.55;      % b/a; the code uses a=2 and b=2*xi0
params.n = 260;
params.kmodes = 100;
params.load_type = 'points';
params.sources = [ ...   % [x y P sigma]
    -0.45  0.00  1.00  0.00;   % ideal point load
     0.45  0.20 -0.70  0.04;   % smooth Gaussian patch load
     0.10 -0.35  0.45  0.03];
params.normalize = true;

result = run_static_source_generation(project_root, params);
fprintf('Generated: %s\n', result.files{1});
