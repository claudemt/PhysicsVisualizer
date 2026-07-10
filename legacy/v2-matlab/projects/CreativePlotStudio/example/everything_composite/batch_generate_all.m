function batch_generate_all()
%BATCH_GENERATE_ALL Generate all CreativePlotStudio images and one preview composite.

example_root = fileparts(mfilename('fullpath'));
project_root = fileparts(fileparts(example_root));
repo_root = fileparts(fileparts(project_root));
addpath(example_root);
addpath(fullfile(repo_root, 'utils'));
addpath(genpath(fullfile(project_root, 'app')));
addpath(genpath(fullfile(project_root, 'core')));

domains = {'art', 'fractals', 'nonlinear'};
plot_defs = {};
for d = 1:numel(domains)
    domain = domains{d};
    catalog = get_domain_catalog(domain);
    for c = 1:numel(catalog)
        for i = 1:numel(catalog(c).items)
            name = catalog(c).items{i};
            slug = image_output('slug', name);
            rpath = fullfile(project_root, 'core', domain, catalog(c).folder, slug, 'render.m');
            if exist(rpath, 'file') ~= 2
                warning('Render file missing: %s', rpath);
                continue;
            end
            plot_defs(end+1, :) = {name, rpath, domain}; %#ok<AGROW>
        end
    end
end

n_total = size(plot_defs, 1);
fprintf('Found %d plot definitions.\n', n_total);

out_root = fullfile(example_root, 'output');
if exist(out_root, 'dir') ~= 7, mkdir(out_root); end
stamp = datestr(now, 'yyyymmdd_HHMMSS');
batch_dir = fullfile(out_root, ['creative_plot_studio_all_' stamp]);
mkdir(batch_dir);
indiv_dir = fullfile(batch_dir, 'individual');
mkdir(indiv_dir);

set(groot, 'DefaultFigureVisible', 'off');
restore_vis = onCleanup(@() set(groot, 'DefaultFigureVisible', 'on'));

png_paths = cell(n_total, 1);
for i = 1:n_total
    name = plot_defs{i, 1};
    rpath = plot_defs{i, 2};
    domain = plot_defs{i, 3};

    fig = figure('Visible', 'off', 'Color', 'w', ...
        'Position', [100 100 640 520], ...
        'MenuBar', 'none', 'ToolBar', 'none', ...
        'NumberTitle', 'off', 'Name', name);
    ax = axes('Parent', fig); %#ok<NASGU>
    style = 'default'; %#ok<NASGU>

    try
        run(rpath);
    catch ME
        warning('FAILED [%s] %s: %s', domain, name, ME.message);
        close(fig);
        continue;
    end

    indexed_name = sprintf('%02d_%s.png', i, image_output('slug', name));
    try
        out_path = image_output('save_figure', fig, indiv_dir, indexed_name, 200);
    catch ME
        warning('EXPORT FAILED [%s] %s: %s', domain, name, ME.message);
        close(fig);
        continue;
    end

    png_paths{i} = out_path;
    fprintf('[%3d/%3d] %s\n', i, n_total, name);
    close(fig);
end

png_paths = png_paths(~cellfun(@isempty, png_paths));
if isempty(png_paths)
    error('No images were rendered.');
end

preview_path = fullfile(batch_dir, 'preview_composite.png');
image_output('compose_grid', png_paths, preview_path, 'Layout', 'auto', 'Padding', 16);

fprintf('\nSaved to:\n  %s\n', batch_dir);
fprintf('  individual/\n');
fprintf('  preview_composite.png\n');
end
