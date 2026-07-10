%STATIC_CUSTOM_LOAD_EXAMPLE General distributed transverse load q(X,Y).
clear; clc;
project_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(genpath(project_root));

params = struct();
params.type = 'circ';
params.boundary = 'C';
params.nu = 0.30;
params.n = 240;
params.mmax = 55;
params.distribution_samples = 28;
params.load_type = 'custom';

% X,Y are Cartesian sample arrays in the displayed plate material.
% For annuli, the central hole is not sampled; valid point sources must satisfy xi0 < hypot(x,y) < 1.
% The function must return either a scalar or an array of the same size.
params.load_function = @(X,Y) exp(-24*((X-0.28).^2 + (Y+0.10).^2)) ...
                         - 0.55*exp(-35*((X+0.32).^2 + (Y-0.20).^2));
params.normalize = true;

result = run_static_source_generation(project_root, params);
fprintf('Generated: %s\n', result.files{1});
