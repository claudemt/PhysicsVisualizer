project_root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(project_root, 'app')));
addpath(genpath(fullfile(project_root, 'core')));

params = default_graphite_levitation_params();
params.laser.enabled = true;
params.laser.alpha = 0.12;

out_dir = fullfile(project_root, 'output', 'headless_demo');
if exist(out_dir, 'dir') ~= 7, mkdir(out_dir); end
result = compute_visualization_maps(params);
render_graphite_levitation_result('visualization', result, out_dir, 'Prefix', 'demo');

params.scan.parameter = 'graphite.radius';
params.scan.valuesDisplay = 4:1:12;
params.scan.values = params.scan.valuesDisplay * 1e-3;
scanResult = compute_parameter_scan(params);
render_graphite_levitation_result('scan', scanResult, out_dir, 'Prefix', 'scan');
fprintf('Wrote demo images to %s\n', out_dir);
