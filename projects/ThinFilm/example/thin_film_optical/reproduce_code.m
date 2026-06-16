export_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(fileparts(export_dir));
addpath(genpath(project_root));

params = struct();
params.omega = 1;
params.theta_a = 0.68;
params.a.eps = 1;
params.a.mu = 1;
params.g.eps = 2.25;
params.g.mu = 1;
params.N = 3;
params.layers_table = [2.25 1 1.111;1.12 1.3 2;1.5 1 3.1];

params.layers = repmat(struct('eps', 0, 'mu', 0, 'h', 0), params.N, 1);
for i = 1:params.N
    params.layers(i).eps = params.layers_table(i, 1);
    params.layers(i).mu  = params.layers_table(i, 2);
    params.layers(i).h   = params.layers_table(i, 3);
end
params = rmfield(params, 'layers_table');

out = thin_film_model('report_optical', params);
disp(out.text);
