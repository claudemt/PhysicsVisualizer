function tab = create_domain_tab(tab_group, project_root, domain_key, domain_title, subtitle)
%CREATE_DOMAIN_TAB Build one CreativePlotStudio domain tab with unified layout.
% PhysicsVisualizer keeps the modern shared GUI chrome, while the actual
% artwork/fractal/nonlinear rendering scripts remain aligned with the original
% CreativePlotStudio core.

app_figure = ancestor(tab_group, 'figure');
catalog = get_domain_catalog(domain_key);

current_state = struct('rendered', false, 'last_signature', '', 'last_cache_file', '');
image_output('clear_cache', project_root, ['creative_' domain_key]);

ui = create_tab_layout(tab_group, domain_title, project_root, ...
    'Preview', 'single', ...
    'NotesTitle', 'notes', ...
    'NotesText', basic_notes(domain_title, ''), ...
    'NotesFile', fullfile(project_root, 'docs', 'physical_formulas.md'), ...
    'PreviewPadding', [8 8 8 12], ...
    'InitialMessage', ['render ' char(string(domain_title))]);

tab = ui.tab;
ax = ui.preview_axes;

left_grid = ui.control_grid;
left_grid.RowHeight = {'fit','fit','fit','fit'};
left_grid.ColumnWidth = {'1x'};
left_grid.Padding = [8 8 8 8];
left_grid.RowSpacing = 8;

category_names = {catalog.category};

category_section = create_control_panel(left_grid, 'section', 'category', {'fit','fit'});
category_dd = create_control_panel(category_section.grid, 'dropdown', 'category', category_names, category_names{1}, 'Choose an artwork family.');
example_dd = create_control_panel(category_section.grid, 'dropdown', 'project', catalog(1).items, catalog(1).items{1}, 'Choose the concrete render script.');

style_section = create_control_panel(left_grid, 'section', 'style / variant', 1);
style_dd = create_control_panel(style_section.grid, 'dropdown', 'style', default_style_items(), 'default', ...
    'Optional variant passed to the original render.m script. Many projects ignore it; those that use it keep the original behavior.');

actions = create_control_panel(left_grid, 'section', 'actions', 1);
bind_workflow(actions.grid, app_figure, @render_project, @reset_project, @export_project, 'GenerateText', 'Render');

prepare_display_axes(ax, domain_title, subtitle);
try, axtoolbar(ax, {'rotate','pan','zoomin','zoomout','restoreview'}); catch, end

category_dd.ValueChangedFcn = @(~,~) sync_selection();
example_dd.ValueChangedFcn  = @(~,~) sync_notes_only_and_mark_dirty();
style_dd.ValueChangedFcn    = @(~,~) mark_dirty();

sync_selection();

    function sync_selection()
        idx = current_category_index();
        example_dd.Items = catalog(idx).items;
        example_dd.Value = catalog(idx).items{1};
        sync_notes_only_and_mark_dirty();
    end

    function sync_notes_only_and_mark_dirty()
        mark_dirty();
        ui.set_notes(basic_notes(category_dd.Value, example_dd.Value));
    end

    function mark_dirty()
        current_state.rendered = false;
        current_state.last_signature = '';
        current_state.last_cache_file = '';
        try, ax.UserData.rendered = false; catch, end
    end

    function render_project()
        cla(ax,'reset');
        prepare_display_axes(ax, domain_title, subtitle);
        render_path = current_render_path();
        if ~exist(render_path,'file')
            error('Core render file not found: %s', render_path);
        end
        image_output('run_core_script', render_path, ax, style_dd.Value);
        try, ax.PositionConstraint = 'outerposition'; catch, end
        try, drawnow limitrate; catch, end
        current_state.rendered = true;
        current_state.last_signature = '';
        current_state.last_cache_file = '';
        try, ax.UserData.rendered = true; catch, end
        ui.set_notes(basic_notes(category_dd.Value, example_dd.Value));
    end

    function reset_project()
        mark_dirty();
        prepare_display_axes(ax, domain_title, subtitle);
        ui.set_notes(basic_notes(category_dd.Value, example_dd.Value));
    end

    function export_project()
        if ~current_state.rendered
            render_project();
        end
        cache_dir = image_output('clear_cache', project_root, ['creative_export_' domain_key]);
        base = sprintf('%s_%s_%s', domain_key, category_dd.Value, example_dd.Value);
        if ~strcmp(style_dd.Value, 'default')
            base = sprintf('%s_%s', base, style_dd.Value);
        end
        out_file = image_output('save_figure', ax, cache_dir, image_output('indexed_name', base, 1, '.png'), 300);
        params = struct('domain', domain_key, ...
            'category', category_dd.Value, ...
            'project', example_dd.Value, ...
            'style', style_dd.Value, ...
            'view_signature', current_view_signature(ax));
        code = strjoin({ ...
            'export_dir = fileparts(mfilename(''fullpath''));', ...
            'project_root = fileparts(fileparts(export_dir));', ...
            'addpath(genpath(project_root));', ...
            sprintf('%% Re-run through the Creative Plot Studio GUI: %s / %s / %s / %s', ...
                domain_key, category_dd.Value, example_dd.Value, style_dd.Value)}, newline);
        image_output('export_bundle', project_root, ['creative_' domain_key], {out_file}, ...
            'Params', params, 'ReproduceCode', code, 'Composite', false);
    end

    function idx = current_category_index()
        idx = find(strcmp(category_dd.Value, category_names), 1, 'first');
        if isempty(idx), idx = 1; end
    end

    function render_path = current_render_path()
        idx = current_category_index();
        project_dir = fullfile(project_root, 'core', domain_key, catalog(idx).folder, image_output('slug', example_dd.Value));
        render_path = fullfile(project_dir, 'render.m');
    end

    function lines = basic_notes(category_name, project_name)
        if nargin < 1 || isempty(category_name), category_name = 'Creative plot'; end
        if nargin < 2 || isempty(project_name), project_name = 'choose a project from the list'; end
        lines = { ...
            sprintf('%s studio.', char(string(category_name))), ...
            sprintf('Current project: %s.', char(string(project_name))), ...
            'category chooses the broad collection: art scenes, fractals, or nonlinear patterns.', ...
            'project chooses the concrete core render.m script. Each script receives ax and style from the GUI.', ...
            'style changes color palette, camera/fractal preset, or rendering variant when the selected project supports it.', ...
            'Render draws into the preview axes. Use the axes toolbar to rotate, pan, zoom, then export the current view.', ...
            'The formula Notes file explains the design/algorithm families; this small box focuses on using the current tab.'};
    end
end

function items = default_style_items()
items = { ...
    'default','dark','electric','zoom','minimal','vibrant','neon','detailed','bright', ...
    'blue','warm','gold','teal','sunset','violet', ...
    'chocolate','vanilla','strawberry','matcha', ...
    'coolnight','warmmountains','monomoon', ...
    'deep zoom','seahorse valley','dragon','spiral','mitosis','worms'};
end

function prepare_display_axes(ax, title_text, subtitle)
cla(ax,'reset');
try, ax.FontName = 'Times New Roman'; catch, end
try, ax.BackgroundColor = [1 1 1]; catch, end
axis(ax,[0 1 0 1]);
axis(ax,'off');
text(ax,0.5,0.58,char(string(title_text)), ...
    'HorizontalAlignment','center', ...
    'FontName','Times New Roman', ...
    'FontWeight','bold', ...
    'FontSize',20, ...
    'Interpreter','none');
text(ax,0.5,0.49,char(string(subtitle)), ...
    'HorizontalAlignment','center', ...
    'FontName','Times New Roman', ...
    'FontSize',13, ...
    'Color',[0.35 0.35 0.35], ...
    'Interpreter','none');
text(ax,0.5,0.40,'Render, rotate if needed, then export the current view.', ...
    'HorizontalAlignment','center', ...
    'FontName','Times New Roman', ...
    'FontSize',13, ...
    'Color',[0.35 0.35 0.35], ...
    'Interpreter','none');
end

function sig = current_view_signature(ax)
parts = {};
try, parts{end+1} = mat2str(ax.CameraPosition, 6); catch, end
try, parts{end+1} = mat2str(ax.CameraTarget, 6); catch, end
try, parts{end+1} = mat2str(ax.CameraUpVector, 6); catch, end
try, parts{end+1} = mat2str(ax.CameraViewAngle, 6); catch, end
try, parts{end+1} = mat2str(ax.XLim, 6); catch, end
try, parts{end+1} = mat2str(ax.YLim, 6); catch, end
try, parts{end+1} = mat2str(ax.ZLim, 6); catch, end
try, parts{end+1} = mat2str(ax.View, 6); catch, end
try, parts{end+1} = char(ax.DataAspectRatioMode); catch, end
try, parts{end+1} = mat2str(ax.DataAspectRatio, 6); catch, end
try, parts{end+1} = char(ax.PlotBoxAspectRatioMode); catch, end
try, parts{end+1} = mat2str(ax.PlotBoxAspectRatio, 6); catch, end
sig = strjoin(parts,'|');
end
