function result = run_chladni_generation(project_root, params)
%RUN_CHLADNI_GENERATION Unified backend for GUI-triggered figure generation.

if nargin < 1 || isempty(project_root)
    project_root = pwd;
end

storage_root = fullfile(project_root, '.cache');
prepare_storage_root(storage_root);

folder_name = local_storage_folder_name(params);
storage_folder = fullfile(storage_root, char(folder_name));
prepare_output_folder(storage_folder);

domain_type = char(lower(string(params.type)));
if ~isfield(params, 'xi0') || isempty(params.xi0)
    params.xi0 = 0;
end

switch domain_type
    case {'rect', 'square'}
        if ~isfield(params, 'a') || isempty(params.a), params.a = 2.0; end
        if ~isfield(params, 'b') || isempty(params.b), params.b = 2.0 * params.xi0; end
        chladni_formula_rect(params.nu, params.k, params.n, params.normalize, storage_folder, params.boundary, params.a, params.b);
    case {'circ', 'circle'}
        chladni_formula_circ(params.nu, params.k, params.n, params.normalize, storage_folder, params.boundary, 0);
    case {'annulus', 'ring'}
        chladni_formula_circ(params.nu, params.k, params.n, params.normalize, storage_folder, params.boundary, params.xi0);
    otherwise
        error('Unknown domain type: %s', params.type);
end

result = struct();
result.storage_folder = storage_folder;
result.files = find_output_images(storage_folder);
end

function prepare_storage_root(storage_root)
if ~exist(storage_root, 'dir')
    mkdir(storage_root);
    return;
end

entries = dir(storage_root);
for i = 1:numel(entries)
    name = entries(i).name;
    if strcmp(name, '.') || strcmp(name, '..')
        continue;
    end
    full_path = fullfile(storage_root, name);
    if entries(i).isdir
        rmdir(full_path, 's');
    else
        delete(full_path);
    end
end
end

function folder_name = local_storage_folder_name(params)
domain_type = char(lower(string(params.type)));
boundary_tag = upper(strtrim(char(string(params.boundary))));
nu_tag = local_num_tag(params.nu);

switch domain_type
    case {'rect', 'square'}
        if ~isfield(params, 'xi0') || isempty(params.xi0)
            error('Rect runs require params.xi0 = b/a.');
        end
        folder_name = sprintf('rect-%s-nu%s-xi%s', boundary_tag, nu_tag, local_num_tag(params.xi0));
    case {'annulus', 'ring'}
        if ~isfield(params, 'xi0') || isempty(params.xi0)
            error('Annulus runs require params.xi0 = R0/R.');
        end
        folder_name = sprintf('annulus-%s-nu%s-xi%s', boundary_tag, nu_tag, local_num_tag(params.xi0));
    case {'circ', 'circle'}
        folder_name = sprintf('circ-%s-nu%s-xi%s', boundary_tag, nu_tag, local_num_tag(0));
    otherwise
        error('Unknown domain type: %s', params.type);
end
end

function tag = local_num_tag(x)
tag = sprintf('%.6g', x);
end

function prepare_output_folder(output_folder)
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
    return;
end

png_info = dir(fullfile(output_folder, '*.png'));
for i = 1:numel(png_info)
    delete(fullfile(output_folder, png_info(i).name));
end
end
