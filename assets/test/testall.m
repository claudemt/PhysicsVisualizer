function results = testall(varargin)
%TESTALL Run broad non-GUI tests for every PhysicsVisualizer subproject.
%
% Usage:
%   testall                 % run the full test suite
%   testall('quick')        % skip the heaviest full-coverage render sweep
%   testall('list')         % list test groups only
%   testall('project','OpticsStudio')  % run matching project/group names
%
% Output:
%   A timestamped folder is created under assets/test/output/.  It contains:
%     - test_report.txt          full normal output plus summary
%     - summary.csv              one row per test group
%     - normal_output/*.txt      captured MATLAB stdout for every group
%     - generated PNG/TXT outputs from the tested modules
%
% Design notes:
%   - Each project path is added only while its tests are running, preventing
%     interface/path collisions between projects that share function names.
%   - GUI launchers are not opened. Core math, parsers, renderers, exporters,
%     and project-level generation facades are tested directly.
%   - Every test group is protected by try/catch so a failed subproject does
%     not stop the rest of the suite.

cfg = local_parse_options(varargin{:});
repo_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
if isempty(repo_root), repo_root = pwd; end
utils_dir = fullfile(repo_root, 'utils');
if exist(utils_dir, 'dir') == 7
    addpath(utils_dir);
end

stamp = datestr(now, 'yyyymmdd_HHMMSS');
test_root = fullfile(repo_root, 'assets', 'test', 'output', ['testall_' stamp]);
normal_root = fullfile(test_root, 'normal_output');

cases = local_build_cases(repo_root, test_root);
if cfg.quick
    cases = cases([cases.quick]);
end
if ~isempty(cfg.project)
    keep = false(size(cases));
    token = lower(cfg.project);
    for i = 1:numel(cases)
        hay = lower([cases(i).project ' ' cases(i).name ' ' cases(i).description]);
        keep(i) = contains(hay, token);
    end
    cases = cases(keep);
end

if cfg.list_only
    fprintf('=== PhysicsVisualizer test groups ===\n');
    for i = 1:numel(cases)
        q = 'full';
        if cases(i).quick, q = 'quick'; end
        fprintf('%2d. %-24s | %-38s | %s\n', i, cases(i).project, cases(i).name, q);
        fprintf('    %s\n', cases(i).description);
    end
    results = cases;
    return;
end

if exist(test_root, 'dir') ~= 7, mkdir(test_root); end
if exist(normal_root, 'dir') ~= 7, mkdir(normal_root); end

old_fig_visibility = '';
try
    old_fig_visibility = get(groot, 'DefaultFigureVisible');
    set(groot, 'DefaultFigureVisible', 'off');
catch
end
cleanup_obj = onCleanup(@() local_restore_figures(old_fig_visibility)); %#ok<NASGU>

report_lines = {};
report_lines{end+1} = '=================================================================';
report_lines{end+1} = 'PhysicsVisualizer TESTALL';
report_lines{end+1} = '=================================================================';
report_lines{end+1} = sprintf('Started    : %s', datestr(now));
report_lines{end+1} = sprintf('Repository : %s', repo_root);
report_lines{end+1} = sprintf('Output     : %s', test_root);
report_lines{end+1} = sprintf('Mode       : %s', local_ifelse(cfg.quick, 'quick', 'full'));
if ~isempty(cfg.project)
    report_lines{end+1} = sprintf('Filter     : %s', cfg.project);
end
report_lines{end+1} = '=================================================================';
report_lines{end+1} = '';

fprintf('\n=== PhysicsVisualizer TESTALL ===\n');
fprintf('Output folder: %s\n', test_root);
fprintf('Test groups  : %d\n\n', numel(cases));

results = repmat(local_empty_result(), 0, 1);
for i = 1:numel(cases)
    tc = cases(i);
    fprintf('[%02d/%02d] %-24s :: %s\n', i, numel(cases), tc.project, tc.name);
    r = local_run_case(tc, i, normal_root);
    results(end+1,1) = r; %#ok<AGROW>

    report_lines{end+1} = sprintf('[%s] %s :: %s', r.status, r.project, r.name); %#ok<AGROW>
    report_lines{end+1} = sprintf('  Duration : %.3f sec', r.duration_sec); %#ok<AGROW>
    report_lines{end+1} = sprintf('  Files    : %d', numel(r.files)); %#ok<AGROW>
    if ~isempty(r.message)
        report_lines{end+1} = sprintf('  Message  : %s', r.message); %#ok<AGROW>
    end
    if ~isempty(r.files)
        report_lines{end+1} = '  Output files:'; %#ok<AGROW>
        for k = 1:min(20, numel(r.files))
            report_lines{end+1} = sprintf('    - %s', r.files{k}); %#ok<AGROW>
        end
        if numel(r.files) > 20
            report_lines{end+1} = sprintf('    ... %d more', numel(r.files)-20); %#ok<AGROW>
        end
    end
    report_lines{end+1} = sprintf('  Normal output: %s', r.normal_output_file); %#ok<AGROW>
    report_lines{end+1} = ''; %#ok<AGROW>

    if r.ok
        fprintf('    PASS (%.2fs, %d file(s))\n', r.duration_sec, numel(r.files));
    else
        fprintf('    FAIL (%.2fs): %s\n', r.duration_sec, r.message);
    end
end

n_pass = sum([results.ok]);
n_fail = numel(results) - n_pass;
report_lines{end+1} = '=================================================================';
report_lines{end+1} = sprintf('SUMMARY: %d passed, %d failed, %d total', n_pass, n_fail, numel(results));
report_lines{end+1} = sprintf('Finished: %s', datestr(now));
report_lines{end+1} = '=================================================================';
report_lines{end+1} = '';
report_lines{end+1} = 'DETAILED NORMAL OUTPUT';
report_lines{end+1} = '=================================================================';
for i = 1:numel(results)
    report_lines{end+1} = sprintf('--- %s :: %s ---', results(i).project, results(i).name); %#ok<AGROW>
    txt = local_read_text(results(i).normal_output_file);
    report_lines = [report_lines(:); local_split_lines(txt)]; %#ok<AGROW>
    report_lines{end+1} = ''; %#ok<AGROW>
end

report_path = fullfile(test_root, 'test_report.txt');
local_write_lines(report_path, report_lines);
local_write_summary_csv(fullfile(test_root, 'summary.csv'), results);

fprintf('\n=== TESTALL COMPLETE ===\n');
fprintf('Passed : %d\n', n_pass);
fprintf('Failed : %d\n', n_fail);
fprintf('Report : %s\n', report_path);

if nargout == 0
    clear results;
end
end

% =====================================================================
% Case registry
% =====================================================================
function cases = local_build_cases(repo_root, test_root)
cases = repmat(local_empty_case(), 0, 1);
cases(end+1,1) = local_case('SharedUtils', 'parsers/render/export', true, ...
    'Shared parser utilities, render_result, image_output, and params_output.', ...
    @() test_shared_utils(repo_root, test_root));
cases(end+1,1) = local_case('ChladniFigures', 'modes/static/parsers', true, ...
    'Rectangular, circular, annular modes; static loads; project parsers.', ...
    @() test_chladni_figures(repo_root, test_root));
cases(end+1,1) = local_case('GraphiteLevitation', 'magnetic maps/render', true, ...
    'Defaults, validators, magnet/graphite helpers, visualization maps, renderer.', ...
    @() test_graphite_levitation(repo_root, test_root));
cases(end+1,1) = local_case('CrystalOpticsBoundary', 'single/sweep reports', true, ...
    'Single polarization and polarization-sweep anisotropic boundary solves.', ...
    @() test_crystal_optics_boundary(repo_root, test_root));
cases(end+1,1) = local_case('MieScattering', 'sphere/cylinder fields', true, ...
    'Sphere and cylinder scattering field bundles plus parser helpers.', ...
    @() test_mie_scattering(repo_root, test_root));
cases(end+1,1) = local_case('MovingChargeFields', 'formula/generator', true, ...
    'Lienard-Wiechert field formula plus image generator for multiple field types.', ...
    @() test_moving_charge_fields(repo_root, test_root));
cases(end+1,1) = local_case('SpecialFunctionsStudio', 'all catalog variants', true, ...
    'Every special-function catalog variant with representative parameters and rendering.', ...
    @() test_special_functions_studio(repo_root, test_root));
cases(end+1,1) = local_case('Waveguide', 'metal/dielectric modes', true, ...
    'PEC rectangular/circular guides, slab/fiber dielectric calculations and exports.', ...
    @() test_waveguide(repo_root, test_root));
cases(end+1,1) = local_case('RigidBodyRotation', 'free/fixed/compare', true, ...
    'Free rigid body, heavy top, and multi-initial-condition comparison.', ...
    @() test_rigid_body_rotation(repo_root, test_root));
cases(end+1,1) = local_case('ThinFilm', 'elastic/optical reports', true, ...
    'Elastic and optical transfer-matrix defaults, solves, and reports.', ...
    @() test_thin_film(repo_root, test_root));
cases(end+1,1) = local_case('OpticsStudio', 'all computational modules', true, ...
    'Fourier, imaging, interference, ray optics, tomography, wave propagation, thin film.', ...
    @() test_optics_studio(repo_root, test_root));
cases(end+1,1) = local_case('CreativePlotStudio', 'all render scripts', false, ...
    'Full render.m sweep across art, fractals, and nonlinear script families.', ...
    @() test_creative_plot_studio(repo_root, test_root));
end

function c = local_empty_case()
c = struct('project', '', 'name', '', 'quick', true, 'description', '', 'fn', []);
end

function c = local_case(project, name, quick, description, fn)
c = struct('project', project, 'name', name, 'quick', quick, 'description', description, 'fn', fn);
end

function r = local_empty_result()
r = struct('project', '', 'name', '', 'ok', false, 'status', 'FAIL', ...
    'duration_sec', 0, 'message', '', 'files', {{}}, 'normal_output_file', '');
end

function r = local_run_case(tc, index, normal_root)
r = local_empty_result();
r.project = tc.project;
r.name = tc.name;
slug = sprintf('%02d_%s_%s.txt', index, local_slug(tc.project), local_slug(tc.name));
r.normal_output_file = fullfile(normal_root, slug);

tic;
try
    out = [];
    normal_output = evalc('out = tc.fn();');
    r.ok = true;
    r.status = 'PASS';
    r.message = 'ok';
    r.files = local_collect_files(out);
catch ME
    normal_output = '';
    try
        normal_output = evalc('disp(getReport(ME, ''extended'', ''hyperlinks'', ''off''));');
    catch
        normal_output = ME.message;
        for s = 1:numel(ME.stack)
            normal_output = sprintf('%s\n  at %s line %d', normal_output, ME.stack(s).name, ME.stack(s).line); %#ok<AGROW>
        end
    end
    r.ok = false;
    r.status = 'FAIL';
    r.message = ME.message;
    r.files = {};
end
r.duration_sec = toc;
local_write_text(r.normal_output_file, normal_output);
end

% =====================================================================
% 0. Shared utilities
% =====================================================================
function info = test_shared_utils(repo_root, test_root)
out_dir = local_mkdir(fullfile(test_root, 'SharedUtils'));
addpath(fullfile(repo_root, 'utils'));
fprintf('Testing shared utils in %s\n', out_dir);

v = create_control_panel('parse_range', '(0, 1)');
local_assert(numel(v) == 2 && abs(v(2)-1) < 1e-12, 'parse_range failed');
M = create_control_panel('parse_tuples', '(1,2); (3,4)', 2, '(0,0)');
local_assert(isequal(size(M), [2 2]), 'parse_tuples failed');
vec = create_control_panel('parse_vector', '[1 2 3]');
local_assert(numel(vec) == 3, 'parse_vector failed');
mat = create_control_panel('parse_matrix', '[1 2; 3 4]');
local_assert(isequal(size(mat), [2 2]), 'parse_matrix failed');

params = struct('alpha', 1, 'beta', [2 3], 'nested', struct('name', 'demo'));
lines = params_output('lines', params);
local_assert(~isempty(lines), 'params_output lines failed');
param_path = params_output('write_with_reproduce', out_dir, params, 'disp(params);');
local_assert_file(param_path);

x = linspace(-1, 1, 80);
y = linspace(-1, 1, 70);
[X, Y] = meshgrid(x, y);
Z = sin(3*X).*cos(4*Y);
heat = render_result('heatmap', x, y, Z, 'Title', 'shared heatmap', 'ColorbarLabel', 'Z');
curves = {struct('x', x, 'y', sin(2*pi*x), 'label', 'sin'), struct('x', x, 'y', cos(2*pi*x), 'label', 'cos')};
curve = render_result('curve', curves, 'Title', 'shared curve');
bundle = render_result('bundle', {heat, curve});
files = render_result('render', bundle, out_dir, 'Prefix', 'shared_utils', 'DPI', 140);
local_assert_files(files);

composite = fullfile(out_dir, 'shared_composite.png');
image_output('compose_grid', files, composite, 'Layout', 'auto');
local_assert_file(composite);

smart_crop_files = local_test_smart_crop(out_dir);

info = local_info([local_cellstr(files), smart_crop_files, {param_path, composite}]);
end

function files = local_test_smart_crop(out_dir)
img = uint8(255 * ones(600, 800, 3));
img(55:58, 260:540, :) = 245;     % pale title-like line
img(160:420, 120:680, :) = 80;    % main plot/content block
img(450:452, 250:550, :) = 242;   % pale label-like line
img(130:430, 118:120, :) = 120;   % thin axis-like line

src = fullfile(out_dir, 'smart_crop_source.png');
imwrite(img, src);
image_output('auto_crop', src);
info = imfinfo(src);
local_assert(info.Height > 380, 'smart crop removed pale top/bottom content');
local_assert(info.Height < 560 && info.Width < 760, 'smart crop did not trim outer whitespace');

img2 = uint8(255 * ones(500, 500, 3));
img2(85:88, 150:350, :) = 240;
img2(150:360, 120:380, 1) = 40;
img2(150:360, 120:380, 2) = 115;
img2(150:360, 120:380, 3) = 180;
src2 = fullfile(out_dir, 'smart_crop_source_2.png');
imwrite(img2, src2);
image_output('auto_crop', src2);

comp = fullfile(out_dir, 'smart_crop_composite.png');
image_output('compose_grid', {src, src2}, comp, 'Layout', 'auto', 'Padding', 12);
local_assert_file(comp);
files = {src, src2, comp};
end

% =====================================================================
% 1. ChladniFigures
% =====================================================================
function info = test_chladni_figures(repo_root, test_root)
project_root = fullfile(repo_root, 'projects', 'ChladniFigures');
out_dir = local_mkdir(fullfile(test_root, 'ChladniFigures'));
guard = local_add_project_paths(project_root); %#ok<NASGU>

fprintf('Chladni boundary parser checks...\n');
local_assert(strcmp(parse_chladni_params('normalize_boundary', 'rect', 'cfsf'), 'CFSF'), 'rect boundary normalize failed');
local_assert(strcmp(parse_chladni_params('normalize_boundary', 'circ', 'free'), 'F'), 'circ boundary normalize failed');
S = parse_chladni_params('read_source_matrix', '[0 0 1 0; 0.3 0.2 -0.5 0.03]');
local_assert(size(S,2) == 4 && size(S,1) == 2, 'source parser failed');
local_assert(~isempty(rect_boundary_options()), 'rect_boundary_options empty');
local_assert(~isempty(circ_boundary_options('annulus')), 'circ_boundary_options empty');
local_assert(has_zero_level([-1 0.2; 0.3 1]), 'has_zero_level failed');
meta = rect_boundary_meta('SSSS');
local_assert(isstruct(meta), 'rect_boundary_meta failed');

files = {};
mode_cases = { ...
    local_chladni_mode_params('rect', 'SSSS', 0.45), ...
    local_chladni_mode_params('rect', 'FFFF', 0.45), ...
    local_chladni_mode_params('rect', 'CFSF', 0.45), ...
    local_chladni_mode_params('circ', 'C', 0), ...
    local_chladni_mode_params('circ', 'F', 0), ...
    local_chladni_mode_params('annulus', 'CF', 0.35)};
for k = 1:numel(mode_cases)
    p = mode_cases{k};
    fprintf('  mode %s %s\n', p.type, p.boundary);
    r = compute_chladni_modes(p);
    local_assert(isstruct(r) && isfield(r, 'items'), 'compute_chladni_modes returned invalid result');
    files = [files, local_cellstr(render_result('render', r, out_dir, 'Prefix', sprintf('mode_%02d_%s_%s', k, p.type, p.boundary), 'DPI', 120))]; %#ok<AGROW>
end

static_cases = { ...
    local_chladni_static_params('rect', 'SSSS', 0.45, 'points'), ...
    local_chladni_static_params('rect', 'CFSF', 0.45, 'custom'), ...
    local_chladni_static_params('circ', 'C', 0, 'uniform'), ...
    local_chladni_static_params('annulus', 'CC', 0.35, 'points'), ...
    local_chladni_static_params('annulus', 'FS', 0.45, 'mixed')};
for k = 1:numel(static_cases)
    p = static_cases{k};
    fprintf('  static %s %s %s\n', p.type, p.boundary, p.load_type);
    r = compute_static_sources(p);
    local_assert(isstruct(r) && isfield(r, 'items'), 'compute_static_sources returned invalid result');
    files = [files, local_cellstr(render_result('render', r, out_dir, 'Prefix', sprintf('static_%02d_%s_%s', k, p.type, p.boundary), 'DPI', 120))]; %#ok<AGROW>
end
local_assert_files(files);
info = local_info(files);
end

function p = local_chladni_mode_params(type, boundary, xi0)
p = struct('type', type, 'boundary', boundary, 'nu', 0.225, 'k', 3, 'n', 240, ...
    'normalize', true, 'xi0', xi0, 'a', 2.0, 'b', max(0.5, 2.0*xi0));
if strcmp(type, 'circ'), p.xi0 = 0; end
end

function p = local_chladni_static_params(type, boundary, xi0, load_type)
p = struct('type', type, 'boundary', boundary, 'nu', 0.30, 'n', 300, 'D', 1.0, ...
    'normalize', true, 'xi0', xi0, 'kmodes', 28, 'mmax', 24, 'q0', 1.0, ...
    'draw_zero_contour', false, 'distribution_samples', 12, 'load_type', load_type, ...
    'a', 2.0, 'b', max(0.7, 2.0*xi0));
switch type
    case 'rect'
        p.sources = [0 0 1 0; 0.45 0.15 -0.5 0.03];
        p.load_function = @(X,Y) cos(pi*X).*cos(pi*Y);
    case 'annulus'
        p.sources = [0.5*(1+xi0) 0 1 0; 0 0.5*(1+xi0) -0.4 0.02];
        p.load_function = @(X,Y) 1 + 0.*X + 0.*Y;
    otherwise
        p.sources = [0.35 0 1 0; -0.2 0.2 -0.4 0.02];
        p.xi0 = 0;
        p.load_function = @(X,Y) exp(-3*(X.^2+Y.^2));
end
end

% =====================================================================
% 2. GraphiteLevitation
% =====================================================================
function info = test_graphite_levitation(repo_root, test_root)
project_root = fullfile(repo_root, 'projects', 'GraphiteLevitation');
out_dir = local_mkdir(fullfile(test_root, 'GraphiteLevitation'));
guard = local_add_project_paths(project_root); %#ok<NASGU>

p = default_graphite_levitation_params();
p.numerics.gridN = 81;
p.numerics.kernelN = 25;
p.numerics.chiGridN = 80;
p.numerics.forceKernelN = 25;
p.numerics.fieldSourceN = 2;
p.array.nx = 4; p.array.ny = 4;
p = validate_graphite_levitation_params(p);

fprintf('Graphite area/mass/extent helpers...\n');
local_assert(graphite_area(p.graphite) > 0, 'graphite_area failed');
local_assert(graphite_mass(p.graphite) > 0, 'graphite_mass failed');
local_assert(all(graphite_extent(p.graphite) > 0), 'graphite_extent failed');
local_assert(~isempty(build_compact_checkerboard_magnets(p)), 'magnet builder failed');
[Wplot, xs, ys] = build_chi_image(p); %#ok<ASGLU>
local_assert(~isempty(Wplot) && ~isempty(xs) && ~isempty(ys), 'build_chi_image failed');

fprintf('Graphite visualization baseline...\n');
r0 = compute_visualization_maps(p);
local_assert(isstruct(r0) && isfield(r0, 'B2') && isfield(r0, 'active'), 'baseline visualization invalid');

p_laser = p;
p_laser.laser.enabled = true;
p_laser.laser.alpha = 0.35;
fprintf('Graphite visualization with laser...\n');
r1 = compute_magnetic_potential(p_laser);
local_assert(isstruct(r1) && isfield(r1, 'B2') && isfield(r1, 'metrics'), 'laser visualization invalid');

bundle = struct('results', {{r0, r1}}, 'params', p_laser, 'scanned', {{}});
files = render_graphite_levitation_result('visualization_bundle', bundle, out_dir, 'Prefix', 'graphite');
local_assert_files(files);
info = local_info(files);
end

% =====================================================================
% 3. CrystalOpticsBoundary
% =====================================================================
function info = test_crystal_optics_boundary(repo_root, test_root)
project_root = fullfile(repo_root, 'projects', 'CrystalOpticsBoundary');
out_dir = local_mkdir(fullfile(test_root, 'CrystalOpticsBoundary'));
guard = local_add_project_paths(project_root); %#ok<NASGU>

cfg = parse_crystal_boundary_params('defaults');
cfg.pol.type = 2;
cfg.pol.angle_deg = 25;
cfg.pol.num_samples = 13;
fprintf('Crystal single-polarization solve...\n');
result_single = crystal_boundary_formula(cfg);
local_assert(isfield(result_single, 'single'), 'single crystal result missing');
report_text = render_crystal_report(result_single);
report_path = fullfile(out_dir, 'crystal_single_report.txt');
local_write_text(report_path, report_text);
local_assert_file(report_path);

fprintf('Crystal arbitrary vector solve...\n');
cfg_vec = cfg;
cfg_vec.pol.type = 1;
cfg_vec.pol.vector = [0; 1; 0];
res_vec = crystal_boundary_formula(cfg_vec);
local_assert(isfield(res_vec, 'single'), 'vector crystal result missing');

fprintf('Crystal polarization sweep solve...\n');
cfg_sweep = cfg;
cfg_sweep.pol.type = 3;
cfg_sweep.pol.num_samples = 9;
res_sweep = crystal_boundary_formula(cfg_sweep);
local_assert(isfield(res_sweep, 'sweep') && numel(res_sweep.sweep.sample) == 9, 'sweep crystal result invalid');
sweep_path = fullfile(out_dir, 'crystal_sweep_summary.txt');
local_write_lines(sweep_path, {sprintf('samples = %d', numel(res_sweep.sweep.sample)), sprintf('first alpha = %.6g', res_sweep.sweep.alpha_deg(1))});

info = local_info({report_path, sweep_path});
end

% =====================================================================
% 4. MieScattering
% =====================================================================
function info = test_mie_scattering(repo_root, test_root)
project_root = fullfile(repo_root, 'projects', 'MieScattering');
out_dir = local_mkdir(fullfile(test_root, 'MieScattering'));
guard = local_add_project_paths(project_root); %#ok<NASGU>

items = parse_mie_scattering_params('custom_items');
labels = parse_mie_scattering_params('custom_labels');
local_assert(numel(items) == numel(labels) && numel(items) >= 10, 'Mie custom item parser failed');
z = parse_mie_scattering_params('str2complex', '2+0.1i');
local_assert(abs(z-(2+0.1i)) < 1e-12, 'Mie complex parser failed');

files = {};
for k = 1:2
    geom = local_ifelse(k == 1, 'sphere', 'cylinder');
    cfg = struct();
    cfg.eps1 = 2 + 0.1i;
    cfg.mu1 = 0.8 + 0.05i;
    cfg.R_over_lambda = 0.45;
    cfg.nu = 1.1;
    cfg.psi = 0.2;
    cfg.geometry = geom;
    cfg.mode = 'custom';
    cfg.customSelection = {'sca_rex','sca_rey','sca_rez','sca_emag','tot_emag'};
    cfg.gridHalfWidth = 2.1;
    cfg.N = 121;
    cfg.nmaxExtra = 10;
    cfg.maskInside = true;
    fprintf('Mie scattering %s...\n', geom);
    r = compute_mie_scattering(cfg);
    local_assert(isstruct(r) && strcmp(r.kind, 'bundle') && numel(r.items) == numel(cfg.customSelection), 'Mie bundle invalid');
    files = [files, local_cellstr(render_result('render', r, out_dir, 'Prefix', ['mie_' geom], 'DPI', 120))]; %#ok<AGROW>
end
local_assert_files(files);
info = local_info(files);
end

% =====================================================================
% 5. MovingChargeFields
% =====================================================================
function info = test_moving_charge_fields(repo_root, test_root)
project_root = fullfile(repo_root, 'projects', 'MovingChargeFields');
out_dir = local_mkdir(fullfile(test_root, 'MovingChargeFields'));
guard = local_add_project_paths(project_root); %#ok<NASGU>

fprintf('Moving charge direct formula circular/harmonic...\n');
[x, y] = meshgrid(linspace(-1.5, 1.5, 42));
z = 0*x;
[data_c, rq_c] = moving_charge_formula(x, y, z, 0, 'circular', 1.0, 0.5, 1.0); %#ok<ASGLU>
local_assert(isstruct(data_c) && isfield(data_c, 'tot'), 'circular formula invalid');
[data_h, rq_h] = moving_charge_formula(x, y, z, 0.3, 'harmonic', 1.0, 0.4, 1.0); %#ok<ASGLU>
local_assert(isstruct(data_h) && isfield(data_h, 'vel'), 'harmonic formula invalid');

params = run_moving_charge_generation('defaults');
params.motionType = 'circular';
params.beta_max = 0.55;
params.a_over_lambda = 0.8;
params.sliceType = 'xy';
params.partType = 'tot';
params.selectedFields = {'E_mag','B_mag','tau','S_stream'};
params = run_moving_charge_generation('normalize', params);
local_assert(numel(params.selectedFields) == 4, 'moving-charge normalize failed');

fprintf('Moving charge image generation...\n');
res = run_moving_charge_generation('generate', params, out_dir);
files = local_collect_files(res);
local_assert_files(files);
info = local_info(files);
end

% =====================================================================
% 6. SpecialFunctionsStudio
% =====================================================================
function info = test_special_functions_studio(repo_root, test_root)
project_root = fullfile(repo_root, 'projects', 'SpecialFunctionsStudio');
out_dir = local_mkdir(fullfile(test_root, 'SpecialFunctionsStudio'));
guard = local_add_project_paths(project_root); %#ok<NASGU>

catalog = parse_special_functions_params('catalog');
files = {};
count = 0;
for f = 1:numel(catalog)
    fam = catalog(f);
    for v = 1:numel(fam.Variants)
        variant = fam.Variants(v);
        params = local_special_params(fam, variant);
        fprintf('Special function %s / %s...\n', fam.Key, variant.Key);
        result = parse_special_functions_params('dispatch', params);
        local_assert(isstruct(result) && isfield(result, 'kind'), 'special function dispatch invalid');
        png = fullfile(out_dir, sprintf('%02d_%s_%s.png', count+1, local_slug(fam.Key), local_slug(variant.Key)));
        render_result('render', result, png, 'DPI', 130, 'Layout', 'auto', 'RenderOptions', struct('legend_location', 'best'));
        local_assert_file(png);
        files{end+1} = png; %#ok<AGROW>
        count = count + 1;
    end
end
local_assert(count >= 20, 'too few special-function variants were tested');
info = local_info(files);
end

function params = local_special_params(fam, variant)
params = struct();
params.family = fam.Key;
params.variant = variant.Key;
params.xmin = fam.DefaultXRange(1);
params.xmax = fam.DefaultXRange(2);
params.layout_text = 'auto';
params.crop = struct('mode', 'auto', 'y_range', []);
params.render_options = struct('legend_location', 'best');
labels = variant.ParamLabels;
if isempty(labels)
    params.arg_matrix = zeros(1,0);
    return;
end
row = zeros(1, numel(labels));
for k = 1:numel(labels)
    lab = lower(char(string(labels{k})));
    switch lab
        case {'nu'}
            row(k) = 2;
        case {'n'}
            row(k) = 1;
        case {'m'}
            row(k) = 0.5;
        case {'l'}
            row(k) = 2;
        case {'a'}
            row(k) = 0.5;
        case {'b'}
            row(k) = 1.0;
        case {'c'}
            row(k) = 2.0;
        otherwise
            row(k) = 1;
    end
end
if any(strcmpi(labels, 'l')) && any(strcmpi(labels, 'm'))
    row = [2 1];
end
params.arg_matrix = row;
end

% =====================================================================
% 7. Waveguide
% =====================================================================
function info = test_waveguide(repo_root, test_root)
project_root = fullfile(repo_root, 'projects', 'Waveguide');
out_dir = local_mkdir(fullfile(test_root, 'Waveguide'));
guard = local_add_project_paths(project_root); %#ok<NASGU>

fprintf('Waveguide low-level helpers...\n');
C = physical_constants();
local_assert(isfield(C, 'c0') && C.c0 > 0, 'physical_constants failed');
[jr, jpr] = bessel_roots(1, 1); %#ok<ASGLU>
local_assert(jr > 0 && jpr > 0, 'bessel_roots failed');
local_assert(abs(besseljprime(1, 1.5)) < 10, 'besseljprime failed');
local_assert(~isempty(rectangular_metal_field('TE', 1, 0, 0.08, 0.04, 80)), 'rect field failed');
local_assert(~isempty(rectangular_metal_field('TM', 1, 1, 0.08, 0.04, 80)), 'rect TM field failed');
local_assert(~isempty(circular_metal_field('TE', 1, 1, 0.03, 80)), 'circular field failed');
local_assert(~isempty(rectangular_metal_dispersion('TE', 0.08, 0.04, 4, 0, 12, 80)), 'rect dispersion failed');
local_assert(~isempty(rectangular_cutoff_map('TE', 0.08, 0.04, 4)), 'rect cutoff failed');
local_assert(~isempty(circular_metal_dispersion('TE', 0.03, 4, 0, 12, 80)), 'circ dispersion failed');
local_assert(~isempty(planar_dispersion('TE', 1.48, 1.46, 8, 4, 80)), 'planar dispersion failed');
local_assert(~isempty(planar_existence('TE', 8, 4)), 'planar existence failed');
local_assert(~isempty(planar_field('TE', 0, 12, 1.48, 1.46, 1.5e-3, 3e-3, 80)), 'planar field failed');
local_assert(~isempty(planar_thickness_sweep('TE', 1.48, 1.46, 1.5e-3, 12, 4, 60)), 'planar sweep failed');
local_assert(~isempty(circular_dielectric_dispersion(1.48, 1.46, 8, 8, 4, 60)), 'cyl dielectric failed');

files = {};
base = local_waveguide_common_params();

p = base; p.guide = 'rectangular'; p.action = 'mode field'; p.mode_type = 'TE'; p.mode_matrix = [1 0; 2 0];
r = run_metal_guide_generation(out_dir, p); files = [files, local_collect_files(r)]; %#ok<AGROW>
p = base; p.guide = 'rectangular'; p.action = 'dispersion curves'; p.mode_type = 'TE'; p.mode_matrix = zeros(0,2);
r = run_metal_guide_generation(out_dir, p); files = [files, local_collect_files(r)]; %#ok<AGROW>
p = base; p.guide = 'rectangular'; p.action = 'cutoff map'; p.mode_type = 'TM'; p.mode_matrix = zeros(0,2);
r = run_metal_guide_generation(out_dir, p); files = [files, local_collect_files(r)]; %#ok<AGROW>
p = base; p.guide = 'circular'; p.action = 'mode field'; p.mode_type = 'TE'; p.mode_matrix = [1 1];
r = run_metal_guide_generation(out_dir, p); files = [files, local_collect_files(r)]; %#ok<AGROW>
p = base; p.guide = 'circular'; p.action = 'dispersion curves'; p.mode_type = 'TM'; p.mode_matrix = zeros(0,2);
r = run_metal_guide_generation(out_dir, p); files = [files, local_collect_files(r)]; %#ok<AGROW>

pd = local_planar_params('mode field'); r = run_planar_dielectric_generation(out_dir, pd); files = [files, local_collect_files(r)]; %#ok<AGROW>
pd = local_planar_params('dispersion curve'); r = run_planar_dielectric_generation(out_dir, pd); files = [files, local_collect_files(r)]; %#ok<AGROW>
pd = local_planar_params('mode existence'); r = run_planar_dielectric_generation(out_dir, pd); files = [files, local_collect_files(r)]; %#ok<AGROW>
pd = local_planar_params('thickness sweep'); r = run_planar_dielectric_generation(out_dir, pd); files = [files, local_collect_files(r)]; %#ok<AGROW>
cd = struct('n1', 1.48, 'n2', 1.46, 'vmax', 8, 'umax', 8, 'max_order', 4, 'samples', 80, 'legend_location', 'best');
r = run_cylindrical_dielectric_generation(out_dir, cd); files = [files, local_collect_files(r)];

local_assert_files(files);
info = local_info(files);
end

function p = local_waveguide_common_params()
p = struct('legend_location', 'best', 'map_name', 'project', 'grid_n', 80, 'samples', 80, ...
    'layout_rows', 'auto', 'max_order', 4, 'fmax_ghz', 12.0, 'a', 0.08, 'b', 0.04, 'radius', 0.03);
end

function p = local_planar_params(action)
p = struct('waveguide', 'planar', 'action', action, 'mode_type', 'TE', 'legend_location', 'best', ...
    'map_name', 'project', 'grid_n', 80, 'samples', 80, 'layout_rows', 'auto', 'max_order', 4, ...
    'vmax', 8, 'fmax_hz', 40e9, 'd', 1.5e-3, 'n1', 1.48, 'n2', 1.46, ...
    'freq_ghz', 12, 'z_length', 3e-3, 'order_list', 0);
end

% =====================================================================
% 8. RigidBodyRotation
% =====================================================================
function info = test_rigid_body_rotation(repo_root, test_root)
project_root = fullfile(repo_root, 'projects', 'RigidBodyRotation');
out_dir = local_mkdir(fullfile(test_root, 'RigidBodyRotation'));
guard = local_add_project_paths(project_root); %#ok<NASGU>

free_input = struct('I', [1 1.5 0.8], 'w0', [2; 0.5; 0.1], 'phi0', pi/4, 'tEnd', 2, 'nSamples', 301);
fixed_input = struct('I', [0.8 1.1 1.4], 'aBody', [0; 0; 0.3], 'mass', 1.2, 'g', 9.81, ...
    'euler0', [0.2; 0.45; 0.1], 'w0', [0.4; 0.1; 8.0], 'tEnd', 2, 'nSamples', 301);
compare_input = free_input;
compare_input.mode = 'free';
compare_input.compareCases = [2 0.5 0.1 0; 1.6 0.4 0.3 0.6];

fprintf('Rigid body free...\n');
r_free = rigid_body_solver('free', free_input);
local_assert(isfield(r_free, 'wBody') && size(r_free.wBody, 2) == 3, 'free rigid result invalid');
fprintf('Rigid body fixed...\n');
r_fixed = rigid_body_solver('fixed', fixed_input);
local_assert(isfield(r_fixed, 'axisTips'), 'fixed rigid result invalid');
fprintf('Rigid body compare...\n');
r_cmp = rigid_body_solver('compare', compare_input);
local_assert(isfield(r_cmp, 'caseResults') && numel(r_cmp.caseResults) == 2, 'compare rigid result invalid');

files = {};
files{end+1} = local_plot_lines(out_dir, 'rigid_free_wbody.png', r_free.t, r_free.wBody, {'wx','wy','wz'}, 'Free rotation body angular velocity');
files{end+1} = local_plot_lines(out_dir, 'rigid_fixed_wbody.png', r_fixed.t, r_fixed.wBody, {'wx','wy','wz'}, 'Fixed-point body angular velocity');
files{end+1} = local_plot_compare(out_dir, 'rigid_compare_energy.png', r_cmp);
local_assert_files(files);
info = local_info(files);
end

function file = local_plot_lines(out_dir, filename, x, Y, labels, title_text)
fig = image_output('hidden_figure', 'Position', [100 100 900 600]);
ax = axes('Parent', fig);
plot(ax, x, Y, 'LineWidth', 1.2);
grid(ax, 'on'); xlabel(ax, 't'); ylabel(ax, 'value'); title(ax, title_text);
legend(ax, labels, 'Location', 'best');
file = image_output('save_figure', fig, out_dir, filename, 160);
close(fig);
end

function file = local_plot_compare(out_dir, filename, r_cmp)
fig = image_output('hidden_figure', 'Position', [100 100 900 600]);
ax = axes('Parent', fig); hold(ax, 'on');
for k = 1:numel(r_cmp.caseResults)
    r = r_cmp.caseResults{k};
    plot(ax, r.t, r.constants.energy, 'LineWidth', 1.2, 'DisplayName', r_cmp.caseLabels{k});
end
hold(ax, 'off'); grid(ax, 'on'); xlabel(ax, 't'); ylabel(ax, 'energy'); title(ax, 'Compare energy'); legend(ax, 'Location', 'best');
file = image_output('save_figure', fig, out_dir, filename, 160);
close(fig);
end

% =====================================================================
% 9. ThinFilm
% =====================================================================
function info = test_thin_film(repo_root, test_root)
project_root = fullfile(repo_root, 'projects', 'ThinFilm');
out_dir = local_mkdir(fullfile(test_root, 'ThinFilm'));
guard = local_add_project_paths(project_root); %#ok<NASGU>

elastic_data = elastic_film_formula('defaultInput');
elastic_result = elastic_film_formula('solve', elastic_data);
local_assert(isstruct(elastic_result), 'elastic_film_formula solve failed');
elastic_report = thin_film_model('report', thin_film_model('defaults'));
elastic_path = fullfile(out_dir, 'elastic_report.txt');
local_write_text(elastic_path, elastic_report.text);

optical_data = optical_film_formula('defaultInput');
optical_result = optical_film_formula('solve', optical_data);
local_assert(isstruct(optical_result), 'optical_film_formula solve failed');
optical_report = thin_film_model('report_optical', thin_film_model('defaults_optical'));
optical_path = fullfile(out_dir, 'optical_report.txt');
local_write_text(optical_path, optical_report.text);

local_assert_files({elastic_path, optical_path});
info = local_info({elastic_path, optical_path});
end

% =====================================================================
% 10. OpticsStudio
% =====================================================================
function info = test_optics_studio(repo_root, test_root)
project_root = fullfile(repo_root, 'projects', 'OpticsStudio');
out_dir = local_mkdir(fullfile(test_root, 'OpticsStudio'));
guard = local_add_project_paths(project_root); %#ok<NASGU>

files = {};
fprintf('Optics common helpers...\n');
[x, y, fx, fy] = make_coordinate_grid(64, 64, 5e-6, 5e-6); %#ok<ASGLU>
for t = {'bars','mesh','double_slit','aperture','gaussian_lattice'}
    obj = make_demo_object(t{1}, 64);
    local_assert(isequal(size(obj), [64 64]), ['make_demo_object failed: ' t{1}]);
end
tmp_norm = normalize_array(rand(8));
local_assert(max(tmp_norm(:)) <= 1, 'normalize_array failed');

fprintf('Optics Fourier plane modules...\n');
files = [files, local_test_fourier_modules(project_root, out_dir)]; %#ok<AGROW>

fprintf('Optics imaging...\n');
[psf, pupil, wavefront] = compute_psf_2d(128, 'defocus', 0.7); %#ok<ASGLU>
otf = compute_otf(psf);
local_assert(isequal(size(psf), size(otf)), 'PSF/OTF size mismatch');
[pupil_mask, rho, phi] = make_circular_pupil(128); %#ok<ASGLU>
for mode = {'tilt_x','defocus','astigmatism','coma','spherical'}
    w = zernike_wavefront(mode{1}, rho, phi);
    local_assert(isequal(size(w), size(rho)), ['zernike failed: ' mode{1}]);
end
files{end+1} = local_save_image_grid(out_dir, 'optics_imaging.png', {abs(pupil), psf, abs(otf)}, {'pupil','psf','otf'}); %#ok<AGROW>

fprintf('Optics interference...\n');
gs = gerchberg_saxton_phase(96, 5, 14, 12, 0.7);
gr = make_grating(96, 7, 25, 0.3);
sh = shearing_interferogram(96, 'defocus', 0.3, 5, 0.08);
local_assert(isstruct(gs) && ~isempty(gr) && isstruct(sh), 'interference module failed');
files{end+1} = local_save_image_grid(out_dir, 'optics_interference.png', {gr, local_first_numeric_field(gs), local_first_numeric_field(sh)}, {'grating','GS','shearing'}); %#ok<AGROW>

fprintf('Optics ray tracing...\n');
coeff = fresnel_coefficients(1.0, 1.5, pi/6);
[tdir, tir] = snell_refraction([0; sin(pi/8); -cos(pi/8)], [0;0;1], 1.0, 1.5); %#ok<ASGLU>
rsph = trace_spherical_interface_bundle(1.0, 1.5, 0.08, 0.02, 9, 0.20);
rlens = trace_thin_lens_bundle(0.30, 0.10, 0.02, 0.025, 9);
local_assert(isstruct(coeff) && isstruct(rsph) && isstruct(rlens), 'ray optics failed');

fprintf('Optics tomography...\n');
phantom_img = make_phantom_slice(96, 'shepp-logan');
theta = linspace(0, 177, 30);
[sinogram, det] = parallel_radon_transform(phantom_img, theta, 96);
[recon, filt_sino, filt] = filtered_backprojection(sinogram, det, theta, 96, 'hann'); %#ok<ASGLU>
local_assert(isequal(size(recon), [96 96]), 'tomography reconstruction failed');
files{end+1} = local_save_image_grid(out_dir, 'optics_tomography.png', {phantom_img, sinogram, recon}, {'phantom','sinogram','reconstruction'}); %#ok<AGROW>

fprintf('Optics wave propagation...\n');
[X, Y] = meshgrid(linspace(-1,1,128));
u0 = double(hypot(X,Y) <= 0.45);
[u1, H] = angular_spectrum_propagation(u0, 8e-6, 532e-9, 15e-3, true);
mask = make_fourier_filter('ring', fx, fy, 0.2); %#ok<NASGU>
local_assert(isequal(size(u1), size(u0)) && isequal(size(H), size(u0)), 'wave propagation failed');
files{end+1} = local_save_image_grid(out_dir, 'optics_wave.png', {u0, real(H), abs(u1).^2}, {'input','transfer','intensity'}); %#ok<AGROW>

fprintf('Optics thin-film copy...\n');
try
    % ThinFilm is a cross-project dependency; add its path temporarily
    tf_root = fullfile(repo_root, 'projects', 'ThinFilm');
    tf_path = genpath(tf_root);
    addpath(tf_path);
    tf_cleanup = onCleanup(@() rmpath(tf_path)); %#ok<NASGU>
    er = thin_film_model('report', thin_film_model('defaults'));
    op = thin_film_model('report_optical', thin_film_model('defaults_optical'));
    ftxt = fullfile(out_dir, 'optics_thinfilm_reports.txt');
    local_write_text(ftxt, sprintf('%s\n\n%s', er.text, op.text));
    files{end+1} = ftxt; %#ok<AGROW>
catch ME
    error('Optics thin-film facade failed: %s', ME.message);
end

local_assert_files(files);
info = local_info(files);
end

function files = local_test_fourier_modules(project_root, out_dir)
files = {};
presets = fourier_params_preset();
p = presets(1);
p.n_samples = 256;
p.window_mm = 3.0;
p.window_m = p.window_mm * 1e-3;
p.object_scale_m = p.object_scale_mm * 1e-3;
p.secondary_scale_m = p.secondary_scale_mm * 1e-3;
p.phase_radius_m = p.phase_radius_mm * 1e-3;
p.lambda_m = p.wavelength_nm * 1e-9;
p.f_m = p.focal_length_mm * 1e-3;

N = 64;
xx = linspace(-1.5e-3, 1.5e-3, N);
[X, Y] = meshgrid(xx, xx);
[FX, FY] = meshgrid(linspace(-1e-3, 1e-3, N));
object_fcns = {@object_circular_aperture,@object_cross_aperture,@object_double_slit,@object_finite_2d_grating,@object_five_slits,@object_hex_lattice_circles,@object_rectangular_aperture,@object_star_aperture,@object_three_slits,@object_two_circular_apertures};
phase_fcns = {@phase_no_phase,@phase_thin_lens,@phase_vortex_charge_1,@phase_vortex_charge_2,@phase_zernike_astigmatism_0_deg,@phase_zernike_astigmatism_45_deg,@phase_zernike_coma_x,@phase_zernike_coma_y,@phase_zernike_defocus,@phase_zernike_spherical,@phase_zernike_tilt_x};
filter_fcns = {@filter_circular_high_pass,@filter_circular_low_pass,@filter_diagonal_slit,@filter_horizontal_double_slit,@filter_horizontal_slit,@filter_mesh,@filter_no_filter,@filter_ring_band_pass,@filter_vertical_double_slit,@filter_vertical_slit};
for i = 1:numel(object_fcns)
    info = object_fcns{i}('info'); %#ok<NASGU>
    A = object_fcns{i}(X, Y, p);
    local_assert(isequal(size(A), size(X)), 'object module size failure');
end
for i = 1:numel(phase_fcns)
    info = phase_fcns{i}('info'); %#ok<NASGU>
    A = phase_fcns{i}(X, Y, p);
    local_assert(isequal(size(A), size(X)), 'phase module size failure');
end
for i = 1:numel(filter_fcns)
    info = filter_fcns{i}('info'); %#ok<NASGU>
    A = filter_fcns{i}(FX, FY, p);
    local_assert(isequal(size(A), size(FX)), 'filter module size failure');
end
mods = discover_fourier_modules(fullfile(project_root, 'core', 'fourier')); %#ok<NASGU>

p.object_name = 'Double slit'; p.phase_name = 'No phase'; p.filter_name = 'Circular low-pass';
r = fourier_4f_model(p, @object_double_slit, @phase_no_phase, @filter_circular_low_pass);
local_assert(isfield(r, 'output_intensity'), 'fourier_4f_model failed');
files{end+1} = local_save_image_grid(out_dir, 'optics_fourier_4f.png', {r.object_amp, r.spectrum_intensity, r.filter_amp, r.output_intensity}, {'object','spectrum','filter','output'});
end

% =====================================================================
% 11. CreativePlotStudio
% =====================================================================
function info = test_creative_plot_studio(repo_root, test_root)
project_root = fullfile(repo_root, 'projects', 'CreativePlotStudio');
out_dir = local_mkdir(fullfile(test_root, 'CreativePlotStudio'));
guard = local_add_project_paths(project_root); %#ok<NASGU>

scripts = local_find_named_files(fullfile(project_root, 'core'), 'render.m');
local_assert(~isempty(scripts), 'No CreativePlotStudio render.m scripts found');
files = {};
failures = {};
for k = 1:numel(scripts)
    script_path = scripts{k};
    rel = script_path(numel(fullfile(project_root, 'core'))+2:end);
    fprintf('Creative render %03d/%03d: %s\n', k, numel(scripts), rel);
    fig = [];
    try
        fig = image_output('hidden_figure', 'Position', [100 100 900 700]);
        ax = axes('Parent', fig);
        image_output('run_core_script', script_path, ax, 'default');
        drawnow;
        png = image_output('save_figure', fig, out_dir, [sprintf('%03d_', k) local_slug(rel) '.png'], 140);
        local_assert_file(png);
        files{end+1} = png; %#ok<AGROW>
    catch ME
        failures{end+1} = sprintf('%s -- %s', rel, ME.message); %#ok<AGROW>
    end
    if ~isempty(fig) && isgraphics(fig)
        try, close(fig); catch, end
    end
end
if ~isempty(failures)
    local_write_lines(fullfile(out_dir, 'creative_failures.txt'), failures);
    error('CreativePlotStudio render failures (%d/%d). First: %s', numel(failures), numel(scripts), failures{1});
end
local_assert_files(files);
info = local_info(files);
end

% =====================================================================
% General plotting/output helpers
% =====================================================================
function file = local_save_image_grid(out_dir, filename, images, titles)
fig = image_output('hidden_figure', 'Position', [100 100 1100 360]);
n = numel(images);
try
    tl = tiledlayout(fig, 1, n, 'TileSpacing', 'compact', 'Padding', 'compact');
    for i = 1:n
        ax = nexttile(tl);
        imagesc(ax, images{i}); axis(ax, 'image'); axis(ax, 'off'); colorbar(ax);
        title(ax, titles{i});
    end
catch
    for i = 1:n
        ax = subplot(1, n, i, 'Parent', fig);
        imagesc(ax, images{i}); axis(ax, 'image'); axis(ax, 'off'); colorbar(ax);
        title(ax, titles{i});
    end
end
file = image_output('save_figure', fig, out_dir, filename, 150);
close(fig);
end

function A = local_first_numeric_field(s)
A = [];
if isnumeric(s)
    A = s;
    return;
end
if ~isstruct(s), return; end
names = fieldnames(s);
for k = 1:numel(names)
    v = s.(names{k});
    if isnumeric(v) && ismatrix(v) && numel(v) > 4
        A = v;
        return;
    elseif isstruct(v)
        A = local_first_numeric_field(v);
        if ~isempty(A), return; end
    end
end
if isempty(A), A = zeros(8); end
end

% =====================================================================
% Files, paths, assertions, and compatibility helpers
% =====================================================================
function cfg = local_parse_options(varargin)
cfg = struct('list_only', false, 'quick', false, 'project', '');
k = 1;
while k <= numel(varargin)
    arg = lower(char(string(varargin{k})));
    switch arg
        case {'list','--list'}
            cfg.list_only = true;
        case {'quick','--quick'}
            cfg.quick = true;
        case {'full','--full'}
            cfg.quick = false;
        case {'project','--project'}
            if k < numel(varargin)
                cfg.project = char(string(varargin{k+1}));
                k = k + 1;
            else
                error('project option requires a value.');
            end
        otherwise
            if isempty(cfg.project)
                cfg.project = char(string(varargin{k}));
            else
                error('Unknown option: %s', char(string(varargin{k})));
            end
    end
    k = k + 1;
end
end

function cleanup = local_add_project_paths(project_root)
paths = {};
for p = {fullfile(project_root, 'app'), fullfile(project_root, 'core'), fullfile(project_root, 'docs')}
    if exist(p{1}, 'dir') == 7
        gp = genpath(p{1});
        addpath(gp);
        paths{end+1} = gp; %#ok<AGROW>
    end
end
cleanup = onCleanup(@() local_remove_paths(paths));
end

function local_remove_paths(paths)
for i = numel(paths):-1:1
    try, rmpath(paths{i}); catch, end
end
end

function d = local_mkdir(d)
if exist(d, 'dir') ~= 7, mkdir(d); end
end

function local_assert(cond, msg)
if ~cond
    error('%s', msg);
end
end

function local_assert_file(file)
local_assert(ischar(file) || isstring(file), 'file path is not text');
file = char(string(file));
local_assert(exist(file, 'file') == 2, ['missing output file: ' file]);
try
    info = dir(file);
    local_assert(info.bytes > 0, ['empty output file: ' file]);
catch
end
end

function local_assert_files(files)
files = local_cellstr(files);
local_assert(~isempty(files), 'expected at least one output file');
for i = 1:numel(files)
    local_assert_file(files{i});
end
end

function out = local_info(files)
out = struct('files', {local_cellstr(files)});
end

function files = local_collect_files(x)
files = {};
if isempty(x), return; end
if iscell(x) || isstring(x) || ischar(x)
    files = local_cellstr(x);
    return;
end
if isstruct(x)
    keys = {'files','paths','png_paths','image_paths'};
    for k = 1:numel(keys)
        if isfield(x, keys{k})
            files = [files, local_cellstr(x.(keys{k}))]; %#ok<AGROW>
        end
    end
    keys2 = {'output_png','composite_path','report_path','text','parameters','preview_png'};
    for k = 1:numel(keys2)
        if isfield(x, keys2{k}) && ~isempty(x.(keys2{k}))
            files = [files, local_cellstr(x.(keys2{k}))]; %#ok<AGROW>
        end
    end
end
files = files(~cellfun(@isempty, files));
end

function c = local_cellstr(x)
if isempty(x)
    c = {};
elseif iscell(x)
    c = {};
    for i = 1:numel(x)
        c = [c, local_cellstr(x{i})]; %#ok<AGROW>
    end
elseif isstring(x)
    c = cellstr(x(:).');
elseif ischar(x)
    c = {x};
else
    c = {};
end
end

function local_write_text(path, text)
fid = fopen(path, 'w', 'n', 'UTF-8');
if fid == -1, error('Could not write %s', path); end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', char(string(text)));
end

function local_write_lines(path, lines)
lines = local_cellstr(lines);
fid = fopen(path, 'w', 'n', 'UTF-8');
if fid == -1, error('Could not write %s', path); end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end

function txt = local_read_text(path)
try
    fid = fopen(path, 'r', 'n', 'UTF-8');
    if fid == -1, txt = ''; return; end
    cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
    txt = fread(fid, '*char').';
catch
    txt = '';
end
end

function lines = local_split_lines(txt)
if isempty(txt)
    lines = {''};
else
    lines = regexp(char(txt), '\r\n|\n|\r', 'split').';
end
end

function local_write_summary_csv(path, results)
fid = fopen(path, 'w', 'n', 'UTF-8');
if fid == -1, error('Could not write %s', path); end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, 'project,name,status,duration_sec,file_count,message,normal_output_file\n');
for i = 1:numel(results)
    fprintf(fid, '%s,%s,%s,%.6f,%d,%s,%s\n', local_csv(results(i).project), local_csv(results(i).name), ...
        local_csv(results(i).status), results(i).duration_sec, numel(results(i).files), local_csv(results(i).message), local_csv(results(i).normal_output_file));
end
end

function s = local_csv(x)
s = char(string(x));
s = strrep(s, '"', '""');
s = ['"' s '"'];
end

function out = local_slug(txt)
out = lower(char(string(txt)));
out = regexprep(out, '[^a-zA-Z0-9]+', '_');
out = regexprep(out, '^_+|_+$', '');
if isempty(out), out = 'item'; end
if numel(out) > 90, out = out(1:90); end
end

function s = local_ifelse(cond, a, b)
if cond, s = a; else, s = b; end
end

function local_restore_figures(old_visibility)
if ~isempty(old_visibility)
    try, set(groot, 'DefaultFigureVisible', old_visibility); catch, end
end
end

function files = local_find_named_files(root_dir, filename)
files = {};
if exist(root_dir, 'dir') ~= 7, return; end
items = dir(root_dir);
for i = 1:numel(items)
    nm = items(i).name;
    if strcmp(nm, '.') || strcmp(nm, '..'), continue; end
    full = fullfile(root_dir, nm);
    if items(i).isdir
        files = [files; local_find_named_files(full, filename)]; %#ok<AGROW>
    elseif strcmpi(nm, filename)
        files{end+1,1} = full; %#ok<AGROW>
    end
end
end
