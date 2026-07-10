%STATIC_UNIFORM_SELF_WEIGHT_EXAMPLE Uniform self-weight / constant load.
clear; clc;
project_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(genpath(project_root));

params = struct();
params.type = 'annulus';
params.boundary = 'CC';       % outer-inner boundary code
params.nu = 0.30;
params.xi0 = 0.35;
params.n = 240;
params.mmax = 60;
params.distribution_samples = 26;
params.load_type = 'uniform';
params.q0 = 1.0;              % use rho*h*g here in dimensional calculations
params.normalize = true;

result = run_static_source_generation(project_root, params);
fprintf('Generated: %s\n', result.files{1});
