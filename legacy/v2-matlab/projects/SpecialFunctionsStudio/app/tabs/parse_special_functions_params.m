function out = parse_special_functions_params(action, varargin)
switch lower(char(action))
    case {'catalog','families'}
        if nargin < 2
            out = local_catalog_query();
        else
            out = local_catalog_query(varargin{:});
        end
    case {'family','variant'}
        out = local_catalog_query(varargin{:});
    case {'dispatch','compute'}
        params = varargin{1};
        if numel(varargin) >= 2 && ~isempty(varargin{2})
            f = varargin{2};
            if ischar(f) || isstring(f)
                f = str2func(char(f));
            end
        else
            v = local_catalog_query(params.family, params.variant);
            f = str2func(v.FunctionName);
        end
        out = local_dispatch(params, f);
    case {'render_from_params','render'}
        out = local_render_from_params(varargin{:});
    otherwise
        error('Unknown parse_special_functions_params action: %s', action);
end
end

function out = local_catalog_query(family_key, variant_key)
%SPECIAL_FUNCTION_CATALOG Return available families and computational variants.

C = local_catalog();
if nargin < 1 || isempty(family_key)
    out = C;
    return;
end

family_key = local_key_text(family_key, 'family');
keys = {C.Key};
idx = local_first_match(keys, family_key);
assert(idx > 0, 'Unknown family: %s', family_key);
fam = C(idx);

if nargin < 2 || isempty(variant_key)
    out = fam;
    return;
end

variant_key = local_key_text(variant_key, 'variant');
variant_keys = {fam.Variants.Key};
idx2 = local_first_match(variant_keys, variant_key);
assert(idx2 > 0, 'Unknown variant: %s', variant_key);
out = fam.Variants(idx2);
end

function key = local_key_text(value, label)
if isstruct(value)
    if isfield(value, 'Key')
        value = value.Key;
    elseif isfield(value, 'Value')
        value = value.Value;
    else
        error('Invalid %s selector: expected a key string, got a struct without Key.', label);
    end
elseif iscell(value) && numel(value) == 1
    value = value{1};
end
key = char(string(value));
end

function idx = local_first_match(keys, key)
idx = 0;
for ii = 1:numel(keys)
    if strcmp(char(string(keys{ii})), key)
        idx = ii;
        return;
    end
end
end

function C = local_catalog()
C = struct('Key', {}, 'Name', {}, 'DefaultXRange', {}, 'Variants', {});

C(1) = make_family('bessel', 'Bessel', [0 20], [ ...
    make_variant('j', 'Bessel J', 'bessel_j_result', '1d', {'nu'}, {'0:5'}, ...
        {'Examples: (2), (0:5), (0,2,4).'}), ...
    make_variant('y', 'Bessel Y', 'bessel_y_result', '1d', {'nu'}, {'0:5'}, ...
        {'Examples: (2), (0:5).'}), ...
    make_variant('i', 'Modified Bessel I', 'bessel_i_result', '1d', {'nu'}, {'0:5'}, ...
        {'Examples: (2), (0:5).'}), ...
    make_variant('k', 'Modified Bessel K', 'bessel_k_result', '1d', {'nu'}, {'0:5'}, ...
        {'Examples: (2), (0:5).'}) ]);

C(end+1) = make_family('spherical_bessel', 'Spherical Bessel', [0.05 20], [ ...
    make_variant('j', 'Spherical Bessel j', 'spherical_bessel_j_result', '1d', {'n'}, {'0:5'}, ...
        {'Examples: (2), (0:5). Integer order is used.'}), ...
    make_variant('y', 'Spherical Bessel y', 'spherical_bessel_y_result', '1d', {'n'}, {'0:5'}, ...
        {'Examples: (2), (0:5). Integer order is used.'}) ]);

C(end+1) = make_family('airy', 'Airy', [-10 5], [ ...
    make_variant('ai', 'Airy Ai', 'airy_ai_result', '1d', {}, {}, {'No parameter input is needed.'}), ...
    make_variant('bi', 'Airy Bi', 'airy_bi_result', '1d', {}, {}, {'No parameter input is needed.'}), ...
    make_variant('aip', 'Airy Ai derivative', 'airy_ai_derivative_result', '1d', {}, {}, {'No parameter input is needed.'}), ...
    make_variant('bip', 'Airy Bi derivative', 'airy_bi_derivative_result', '1d', {}, {}, {'No parameter input is needed.'}) ]);

C(end+1) = make_family('lane_emden', 'Lane-Emden', [0 10], [ ...
    make_variant('theta', 'Lane-Emden theta', 'lane_emden_result', '1d', {'n'}, {'0,1,1.5,3,5'}, ...
        {'Examples: (3), (0,1,1.5,3,5).'}) ]);

C(end+1) = make_family('elliptic', 'Elliptic Integrals', [0 0.999], [ ...
    make_variant('k', 'Complete elliptic K', 'complete_elliptic_k_result', '1d', {}, {}, ...
        {'No parameter input; the x-axis is the Legendre parameter m.'}), ...
    make_variant('e', 'Complete elliptic E', 'complete_elliptic_e_result', '1d', {}, {}, ...
        {'No parameter input; the x-axis is the Legendre parameter m.'}), ...
    make_variant('f_inc', 'Incomplete elliptic F', 'incomplete_elliptic_f_result', '1d', {'m'}, {'0.5'}, ...
        {'Examples: (0.5), (0,0.5,0.9). The x-axis is phi.'}), ...
    make_variant('e_inc', 'Incomplete elliptic E', 'incomplete_elliptic_e_result', '1d', {'m'}, {'0.5'}, ...
        {'Examples: (0.5), (0,0.5,0.9). The x-axis is phi.'}), ...
    make_variant('pi_inc', 'Incomplete elliptic Pi', 'incomplete_elliptic_pi_result', '1d', {'n', 'm'}, {'0.2', '0.5'}, ...
        {'Examples: (0.2,0.5), (0.1:0.4,0.5), ((0.1,0.3),(0.2,0.6)).'}) ]);

C(end+1) = make_family('jacobi_elliptic', 'Jacobi Elliptic', [0 12], [ ...
    make_variant('sn', 'Jacobi sn', 'jacobi_sn_result', '1d', {'m'}, {'0,0.5,0.95'}, ...
        {'Examples: (0.5), (0,0.5,0.95).'}), ...
    make_variant('cn', 'Jacobi cn', 'jacobi_cn_result', '1d', {'m'}, {'0,0.5,0.95'}, ...
        {'Examples: (0.5), (0,0.5,0.95).'}), ...
    make_variant('dn', 'Jacobi dn', 'jacobi_dn_result', '1d', {'m'}, {'0,0.5,0.95'}, ...
        {'Examples: (0.5), (0,0.5,0.95).'}) ]);

C(end+1) = make_family('hypergeometric', 'Hypergeometric', [-0.9 0.9], [ ...
    make_variant('2f1', 'Gauss 2F1', 'gauss_hypergeometric_2f1_result', '1d', {'a', 'b', 'c'}, {'0.5', '1', '2'}, ...
        {'Examples: (0.5,1,2), (0.5:2,1,2), (1:4,(2,5,7),4).'}) ]);

C(end+1) = make_family('spherical_harmonics', 'Spherical Harmonics', [0 1], [ ...
    make_variant('ylm', 'Spherical harmonic Y', 'spherical_harmonic_surface_result', '3d', {'l', 'm'}, {'0:3', '-3:3'}, ...
        {'Examples: (3,1), (0:3,-3:3), (1:4,(0,1,2)). Invalid |m| > l tuples are dropped.'}) ]);

C(end+1) = make_family('vector_spherical_harmonics', 'Vector Spherical Harmonics', [0 1], [ ...
    make_variant('xlm', 'Toroidal X', 'vector_spherical_harmonic_x_result', '3d', {'l', 'm'}, {'0:3', '-3:3'}, ...
        {'Examples: (2,1), (0:3,-3:3). Invalid |m| > l tuples are dropped.'}), ...
    make_variant('psilm', 'Surface-gradient Psi', 'vector_spherical_harmonic_psi_result', '3d', {'l', 'm'}, {'0:3', '-3:3'}, ...
        {'Examples: (2,1), (0:3,-3:3). Invalid |m| > l tuples are dropped.'}), ...
    make_variant('radial', 'Radial rhat Y', 'vector_spherical_harmonic_radial_result', '3d', {'l', 'm'}, {'0:3', '-3:3'}, ...
        {'Examples: (2,1), (0:3,-3:3). Invalid |m| > l tuples are dropped.'}) ]);
end

function family = make_family(key, name, default_xrange, variants)
family = struct('Key', key, 'Name', name, 'DefaultXRange', default_xrange, 'Variants', variants);
end

function variant = make_variant(key, name, function_name, plot_kind, param_labels, param_defaults, param_hint)
variant = struct( ...
    'Key', key, ...
    'Name', name, ...
    'FunctionName', function_name, ...
    'PlotKind', plot_kind, ...
    'ParamLabels', {param_labels}, ...
    'ParamDefaults', {param_defaults}, ...
    'ParamHint', {param_hint});
end

function limits = local_common_limits_cell(items)
lim = image_output('common_3d_limits', items);
if iscell(lim)
    limits = lim;
elseif isnumeric(lim) && numel(lim) >= 6
    limits = {lim(1:2), lim(3:4), lim(5:6)};
else
    limits = {[-1 1], [-1 1], [-1 1]};
end
end

function result = local_dispatch(params,function_handle)
result = function_handle(params);
result.family = params.family;
result.variant = params.variant;
if isfield(params,'layout_text')
    result.layout_text = params.layout_text;
else
    result.layout_text = '';
end
end

function out = local_render_from_params(params)
if nargin < 1 || isempty(params)
    error('params is required.');
end
v = local_catalog_query(params.family, params.variant);
result = local_dispatch(params, str2func(v.FunctionName));
base_name = local_special_base_name(params, v, result);
export_after = false;
if isfield(params, 'output_dir') && ~isempty(params.output_dir)
    output_dir = char(string(params.output_dir));
    if exist(output_dir, 'dir') ~= 7
        mkdir(output_dir);
    end
else
    output_dir = image_output('clear_cache', pwd, 'special_functions_reproduce');
    export_after = true;
end
if isfield(params, 'crop')
    crop = params.crop;
else
    crop = struct('mode', 'auto', 'y_range', []);
end
if isfield(params, 'render_options')
    render_options = params.render_options;
else
    render_options = struct('legend_location', 'northwest');
end
if isfield(params, 'output_layout') && ~isempty(params.output_layout)
    output_layout = params.output_layout;
elseif isfield(params, 'layout_text') && ~isempty(params.layout_text)
    output_layout = params.layout_text;
else
    output_layout = 'auto';
end
if strcmp(result.kind, '3d')
    all_indices = 1:numel(result.items);
    if isfield(params, 'selected_preview_indices') && ~isempty(params.selected_preview_indices)
        indices = params.selected_preview_indices;
        indices = indices(indices >= 1 & indices <= numel(result.items));
        if isempty(indices)
            indices = all_indices;
        end
    else
        indices = all_indices;
    end
    common_limits = local_common_limits_cell(result.items);
    paths = cell(1, numel(indices));
    for kk = 1:numel(indices)
        k = indices(kk);
        single = result;
        single.items = result.items(k);
        single.layout_text = '1';
        single.common_limits = common_limits;
        if isfield(result.items{k}, 'filename') && ~isempty(result.items{k}.filename)
            name = image_output('indexed_name', result.items{k}.filename, kk, '.png');
        else
            item_label = local_special_item_label(result.items{k}, params, v, k);
            name = image_output('indexed_name', [base_name '_' item_label], kk, '.png');
        end
        paths{kk} = fullfile(output_dir, name);
        render_result('render', single, paths{kk}, 'Crop', crop, 'DPI', 220, 'RenderOptions', render_options);
    end
    composite_path = '';
    if numel(paths) > 1
        composite_path = fullfile(output_dir, 'composite.png');
        image_output('compose_grid', paths, composite_path, 'Layout', output_layout);
    end
    if export_after
        info = image_output('export_bundle', pwd, 'special_functions', paths, ...
            'Params', params, 'Composite', numel(paths) > 1, 'Layout', output_layout);
        out = struct('result', result, 'output_dir', info.output_dir, 'files', {info.files}, 'composite_path', info.composite);
    else
        out = struct('result', result, 'output_dir', output_dir, 'files', {paths}, 'composite_path', composite_path);
    end
else
    if isfield(params, 'output_png') && ~isempty(params.output_png)
        output_png = char(string(params.output_png));
    else
        output_png = fullfile(output_dir, [base_name '.png']);
    end
    render_result('render', result, output_png, 'Crop', crop, 'DPI', 220, 'RenderOptions', render_options);
    if export_after
        info = image_output('export_bundle', pwd, 'special_functions', {output_png}, ...
            'Params', params, 'Composite', false);
        out = struct('result', result, 'output_png', info.files{1}, 'output_dir', info.output_dir, 'files', {info.files}, 'composite_path', info.composite);
    else
        out = struct('result', result, 'output_png', output_png, 'output_dir', output_dir, 'files', {{output_png}}, 'composite_path', '');
    end
end
end


function name = local_special_base_name(params, variant_info, result)
family = '';
variant = '';
if isfield(params, 'family'), family = char(string(params.family)); end
if isfield(params, 'variant'), variant = char(string(params.variant)); end
if nargin >= 2 && isstruct(variant_info)
    if isfield(variant_info, 'Key') && ~isempty(variant_info.Key), variant = char(string(variant_info.Key)); end
end
parts = {family, variant};
base = strjoin(parts(~cellfun(@isempty, parts)), '_');
base = image_output('slug', base);
if isempty(base) || strcmp(base, 'item')
    base = image_output('slug', local_get_field(result, 'title', 'special_function'));
end
name = base;
end

function label = local_special_item_label(item, params, variant_info, idx)
label = '';
if isfield(item, 'filename') && ~isempty(item.filename)
    [~, label] = fileparts(char(string(item.filename)));
end
if isempty(label) && isfield(item, 'title') && contains(char(string(item.title)), 'l=') && contains(char(string(item.title)), 'm=')
    t = char(string(item.title));
    toks = regexp(t, 'l\s*=\s*(-?\d+)\D+m\s*=\s*(-?\d+)', 'tokens', 'once');
    if ~isempty(toks)
        label = sprintf('l%s_m%s', toks{1}, toks{2});
    end
end
if isempty(label)
    label = image_output('clean_label', local_get_field(item, 'title', sprintf('item_%d', idx)));
end
label = image_output('slug', label);
if isempty(label) || strcmp(label, 'item')
    label = sprintf('item_%d', idx);
end
end

function v = local_get_field(s, field, fallback)
if isstruct(s) && isfield(s, field) && ~isempty(s.(field))
    v = s.(field);
else
    v = fallback;
end
end
