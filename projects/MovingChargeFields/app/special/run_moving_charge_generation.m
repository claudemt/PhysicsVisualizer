function result = run_moving_charge_generation(action, params, project_root)
%RUN_MOVING_CHARGE_GENERATION Preview/export moving-charge plots and own its project parameters.
% Shared display mechanics such as hidden figures and VideoWriter frame sizing live in image_output.

if nargin < 1 || isempty(action)
    action = 'generate';
end

switch lower(char(string(action)))
    case {'defaults','default_params'}
        result = local_default_params();
        return;
    case {'normalize','normalize_params'}
        if nargin < 2 || isempty(params), params = struct(); end
        result = local_normalize_params(params);
        return;
end

if nargin < 3 || isempty(project_root)
    project_root = pwd;
end
if nargin < 2 || isempty(params)
    params = struct();
end
params = local_normalize_params(params);

switch lower(char(string(action)))
    case 'preview'
        result = preview_current_field(params);
    case 'generate'
        result = generate_current_case(params, project_root);
    case 'export'
        result = export_current_case(params, project_root);
    otherwise
        error('Unknown action: %s', action);
end
end

function result = preview_current_field(params)
visibility_guard = image_output('hidden_figures'); %#ok<NASGU>
field_list = export_field_list(params);
field_list = field_list(1);
params.fieldType = field_list{1};
[uvx, uvy] = build_plot_axes(params.a_over_lambda, params.slicePos_over_lambda, 'image', params.beta_max, field_list);
payload = compute_frame_payload(uvx, uvy, params.motionType, params.a_over_lambda, params.beta_max, ...
    params.sliceType, params.slicePos_over_lambda, params.phase_over_T, params.partType, params.fieldType);
fig = create_plot_figure(payload, uvx, uvy, payload.rq_now_plot, params, params.fieldType);
preview_png = [tempname, '.png'];
exportgraphics(fig, preview_png, 'Resolution', 180);
close(fig);
result = struct('preview_png', preview_png, 'case_dir', '', 'paths', {{}});
end

function result = generate_current_case(params, project_root)
%GENERATE_CURRENT_CASE Render preview PNGs using the original drawing pipeline.
visibility_guard = image_output('hidden_figures'); %#ok<NASGU>
params.cmapMode = 'log';
cache_dir = image_output('clear_cache', project_root, 'moving_charge');
field_list = export_field_list(params);
[uvx, uvy] = build_plot_axes(params.a_over_lambda, params.slicePos_over_lambda, 'image', params.beta_max, field_list);
paths = cell(1, numel(field_list));

for k = 1:numel(field_list)
    payload = compute_frame_payload(uvx, uvy, params.motionType, params.a_over_lambda, params.beta_max, ...
        params.sliceType, params.slicePos_over_lambda, params.phase_over_T, params.partType, field_list{k});
    fig = create_plot_figure(payload, uvx, uvy, payload.rq_now_plot, params, field_list{k});
    paths{k} = image_output('save_figure', fig, cache_dir, [make_output_basename(params, field_list{k}), '.png'], 260);
    close(fig);
end

result = struct('preview_png', '', 'case_dir', cache_dir, 'output_dir', cache_dir, ...
    'paths', {paths}, 'files', {paths}, 'storage_folder', cache_dir);
end

function result = export_current_case(params, project_root)
%EXPORT_CURRENT_CASE Export sequentially-numbered image/video files via shared utils.
visibility_guard = image_output('hidden_figures'); %#ok<NASGU>
params.cmapMode = 'log';
cache_dir = image_output('clear_cache', project_root, 'moving_charge_export');

field_list = export_field_list(params);
[uvx, uvy] = build_plot_axes(params.a_over_lambda, params.slicePos_over_lambda, params.outputMode, params.beta_max, field_list);
nFields = numel(field_list);

% Generate PNG images, pass to export_bundle for numbered output
image_paths = {};
if any(strcmp(params.outputMode, {'image','image+video'}))
    for k = 1:nFields
        payload = compute_frame_payload(uvx, uvy, params.motionType, params.a_over_lambda, params.beta_max, ...
            params.sliceType, params.slicePos_over_lambda, params.phase_over_T, params.partType, field_list{k});
        fig = create_plot_figure(payload, uvx, uvy, payload.rq_now_plot, params, field_list{k});
        image_paths{end+1} = image_output('save_figure', fig, cache_dir, [field_list{k}, '.png'], 300);
        close(fig);
    end
end

reproduce_code = local_reproduce_code(params);
info = image_output('export_bundle', project_root, 'moving_charge', image_paths, ...
    'Params', params, 'ReproduceCode', reproduce_code, 'Composite', false);
out_dir = info.output_dir;

% Copy videos to the same output dir (continue numbering after images)
out_files = info.files;
if any(strcmp(params.outputMode, {'video','image+video'}))
    cfg = default_video_config(params.beta_max);
    for k = 1:nFields
        video_path = save_video_for_field(field_list{k}, uvx, uvy, params, cache_dir, cfg);
        idx = nFields + k;
        dst = fullfile(out_dir, sprintf('%02d_%s.mp4', idx, field_list{k}));
        copyfile(video_path, dst, 'f');
        out_files{end+1} = dst;
    end
end

result = struct('preview_png', '', 'case_dir', out_dir, 'output_dir', out_dir, ...
    'paths', {out_files}, 'files', {out_files}, 'storage_folder', out_dir);
end

function code = local_reproduce_code(params)
assignment = params_output('reproduce_code', 'unused_function', params);
parts = splitlines(assignment);
if numel(parts) >= 2
    param_lines = parts(1:end-1);
else
    param_lines = {'params = struct();'};
end
lines = [ ...
    {'export_dir = fileparts(mfilename(''fullpath''));'; ...
     'project_root = fileparts(fileparts(export_dir));'; ...
     'addpath(genpath(project_root));'}; ...
     param_lines(:); ...
    {'run_moving_charge_generation(''export'', params, project_root);'}];
code = strjoin(lines, newline);
end

function field_list = export_field_list(params)
all_fields = {'E_in','E_n','E_mag','B_in','B_n','B_mag','S_stream','tau','E_stream','B_stream'};
if isfield(params, 'selectedFields') && ~isempty(params.selectedFields)
    field_list = local_cellstr(params.selectedFields);
elseif isfield(params, 'viewMode') && strcmp(params.viewMode, 'custom') && isfield(params, 'customFields') && ~isempty(params.customFields)
    field_list = local_cellstr(params.customFields);
elseif isfield(params, 'exportAllFields') && params.exportAllFields
    field_list = all_fields;
else
    field_list = {params.fieldType};
end
field_list = field_list(ismember(field_list, all_fields));
if isempty(field_list)
    field_list = {params.fieldType};
end
end

function [uvx, uvy] = build_plot_axes(a_over_lambda, slicePos_over_lambda, outputMode, beta_max, fieldList)
span = max([2.5, 2.4*a_over_lambda + abs(slicePos_over_lambda) + 0.5, 1.5*abs(slicePos_over_lambda) + 1.5]);

wantsStream = any(contains(fieldList, 'stream'));
if strcmp(outputMode, 'video')
    nGrid = 221;
else
    nGrid = 301;
end
if beta_max >= 0.95
    nGrid = nGrid + 120;
elseif beta_max >= 0.90
    nGrid = nGrid + 60;
end
if wantsStream && beta_max >= 0.90
    nGrid = nGrid + 20;
end
uvx = linspace(-span, span, nGrid);
uvy = linspace(-span, span, nGrid);
end

function payload = compute_frame_payload(uvx, uvy, motionType, a_over_lambda, beta_max, ...
    sliceType, slicePos_over_lambda, phase_over_T, partType, fieldType)

lambda_ref = 1;
a = a_over_lambda * lambda_ref;
omega = beta_max / a;
T = 2*pi / omega;
tObs = phase_over_T * T;

[U, V] = meshgrid(uvx, uvy);
[X, Y, Z] = make_slice_grid(U, V, sliceType, slicePos_over_lambda * lambda_ref);

[data, rq_now] = moving_charge_formula(X, Y, Z, tObs, motionType, a, omega, lambda_ref);

payload = build_plot_payload(data, fieldType, partType, sliceType, tObs);
payload.rq_now_plot = rq_now ./ lambda_ref;
end

function cfg = default_video_config(beta_max)
cfg.nFrames = 60;
cfg.frameRate = 20;
cfg.resolution = 160;
if beta_max >= 0.95
    cfg.nFrames = 72;
    cfg.resolution = 180;
end
cfg.phaseList = linspace(0, 1, cfg.nFrames);
end

function out_path = save_video_for_field(fieldType, uvx, uvy, params, case_dir, cfg)
writer = [];
out_path = fullfile(case_dir, [make_video_basename(params, fieldType), '.mp4']);
try
    writer = VideoWriter(out_path, 'MPEG-4');
catch
    out_path = fullfile(case_dir, [make_video_basename(params, fieldType), '.avi']);
    writer = VideoWriter(out_path, 'Motion JPEG AVI');
end
writer.FrameRate = cfg.frameRate;
open(writer);
cleanupObj = onCleanup(@() close_video_writer_safely(writer)); %#ok<NASGU>

target_size = [];
for i = 1:numel(cfg.phaseList)
    p = params;
    p.phase_over_T = cfg.phaseList(i);
    payload = compute_frame_payload(uvx, uvy, p.motionType, p.a_over_lambda, p.beta_max, ...
        p.sliceType, p.slicePos_over_lambda, p.phase_over_T, p.partType, fieldType);
    fig = create_plot_figure(payload, uvx, uvy, payload.rq_now_plot, p, fieldType);
    frame = image_output('export_frame', fig, cfg.resolution, target_size);
    close(fig);
    if isempty(target_size)
        target_size = [size(frame,1), size(frame,2)];
    end
    writeVideo(writer, frame);
end
end

function close_video_writer_safely(writer)
try
    close(writer);
catch
end
end

function payload = build_plot_payload(data, fieldType, partType, sliceType, tObs)
if strcmp(fieldType, 'tau')
    payload.F = tObs - data.tr;
    payload.U = [];
    payload.V = [];
    payload.isSigned = false;
    payload.isStream = false;
    payload.cbLabel = '$\tau=t-t_r$';
    payload.titleCore = '\tau';
    return;
end

block = data.(partType);
[Eu, Ev, En, planeLabel, normalLabel] = plane_components(block.Ex, block.Ey, block.Ez, sliceType);
[Bu, Bv, Bn, ~, ~] = plane_components(block.Bx, block.By, block.Bz, sliceType);

Emag = sqrt(max(block.Ex.^2 + block.Ey.^2 + block.Ez.^2, 0));
Bmag = sqrt(max(block.Bx.^2 + block.By.^2 + block.Bz.^2, 0));

Sx = block.Ey .* block.Bz - block.Ez .* block.By;
Sy = block.Ez .* block.Bx - block.Ex .* block.Bz;
Sz = block.Ex .* block.By - block.Ey .* block.Bx;
[~, ~, ~, SplaneLabel, ~] = plane_components(Sx, Sy, Sz, sliceType);

rad = data.rad;
Srx = rad.Ey .* rad.Bz - rad.Ez .* rad.By;
Sry = rad.Ez .* rad.Bx - rad.Ex .* rad.Bz;
Srz = rad.Ex .* rad.By - rad.Ey .* rad.Bx;
[Sru, Srv, ~, ~, ~] = plane_components(Srx, Sry, Srz, sliceType);

switch fieldType
    case 'E_in'
        payload.F = hypot(Eu, Ev);
        payload.U = [];
        payload.V = [];
        payload.isSigned = false;
        payload.isStream = false;
        payload.cbLabel = sprintf('$|E_{%s}|$', planeLabel);
        payload.titleCore = sprintf('E_{%s}', planeLabel);
    case 'E_n'
        payload.F = En;
        payload.U = [];
        payload.V = [];
        payload.isSigned = true;
        payload.isStream = false;
        payload.cbLabel = sprintf('$E_{%s}$', normalLabel);
        payload.titleCore = sprintf('E_{%s}', normalLabel);
    case 'E_mag'
        payload.F = Emag;
        payload.U = [];
        payload.V = [];
        payload.isSigned = false;
        payload.isStream = false;
        payload.cbLabel = '$|E|$';
        payload.titleCore = 'E';
    case 'B_in'
        payload.F = hypot(Bu, Bv);
        payload.U = [];
        payload.V = [];
        payload.isSigned = false;
        payload.isStream = false;
        payload.cbLabel = sprintf('$|B_{%s}|$', planeLabel);
        payload.titleCore = sprintf('B_{%s}', planeLabel);
    case 'B_n'
        payload.F = Bn;
        payload.U = [];
        payload.V = [];
        payload.isSigned = true;
        payload.isStream = false;
        payload.cbLabel = sprintf('$B_{%s}$', normalLabel);
        payload.titleCore = sprintf('B_{%s}', normalLabel);
    case 'B_mag'
        payload.F = Bmag;
        payload.U = [];
        payload.V = [];
        payload.isSigned = false;
        payload.isStream = false;
        payload.cbLabel = '$|B|$';
        payload.titleCore = 'B';
    case 'S_stream'
        payload.F = hypot(Sru, Srv);
        payload.U = Sru;
        payload.V = Srv;
        payload.isSigned = false;
        payload.isStream = true;
        payload.cbLabel = sprintf('$|S_{%s}|$', SplaneLabel);
        payload.titleCore = sprintf('S_{%s}', SplaneLabel);
    case 'E_stream'
        payload.F = hypot(Eu, Ev);
        payload.U = Eu;
        payload.V = Ev;
        payload.isSigned = false;
        payload.isStream = true;
        payload.cbLabel = sprintf('$|E_{%s}|$', planeLabel);
        payload.titleCore = sprintf('E_{%s}', planeLabel);
    case 'B_stream'
        payload.F = hypot(Bu, Bv);
        payload.U = Bu;
        payload.V = Bv;
        payload.isSigned = false;
        payload.isStream = true;
        payload.cbLabel = sprintf('$|B_{%s}|$', planeLabel);
        payload.titleCore = sprintf('B_{%s}', planeLabel);
    otherwise
        error('Unknown fieldType.');
end
end

function fig = create_plot_figure(payload, uvx, uvy, rq_now_plot, params, fieldType)
fig = image_output('hidden_figure', 'Position', [100 100 900 750]);
ax = axes('Parent', fig);
render_plot(ax, payload, uvx, uvy, rq_now_plot, params, fieldType);
end

function render_plot(ax, payload, uvx, uvy, rq_now_plot, params, fieldType)
cla(ax, 'reset');
hold(ax, 'on');

if payload.isStream
    C = process_field(payload.F, false, params.cmapMode);
    draw_colored_streamlines(ax, uvx, uvy, payload.U, payload.V, C, rq_now_plot, params.sliceType, params.a_over_lambda, fieldType);
    draw_trajectory(ax, params.motionType, params.sliceType, params.a_over_lambda);
    draw_charge_marker(ax, rq_now_plot, params.sliceType);
    axis(ax, 'image');
    xlim(ax, [uvx(1), uvx(end)]);
    ylim(ax, [uvy(1), uvy(end)]);
    set(ax, 'YDir', 'normal', 'Color', 'w');
    box(ax, 'on');
    [cmin, cmax] = finite_minmax(C);
    if ~isfinite(cmin) || ~isfinite(cmax) || cmin == cmax
        cmin = 0; cmax = 1;
    end
    render_result('colorbar', ax, 'Limits', [cmin cmax], 'Label', payload.cbLabel);
else
    G = process_field(payload.F, payload.isSigned, params.cmapMode);
    A = double(isfinite(G));
    G(~isfinite(G)) = NaN;
    imagesc(ax, uvx, uvy, G, 'AlphaData', A);
    axis(ax, 'image');
    xlim(ax, [uvx(1), uvx(end)]);
    ylim(ax, [uvy(1), uvy(end)]);
    set(ax, 'YDir', 'normal', 'Color', 'w');
    draw_trajectory(ax, params.motionType, params.sliceType, params.a_over_lambda);
    draw_charge_marker(ax, rq_now_plot, params.sliceType);
    box(ax, 'on');
    if payload.isSigned
        render_result('colorbar', ax, 'AutoSymmetric', true, 'Data', G, 'Label', payload.cbLabel);
    else
        [cmin, cmax] = finite_minmax(G);
        if ~isfinite(cmin) || ~isfinite(cmax) || cmin == cmax
            cmin = 0; cmax = 1;
        end
        render_result('colorbar', ax, 'Limits', [cmin cmax], 'Label', payload.cbLabel);
    end
end

[xLabel, yLabel, ~] = axis_labels(params.sliceType);
apply_tex_style(ax, ...
    'Title', compose_title(payload.titleCore, params.motionType, params.partType), ...
    'XLabel', xLabel, 'YLabel', yLabel, ...
    'Box', 'on');
end

function titleStr = compose_title(titleCore, motionType, partType)
switch motionType
    case 'circular'
        motionToken = '\mathrm{circ}';
    case 'harmonic'
        motionToken = '\mathrm{harm}';
    otherwise
        motionToken = '';
end

switch partType
    case 'tot'
        partToken = '\mathrm{tot}';
    case 'vel'
        partToken = '\mathrm{vel}';
    case 'rad'
        partToken = '\mathrm{rad}';
    otherwise
        partToken = '';
end

titleStr = ['$' motionToken ' - ' partToken ' \; ' titleCore '$'];
end

function draw_colored_streamlines(ax, xv, yv, U, V, C, rq_now_plot, sliceType, a0, fieldType)
U0 = real(U); V0 = real(V);
U0(~isfinite(U0)) = 0;
V0(~isfinite(V0)) = 0;

mag = hypot(U0, V0);
magRef = finite_quantile(mag, 0.98);
if ~isfinite(magRef) || magRef <= 0
    magRef = finite_max(mag);
end
if isfinite(magRef) && magRef > 0
    Uplot = U0 ./ max(mag, magRef*0.02);
    Vplot = V0 ./ max(mag, magRef*0.02);
else
    Uplot = U0;
    Vplot = V0;
end

[u0, v0] = project_to_slice(rq_now_plot(1), rq_now_plot(2), rq_now_plot(3), sliceType);

if strcmp(fieldType, 'S_stream')
    nSeed = 72;
    rSeed = 0.30*a0 + 0.08;
else
    nSeed = 60;
    rSeed = 0.18*a0 + 0.04;
end

th = linspace(0, 2*pi, nSeed+1); th(end) = [];
sx = u0 + rSeed*cos(th);
sy = v0 + rSeed*sin(th);

S = stream2(xv, yv, Uplot, Vplot, sx, sy);
for i = 1:numel(S)
    xy = S{i};
    if size(xy,1) < 2
        continue;
    end
    xi = xy(:,1);
    yi = xy(:,2);
    ci = interp2(xv, yv, C, xi, yi, 'linear', NaN);
    good = isfinite(ci);
    if nnz(good) < 2
        continue;
    end
    xi = xi(good); yi = yi(good); ci = ci(good);
    surface(ax, [xi xi], [yi yi], zeros(numel(xi),2), [ci ci], ...
        'FaceColor', 'none', 'EdgeColor', 'interp', 'LineWidth', 1.25);
end
end

function draw_trajectory(ax, motionType, sliceType, a0)
s = linspace(0, 2*pi, 800);
if strcmp(motionType, 'circular')
    x = a0*cos(s); y = a0*sin(s); z = 0*s;
else
    x = 0*s; y = 0*s; z = a0*cos(s);
end
[u, v] = project_to_slice(x, y, z, sliceType);
plot(ax, u, v, 'k', 'LineWidth', 1.5);
end

function draw_charge_marker(ax, rq_now_plot, sliceType)
[u0, v0] = project_to_slice(rq_now_plot(1), rq_now_plot(2), rq_now_plot(3), sliceType);
plot(ax, u0, v0, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 6);
end

function G = process_field(F, isSigned, cmapMode) %#ok<INUSD>
%PROCESS_FIELD Log-scaled display only.
G = real(F);
G(~isfinite(G)) = NaN;
if ~isSigned
    G(G < 0) = 0;
end

if isSigned
    A = abs(G);
    ref = finite_quantile(A, 0.998);
    if ~isfinite(ref) || ref <= 0
        ref = finite_max(A);
    end
    if isfinite(ref) && ref > 0
        A = log1p(40 * min(A, ref) / ref) / log1p(40);
    end
    G = sign(G) .* A;
else
    ref = finite_quantile(G, 0.998);
    if ~isfinite(ref) || ref <= 0
        ref = finite_max(G);
    end
    if isfinite(ref) && ref > 0
        G = log1p(40 * min(G, ref) / ref) / log1p(40);
    end
end
end

function [X, Y, Z] = make_slice_grid(U, V, sliceType, slicePos)
switch sliceType
    case 'xy'
        X = U; Y = V; Z = slicePos * ones(size(U));
    case 'xz'
        X = U; Y = slicePos * ones(size(U)); Z = V;
    case 'yz'
        X = slicePos * ones(size(U)); Y = U; Z = V;
    otherwise
        error('Unknown sliceType.');
end
end

function [xLabel, yLabel, normalLabel] = axis_labels(sliceType)
switch sliceType
    case 'xy'
        xLabel = '$x/\lambda$'; yLabel = '$y/\lambda$'; normalLabel = 'z';
    case 'xz'
        xLabel = '$x/\lambda$'; yLabel = '$z/\lambda$'; normalLabel = 'y';
    case 'yz'
        xLabel = '$y/\lambda$'; yLabel = '$z/\lambda$'; normalLabel = 'x';
    otherwise
        error('Unknown sliceType.');
end
end

function [u, v] = project_to_slice(x, y, z, sliceType)
switch sliceType
    case 'xy'
        u = x; v = y;
    case 'xz'
        u = x; v = z;
    case 'yz'
        u = y; v = z;
    otherwise
        error('Unknown sliceType.');
end
end

function [Uin, Vin, Ncomp, planeLabel, normalLabel] = plane_components(Fx, Fy, Fz, sliceType)
switch sliceType
    case 'xy'
        Uin = Fx; Vin = Fy; Ncomp = Fz; planeLabel = 'xy'; normalLabel = 'z';
    case 'xz'
        Uin = Fx; Vin = Fz; Ncomp = Fy; planeLabel = 'xz'; normalLabel = 'y';
    case 'yz'
        Uin = Fy; Vin = Fz; Ncomp = Fx; planeLabel = 'yz'; normalLabel = 'x';
    otherwise
        error('Unknown sliceType.');
end
end


function c = local_cellstr(x)
if isempty(x)
    c = {};
elseif iscell(x)
    c = cellfun(@char, x(:).', 'UniformOutput', false);
elseif isstring(x)
    c = cellstr(x(:).');
else
    c = {char(string(x))};
end
end

function name = make_output_basename(params, fieldType)
% Semantic image filenames; metadata goes to parameters.txt.
name = moving_charge_field_name(fieldType);
end

function name = make_video_basename(params, fieldType)
% Semantic video filenames; metadata goes to parameters.txt.
name = moving_charge_field_name(fieldType);
end

function name = moving_charge_field_name(fieldType)
switch char(string(fieldType))
    case 'E_in',      name = 'electric_in_plane_magnitude';
    case 'E_n',       name = 'electric_normal_component';
    case 'E_mag',     name = 'electric_field_magnitude';
    case 'B_in',      name = 'magnetic_in_plane_magnitude';
    case 'B_n',       name = 'magnetic_normal_component';
    case 'B_mag',     name = 'magnetic_field_magnitude';
    case 'S_stream',  name = 'poynting_streamlines';
    case 'tau',       name = 'retarded_time_delay';
    case 'E_stream',  name = 'electric_field_streamlines';
    case 'B_stream',  name = 'magnetic_field_streamlines';
    otherwise,        name = image_output('slug', fieldType);
end
end

function s = fmt_num_name(v)
s = sprintf('%.6f', v);
s = regexprep(s, '0+$', '');
s = regexprep(s, '\.$', '');
if strcmp(s, '-0')
    s = '0';
end
end

function m = finite_max(A)
a = A(isfinite(A));
if isempty(a)
    m = NaN;
else
    m = max(a(:));
end
end

function [mn, mx] = finite_minmax(A)
a = A(isfinite(A));
if isempty(a)
    mn = NaN;
    mx = NaN;
else
    mn = min(a(:));
    mx = max(a(:));
end
end

function q = finite_quantile(A, p)
a = A(isfinite(A));
if isempty(a)
    q = NaN;
    return;
end
a = sort(a(:));
idx = max(1, min(numel(a), round(p * numel(a))));
q = a(idx);
end

function params = local_default_params()
%LOCAL_DEFAULT_PARAMS Default moving-charge parameter struct.
params.motionType = 'circular';
params.a_over_lambda = 1.2;
params.beta_max = 0.6;
params.sliceType = 'xy';
params.slicePos_over_lambda = 0.0;
params.phase_over_T = 0.0;
params.partType = 'tot';
params.fieldType = 'E_mag';
params.outputMode = 'image';
params.cmapMode = 'log';
params.exportAllFields = false;
params.viewMode = 'custom';
params.customFields = {'E_mag','B_mag','E_stream','S_stream'};
params.selectedFields = params.customFields;
end

function params = local_normalize_params(params)
%LOCAL_NORMALIZE_PARAMS Normalize and validate the parameter struct.
base = local_default_params();
fields = fieldnames(base);
for k = 1:numel(fields)
    name = fields{k};
    if ~isfield(params, name) || isempty(params.(name))
        params.(name) = base.(name);
    end
end
text_fields = {'motionType','sliceType','partType','fieldType','outputMode','cmapMode','viewMode'};
for k = 1:numel(text_fields)
    key = text_fields{k};
    if isstring(params.(key))
        params.(key) = char(params.(key));
    end
end
num_fields = {'a_over_lambda','beta_max','slicePos_over_lambda','phase_over_T'};
for k = 1:numel(num_fields)
    key = num_fields{k};
    params.(key) = double(params.(key));
end
params.exportAllFields = logical(params.exportAllFields);
params.customFields = local_cellstr(params.customFields);
params.selectedFields = local_cellstr(params.selectedFields);
local_validate_params(params);
end

function local_validate_params(params)
if ~any(strcmp(params.motionType, {'circular','harmonic'}))
    error('motionType must be ''circular'' or ''harmonic''.');
end
if ~any(strcmp(params.sliceType, {'xy','xz','yz'}))
    error('sliceType must be ''xy'', ''xz'', or ''yz''.');
end
if ~any(strcmp(params.partType, {'tot','vel','rad'}))
    error('partType must be ''tot'', ''vel'', or ''rad''.');
end
if ~any(strcmp(params.fieldType, {'E_in','E_n','E_mag','B_in','B_n','B_mag','S_stream','tau','E_stream','B_stream'}))
    error('Invalid fieldType.');
end
if ~isscalar(params.a_over_lambda) || ~isfinite(params.a_over_lambda) || params.a_over_lambda <= 0
    error('a_over_lambda must be a positive finite scalar.');
end
if ~isscalar(params.beta_max) || ~isfinite(params.beta_max) || params.beta_max <= 0 || params.beta_max >= 1
    error('beta_max must satisfy 0 < beta_max < 1.');
end
if ~isscalar(params.slicePos_over_lambda) || ~isfinite(params.slicePos_over_lambda)
    error('slicePos_over_lambda must be a finite scalar.');
end
if ~isscalar(params.phase_over_T) || ~isfinite(params.phase_over_T)
    error('phase_over_T must be a finite scalar.');
end
if ~any(strcmp(params.outputMode, {'image','video','image+video'}))
    error('outputMode must be ''image'', ''video'', or ''image+video''.');
end
if ~any(strcmp(params.cmapMode, {'log','linear'}))
    error('cmapMode must be ''log'' or ''linear''.');
end
end
