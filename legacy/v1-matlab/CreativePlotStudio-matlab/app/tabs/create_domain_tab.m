function tab = create_domain_tab(tab_group, project_root, domain_key, domain_title, subtitle)
%CREATE_DOMAIN_TAB Build one domain tab: Art, Fractals, or Nonlinear.

app_figure = ancestor(tab_group, 'figure');
catalog = get_domain_catalog(domain_key);

current_state = struct( ...
    'rendered', false, ...
    'last_signature', '', ...
    'last_cache_file', '');

cache_dir = fullfile(project_root, '.cache');
if ~exist(cache_dir,'dir')
    mkdir(cache_dir);
end

tab = uitab(tab_group, 'Title', domain_title);

root = uigridlayout(tab, [1 2]);
root.ColumnWidth = {380, '1x'};
root.RowHeight = {'1x'};
root.Padding = [10 10 10 10];
root.ColumnSpacing = 10;

left_panel = uipanel(root, 'Title', [domain_title ' controls']);
left_panel.Layout.Row = 1;
left_panel.Layout.Column = 1;

left_grid = uigridlayout(left_panel, [7 1]);
left_grid.RowHeight = {'fit','fit','fit','fit','fit','fit','1x'};
left_grid.ColumnWidth = {'1x'};
left_grid.Padding = [8 8 8 8];
left_grid.RowSpacing = 8;

header = uilabel(left_grid, ...
    'Text', domain_title, ...
    'FontName', 'Times New Roman', ...
    'FontSize', 18, ...
    'FontAngle', 'italic', ...
    'FontWeight', 'bold');
header.Layout.Row = 1;
header.Layout.Column = 1;

subtitle_label = uilabel(left_grid, ...
    'Text', subtitle, ...
    'FontName', 'Times New Roman', ...
    'WordWrap', 'on');
subtitle_label.Layout.Row = 2;
subtitle_label.Layout.Column = 1;

category_panel = uipanel(left_grid, 'Title', 'category');
category_panel.Layout.Row = 3;
category_panel.Layout.Column = 1;
category_grid = uigridlayout(category_panel, [1 1]);
category_grid.Padding = [6 6 6 6];

category_names = cell(1,numel(catalog));
for k = 1:numel(catalog)
    category_names{k} = catalog(k).category;
end

category_dd = uidropdown(category_grid, ...
    'Items', category_names, ...
    'FontName', 'Times New Roman');
category_dd.Layout.Row = 1;
category_dd.Layout.Column = 1;
category_dd.Value = category_names{1};

example_panel = uipanel(left_grid, 'Title', 'project');
example_panel.Layout.Row = 4;
example_panel.Layout.Column = 1;
example_grid = uigridlayout(example_panel, [1 1]);
example_grid.Padding = [6 6 6 6];

example_dd = uidropdown(example_grid, ...
    'Items', catalog(1).items, ...
    'FontName', 'Times New Roman');
example_dd.Layout.Row = 1;
example_dd.Layout.Column = 1;
example_dd.Value = catalog(1).items{1};

style_panel = uipanel(left_grid, 'Title', 'style / variant');
style_panel.Layout.Row = 5;
style_panel.Layout.Column = 1;
style_grid = uigridlayout(style_panel, [1 1]);
style_grid.Padding = [6 6 6 6];

style_dd = uidropdown(style_grid, ...
    'Items', default_style_items(), ...
    'FontName', 'Times New Roman');
style_dd.Layout.Row = 1;
style_dd.Layout.Column = 1;
style_dd.Value = 'default';

actions_panel = uipanel(left_grid, 'Title', 'actions');
actions_panel.Layout.Row = 6;
actions_panel.Layout.Column = 1;
actions_grid = uigridlayout(actions_panel, [1 1]);
actions_grid.RowHeight = {32};
actions_grid.Padding = [6 6 6 6];

create_action_row(actions_grid, @render_project, @export_project);

spacer = uilabel(left_grid, 'Text', '');
spacer.Layout.Row = 7;
spacer.Layout.Column = 1;

right_grid = uigridlayout(root, [2 1]);
right_grid.Layout.Row = 1;
right_grid.Layout.Column = 2;
right_grid.RowHeight = {'1x', 150};
right_grid.ColumnWidth = {'1x'};
right_grid.Padding = [0 0 0 0];
right_grid.RowSpacing = 8;

preview_panel = uipanel(right_grid, 'Title', 'preview');
preview_panel.Layout.Row = 1;
preview_panel.Layout.Column = 1;

preview_grid = uigridlayout(preview_panel, [1 1]);
preview_grid.Padding = [4 4 4 4];

ax = uiaxes(preview_grid);
ax.Layout.Row = 1;
ax.Layout.Column = 1;

prepare_display_axes(ax, domain_title, subtitle);

notes_box = uitextarea(right_grid, ...
    'Editable', 'off', ...
    'FontName', 'Times New Roman', ...
    'FontSize', 13);
notes_box.Layout.Row = 2;
notes_box.Layout.Column = 1;

try
    axtoolbar(ax, {'rotate','pan','zoomin','zoomout','restoreview'});
catch
end

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
        [~, notes_path] = current_paths();
        notes_box.Value = read_note_lines(notes_path);
    end

    function mark_dirty()
        current_state.rendered = false;
        current_state.last_signature = '';
        current_state.last_cache_file = '';
        try
            ax.UserData.rendered = false;
        catch
        end
    end

    function render_project(~,~)
        with_progress(app_figure, ...
            'Rendering', ...
            ['Rendering ' example_dd.Value '...'], ...
            @do_render);
    end

    function do_render(~)
        cla(ax,'reset');
        prepare_display_axes(ax, domain_title, subtitle);

        [render_path, ~] = current_paths();

        if ~exist(render_path,'file')
            error('Core render file not found: %s', render_path);
        end

        style = style_dd.Value;

        run_core_script(render_path, ax, style);

        current_state.rendered = true;

        % A new render means old cached image may no longer represent the current scene,
        % especially for stochastic/generative plots.
        current_state.last_signature = '';
        current_state.last_cache_file = '';

        try
            ax.UserData.rendered = true;
        catch
        end

        sync_notes_only_no_dirty();
    end

    function sync_notes_only_no_dirty()
        [~, notes_path] = current_paths();
        notes_box.Value = read_note_lines(notes_path);
    end

    function export_project(~,~)
        with_progress(app_figure, ...
            'Exporting', ...
            'Exporting the current visible axes...', ...
            @do_export);
    end

    function do_export(~)
        if ~current_state.rendered
            do_render([]);
        end

        output_dir = fullfile(project_root,'output');
        if ~exist(output_dir,'dir')
            mkdir(output_dir);
        end

        if ~exist(cache_dir,'dir')
            mkdir(cache_dir);
        end

        filename = sprintf('%s_%s_%s_%s.png', ...
            slugify(domain_title), ...
            slugify(category_dd.Value), ...
            slugify(example_dd.Value), ...
            slugify(style_dd.Value));

        cache_file = fullfile(cache_dir, filename);
        out_file   = fullfile(output_dir, filename);

        sig = current_view_signature(ax);

        % True cache behavior:
        % Same project + same style + same camera/view -> copy cached PNG directly.
        if exist(cache_file,'file') && strcmp(current_state.last_signature, sig)
            copyfile(cache_file, out_file, 'f');
        else
            exportgraphics(ax, cache_file, 'Resolution', 300);
            current_state.last_signature = sig;
            current_state.last_cache_file = cache_file;
            copyfile(cache_file, out_file, 'f');
        end

        uialert(app_figure, ...
            sprintf('Image exported to:\n%s', out_file), ...
            'Export complete', ...
            'Icon', 'success');
    end

    function idx = current_category_index()
        idx = find(strcmp(category_dd.Value, category_names), 1, 'first');
        if isempty(idx)
            idx = 1;
        end
    end

    function [render_path, notes_path] = current_paths()
        idx = current_category_index();

        category_folder = catalog(idx).folder;
        project_folder = slugify(example_dd.Value);

        project_dir = fullfile( ...
            project_root, ...
            'core', ...
            domain_key, ...
            category_folder, ...
            project_folder);

        render_path = fullfile(project_dir, 'render.m');
        notes_path  = fullfile(project_dir, 'notes.txt');
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

ax.FontName = 'Times New Roman';
ax.BackgroundColor = [1 1 1];

axis(ax,[0 1 0 1]);
axis(ax,'off');

text(ax,0.5,0.58,title_text, ...
    'HorizontalAlignment','center', ...
    'FontName','Times New Roman', ...
    'FontWeight','bold', ...
    'FontSize',20);

text(ax,0.5,0.49,subtitle, ...
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

function lines = read_note_lines(notes_path)
if exist(notes_path,'file')
    raw = fileread(notes_path);
    lines = cellstr(splitlines(string(raw)));
else
    lines = {'No notes.txt found for this project.'};
end
end

function with_progress(fig, title_text, message_text, work_fcn)
dlg = uiprogressdlg(fig, ...
    'Title', title_text, ...
    'Message', message_text, ...
    'Indeterminate', 'on', ...
    'Cancelable', 'off');

drawnow;

try
    work_fcn(dlg);

    if isvalid(dlg)
        close(dlg);
    end
catch ME
    if isvalid(dlg)
        close(dlg);
    end

    uialert(fig, ...
        getReport(ME,'extended','hyperlinks','off'), ...
        'Operation failed');
end
end

function sig = current_view_signature(ax)
%CURRENT_VIEW_SIGNATURE Describe the current visible axes state.
%
% This is used to decide whether the cached PNG still matches the current
% view. If the user rotates, pans, or zooms, this signature changes.

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
