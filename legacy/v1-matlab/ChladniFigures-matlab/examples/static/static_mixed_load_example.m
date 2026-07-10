%STATIC_MIXED_LOAD_EXAMPLE Superpose points, uniform self-weight, and custom q(X,Y).
clear; clc;
project_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(genpath(project_root));

params = struct();
params.type = 'rect';
params.boundary = 'SSCF';
params.nu = 0.28;
params.xi0 = 0.60;
params.n = 260;
params.kmodes = 120;
params.load_type = 'mixed';
params.q0 = 0.20;
params.sources = [0 0 1 0; 0.55 0.15 -0.5 0.05];
params.load_function = @(X,Y) 0.35*cos(pi*X).*exp(-4*Y.^2);
params.normalize = true;

result = run_static_source_generation(project_root, params);
fprintf('Generated: %s\n', result.files{1});
