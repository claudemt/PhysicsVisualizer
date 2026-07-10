export_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(fileparts(export_dir));
addpath(genpath(project_root));

params = struct();
params.omega = 1;
params.kx = 0.1;
params.phii = 1;
params.psii = 1;
params.a.lambda = 1.3;
params.a.mu = 1;
params.a.eta = 1;
params.g.lambda = 1.3;
params.g.mu = 5.2;
params.g.eta = 1.9;
params.N = 3;
params.layers_table = [4 1.5 4.4 9.8;1 1.1 1.5 6;2.1 3.1 5.4 1];

params.layers = repmat(struct('lambda', 0, 'mu', 0, 'eta', 0, 'h', 0), params.N, 1);
for i = 1:params.N
    params.layers(i).lambda = params.layers_table(i, 1);
    params.layers(i).mu     = params.layers_table(i, 2);
    params.layers(i).eta    = params.layers_table(i, 3);
    params.layers(i).h      = params.layers_table(i, 4);
end
params = rmfield(params, 'layers_table');

out = thin_film_model('report', params);
disp(out.text);
