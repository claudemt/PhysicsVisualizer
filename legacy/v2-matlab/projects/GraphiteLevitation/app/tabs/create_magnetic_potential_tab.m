function tab = create_magnetic_potential_tab(tab_group, project_root)
%CREATE_MAGNETIC_POTENTIAL_TAB Visualization and inline multi-parameter scan.
% Scan is intentionally not a separate tab. Four physical inputs accept either
% a scalar or a tuple/list: d, W, chi, and P.

app_figure = ancestor(tab_group, 'figure');
defaults = parse_graphite_levitation_params('defaults');

ui = create_tab_layout(tab_group, 'visualization', project_root, ...
    'Preview', 'list', ...
    'PreviewListWidth', 330, ...
    'NotesText', local_notes(), ...
    'NotesFile', fullfile(project_root, 'docs', 'physical_formulas.md'));
tab = ui.tab;
try, ui.control_grid.RowHeight = {'fit','fit','fit','fit'}; catch, end

sample = create_control_panel(ui.control_grid, 'section', 'graphite sample', 5);
shape_dd = create_control_panel(sample.grid, 'dropdown', 'shape', parse_graphite_levitation_params('shape_items'), defaults.graphite.shape, [], 'circle or square graphite footprint.');
d_edit = create_control_panel(sample.grid, 'text', 'd [mm]', sprintf('%.4g', defaults.graphite.radius*1e3), [], 'Circle: d is the circle radius. Square: d is the side length. Supports 6 or (6,8,10).');
rotation_edit = create_control_panel(sample.grid, 'numeric', 'rotation [deg]', defaults.graphite.rotationDeg, [], 'In-plane rotation. Circle is unchanged by this value.');
W_edit = create_control_panel(sample.grid, 'text', 'W [um]', sprintf('%.4g', defaults.graphite.thickness*1e6), [], 'Graphite thickness. Supports 40 or (20,40,60).');
chi_edit = create_control_panel(sample.grid, 'text', 'chi [1e-4]', sprintf('%.4g', defaults.graphite.chiAbs*1e4), [], 'No-laser susceptibility magnitude in units of 1e-4. Supports 3 or (2.5,3,3.5).');

array = create_control_panel(ui.control_grid, 'section', 'compact checkerboard magnets', 3);
array_size_edit = create_control_panel(array.grid, 'text', 'array size', parse_graphite_levitation_params('format_array_size', defaults), [], 'Use keyboard-friendly syntax such as 6*6. Magnets are tightly packed.');
magnet_size_edit = create_control_panel(array.grid, 'text', 'magnet size [mm]', parse_graphite_levitation_params('format_magnet_size', defaults), [], 'Use a*b*c syntax, e.g. 10*10*10. Magnets are tightly packed.');
br_edit = create_control_panel(array.grid, 'numeric', 'Br [T]', defaults.magnet.Br, [], 'Remanence proxy used by the field model.');

laser = create_control_panel(ui.control_grid, 'section', 'laser susceptibility perturbation', 2);
spot_edit = create_control_panel(laser.grid, 'text', 'spot x*y [mm]', parse_graphite_levitation_params('format_spot', defaults), [], 'Sample-local laser spot position, e.g. 3*0.');
P_edit = create_control_panel(laser.grid, 'text', 'P', sprintf('%.4g', defaults.laser.alpha), [], 'Laser strength factor. P=0 means no laser. Supports 0.35 or (0,0.1,0.2).');

actions = create_control_panel(ui.control_grid, 'section', 'actions', 1);
state = struct('png_paths', {{}}, 'params', defaults, 'results', {{}});
bind_workflow(actions.grid, app_figure, @run_callback, @reset_callback, @export_callback);

    function [base, sweep] = read_params_and_sweep()
        base = parse_graphite_levitation_params('defaults');
        base.graphite.shape = shape_dd.Value;
        valsD = local_parse_vector(d_edit.Value, base.graphite.radius*1e3);
        valsW = local_parse_vector(W_edit.Value, base.graphite.thickness*1e6);
        valsChi = local_parse_vector(chi_edit.Value, base.graphite.chiAbs*1e4);
        valsP = local_parse_vector(P_edit.Value, base.laser.alpha);
        base.graphite.rotationDeg = rotation_edit.Value;
        nxy = parse_graphite_levitation_params('parse_size_pair', array_size_edit.Value);
        base.array.nx = nxy(1); base.array.ny = nxy(2);
        abc = parse_graphite_levitation_params('parse_size_triple_mm', magnet_size_edit.Value) * 1e-3;
        base.magnet.a = abc(1); base.magnet.b = abc(2); base.magnet.c = abc(3);
        base.magnet.Br = br_edit.Value;
        xy = parse_graphite_levitation_params('parse_point_pair', spot_edit.Value) * 1e-3;
        base.laser.spotX = xy(1); base.laser.spotY = xy(2);
        base = validate_graphite_levitation_params(base);
        sweep = struct('d', valsD, 'W', valsW, 'chi', valsChi, 'P', valsP);
    end

    function run_callback()
        [base, sweep] = read_params_and_sweep();
        combos = local_make_combinations(sweep);
        scanned = local_scanned_names(sweep);
        cache_dir = image_output('clear_cache', project_root, 'graphite_visualization');
        png_paths = {};
        results = cell(1, numel(combos));
        paramsForExport = base;
        paramsForExport.inlineScan = sweep;
        for i = 1:numel(combos)
            cfg = base;
            if strcmpi(char(string(cfg.graphite.shape)), 'circle')
                cfg.graphite.radius = combos(i).d * 1e-3;
                cfg.graphite.side = max(cfg.graphite.side, 2*cfg.graphite.radius);
            else
                cfg.graphite.side = combos(i).d * 1e-3;
                cfg.graphite.radius = max(cfg.graphite.radius, 0.5*cfg.graphite.side);
            end
            cfg.graphite.thickness = combos(i).W * 1e-6;
            cfg.graphite.chiAbs = combos(i).chi * 1e-4;
            cfg.laser.alpha = combos(i).P;
            cfg.laser.enabled = combos(i).P > 0;
            cfg = validate_graphite_levitation_params(cfg);
            result = compute_visualization_maps(cfg);
            result.variant = combos(i);
            result.variantSuffix = local_suffix(combos(i), scanned);
            result.variantLabel = local_label(combos(i), scanned);
            results{i} = result;
        end
        paramsForExport.equilibriumSolutions = local_equilibrium_summary_text(results, scanned);
        bundle = struct();
        bundle.results = results;
        bundle.params = paramsForExport;
        bundle.scanned = scanned;
        bundle.sweep = sweep;
        png_paths = render_graphite_levitation_result('visualization_bundle', bundle, cache_dir, 'Prefix', 'visualization');
        image_output('bind_preview_list', ui.preview_list, ui.preview_axes, png_paths);
        state.png_paths = png_paths;
        state.params = paramsForExport;
        state.results = results;
        ui.set_notes(local_run_notes(results, scanned));
    end

    function reset_callback()
        d = parse_graphite_levitation_params('defaults');
        shape_dd.Value = d.graphite.shape;
        d_edit.Value = sprintf('%.4g', d.graphite.radius*1e3);
        rotation_edit.Value = d.graphite.rotationDeg;
        W_edit.Value = sprintf('%.4g', d.graphite.thickness*1e6);
        chi_edit.Value = sprintf('%.4g', d.graphite.chiAbs*1e4);
        array_size_edit.Value = parse_graphite_levitation_params('format_array_size', d);
        magnet_size_edit.Value = parse_graphite_levitation_params('format_magnet_size', d);
        br_edit.Value = d.magnet.Br;
        spot_edit.Value = parse_graphite_levitation_params('format_spot', d);
        P_edit.Value = sprintf('%.4g', d.laser.alpha);
        state.png_paths = {};
        state.results = {};
        image_output('bind_preview_list', ui.preview_list, ui.preview_axes, {});
        ui.set_notes(local_notes());
    end

    function export_callback()
        if isempty(state.png_paths), error('Run before exporting.'); end
        paths = image_output('selected_preview_paths', ui.preview_list, state.png_paths);
        layout = image_output('preview_layout', ui, 'auto');
        exportParams = state.params;
        modelParams = exportParams;
        try
            if isfield(modelParams, 'equilibriumSolutions')
                modelParams = rmfield(modelParams, 'equilibriumSolutions');
            end
        catch
        end
        code = strjoin({ ...
            'export_dir = fileparts(mfilename(''fullpath''));', ...
            'project_root = fileparts(fileparts(export_dir));', ...
            'addpath(genpath(project_root));', ...
            params_output('reproduce_code', 'compute_visualization_maps', modelParams)}, newline);
        image_output('export_bundle', project_root, 'graphite_visualization', paths, ...
            'Params', exportParams, 'ReproduceCode', code, 'Composite', true, 'Layout', layout);
    end
end

function values = local_parse_vector(raw, fallback)
if isnumeric(raw)
    values = raw(:).';
else
    s = char(string(raw));
    s = strtrim(s);
    s = regexprep(s, '^\((.*)\)$', '$1');
    s = regexprep(s, '^\[(.*)\]$', '$1');
    s = strrep(s, '，', ',');
    if startsWith(lower(s), 'linspace')
        nums = sscanf(regexprep(s, '[^0-9eE+\-.]+', ' '), '%f').';
        if numel(nums) >= 3
            values = linspace(nums(1), nums(2), max(1, round(nums(3))));
        else
            values = nums;
        end
    elseif contains(s, ':') && isempty(regexp(s, '[,;\s]', 'once'))
        nums = sscanf(regexprep(s, ':', ' '), '%f').';
        if numel(nums) == 2
            values = nums(1):1:nums(2);
        elseif numel(nums) >= 3
            values = nums(1):nums(2):nums(3);
        else
            values = nums;
        end
    else
        values = sscanf(regexprep(s, '[,;\s]+', ' '), '%f').';
    end
end
if isempty(values) || any(~isfinite(values))
    values = fallback;
end
values = values(:).';
end

function combos = local_make_combinations(s)
nd = numel(s.d); nW = numel(s.W); nc = numel(s.chi); nP = numel(s.P);
combos = repmat(struct('d',0,'W',0,'chi',0,'P',0), 1, nd*nW*nc*nP);
k = 0;
for id = 1:nd
    for iW = 1:nW
        for ic = 1:nc
            for iP = 1:nP
                k = k + 1;
                combos(k).d = s.d(id);
                combos(k).W = s.W(iW);
                combos(k).chi = s.chi(ic);
                combos(k).P = s.P(iP);
            end
        end
    end
end
end

function names = local_scanned_names(s)
names = {};
if numel(s.d) > 1, names{end+1} = 'd'; end %#ok<AGROW>
if numel(s.W) > 1, names{end+1} = 'W'; end %#ok<AGROW>
if numel(s.chi) > 1, names{end+1} = 'chi'; end %#ok<AGROW>
if numel(s.P) > 1, names{end+1} = 'P'; end %#ok<AGROW>
end

function suffix = local_suffix(c, names)
if isempty(names), suffix = ''; return; end
parts = cell(1, numel(names));
for k = 1:numel(names)
    nm = names{k};
    parts{k} = [nm local_number_text(c.(nm))];
end
suffix = ['_' strjoin(parts, '_')];
end

function label = local_label(c, names)
if isempty(names)
    label = 'single run'; return;
end
parts = cell(1, numel(names));
for k = 1:numel(names)
    nm = names{k};
    parts{k} = sprintf('%s=%s', nm, local_number_text(c.(nm)));
end
label = strjoin(parts, ', ');
end

function txt = local_number_text(v)
txt = sprintf('%.12g', v);
end

function lines = local_notes()
lines = { ...
    'Seven figures are generated: 01 B^2, 02 potential compare, 03 susceptibility compare, 04 system views, and 05/06/07 force compares in x/y/z.', ...
    'Only d, W, chi, and P scan automatically. Enter 6 for one case or (6,8,10) for a scan. Multiple scanned fields form a Cartesian product.', ...
    'd is radius for circle and side length for square. W is thickness in um. chi is in 1e-4. P=0 means no laser.'};
end

function lines = local_run_notes(results, scanned)
lines = cell(0,1);
if isempty(results)
    lines = {'No result.'}; return;
end
if isempty(scanned)
    prefix = '';
else
    prefix = 'scan ';
end
for i = 1:numel(results)
    r = results{i};
    m = r.metrics;
    label = '';
    try, label = r.variantLabel; catch, end
    if isempty(label), label = sprintf('case %d', i); end
    lines{end+1,1} = sprintf('%s%s: displacement dx = %.3f mm, dy = %.3f mm, |d| = %.3f mm; angle theta_x = %.3f mrad, theta_y = %.3f mrad, |theta| = %.3f mrad.', ...
        prefix, label, 1e3*m.dxLaser, 1e3*m.dyLaser, 1e3*m.displacement, 1e3*m.thetaX, 1e3*m.thetaY, 1e3*m.thetaMag); %#ok<AGROW>
end
end



function text = local_equilibrium_summary_text(results, scanned)
%LOCAL_EQUILIBRIUM_SUMMARY_TEXT Export all grid-resolved stable poses as text.
% Keep this as a column cell array. MATLAB errors on [row; column] cell
% concatenation, which can happen after the first scan case if end+1 is used
% without an explicit row index.
lines = cell(0,1);
try
    if ~isempty(scanned)
        lines{end+1,1} = ['scanned = ' strjoin(scanned(:).', ', ')];
    end
catch
end
for ii = 1:numel(results)
    r = results{ii};
    label = '';
    try, label = r.variantLabel; catch, end
    if isempty(label), label = sprintf('case %d', ii); end
    lines{end+1,1} = sprintf('[%d] %s', ii, label); %#ok<AGROW>
    lines = [lines; local_pose_lines('no laser', r.metrics.posesOff)]; %#ok<AGROW>
    lines = [lines; local_pose_lines('with laser', r.metrics.posesOn)]; %#ok<AGROW>
end
text = strjoin(lines(:).', newline);
end

function lines = local_pose_lines(prefix, poses)
lines = cell(0,1);
try, n = poses.count; catch, n = 0; end
lines{end+1,1} = sprintf('  %s count = %d', prefix, n);
for jj = 1:n
    try
        lines{end+1,1} = sprintf('  %s #%d: x = %.6g mm, y = %.6g mm, z = %.6g mm, theta_x = %.6g mrad, theta_y = %.6g mrad, theta = %.6g mrad, U = %.12g', ...
            prefix, jj, 1e3*poses.x(jj), 1e3*poses.y(jj), 1e3*poses.z(jj), ...
            1e3*poses.thetaX(jj), 1e3*poses.thetaY(jj), 1e3*poses.thetaMag(jj), poses.U(jj));
    catch
    end
end
end
