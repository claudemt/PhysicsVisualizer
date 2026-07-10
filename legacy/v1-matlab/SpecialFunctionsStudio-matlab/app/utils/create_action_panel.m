function action = create_action_panel(parent, app_figure, generate_fcn, reset_fcn, export_fcn, varargin)
p = inputParser;
p.addParameter('Labels', {'Generate','Reset','Export'});
p.addParameter('ExtraButtons', {});
p.addParameter('ProgressTitle', 'Processing');
p.addParameter('ProgressMessage', 'Processing ...');
p.addParameter('UseProgress', true);
p.addParameter('ButtonHeight', 28);
p.addParameter('BoldFirst', true);
p.parse(varargin{:});
opt = p.Results;

extra = opt.ExtraButtons;
if isempty(extra)
    extra = {};
end
n_extra = local_extra_count(extra);
n = 3 + n_extra;

action = struct();
action.grid = uigridlayout(parent, [1 n]);
action.grid.ColumnWidth = repmat({'1x'}, 1, n);
action.grid.RowHeight = {opt.ButtonHeight};
action.grid.Padding = [0 0 0 0];
action.grid.ColumnSpacing = 6;

labels = opt.Labels;
if numel(labels) < 3
    labels = {'Generate','Reset','Export'};
end

action.generate = local_button(action.grid, labels{1}, generate_fcn, app_figure, opt, 1);
action.reset = local_button(action.grid, labels{2}, reset_fcn, app_figure, opt, 2);
action.export = local_button(action.grid, labels{3}, export_fcn, app_figure, opt, 3);
if opt.BoldFirst
    action.generate.FontWeight = 'bold';
end

action.extra = struct();
col = 4;
if isstruct(extra)
    names = fieldnames(extra);
    for k = 1:numel(names)
        name = names{k};
        spec = extra.(name);
        if iscell(spec)
            text = spec{1};
            fcn = spec{2};
        else
            text = name;
            fcn = spec;
        end
        action.extra.(matlab.lang.makeValidName(name)) = local_button(action.grid, text, fcn, app_figure, opt, col);
        col = col + 1;
    end
elseif iscell(extra)
    k = 1;
    while k <= numel(extra)
        if k < numel(extra)
            text = extra{k};
            fcn = extra{k+1};
            name = matlab.lang.makeValidName(char(string(text)));
            action.extra.(name) = local_button(action.grid, text, fcn, app_figure, opt, col);
            col = col + 1;
        end
        k = k + 2;
    end
end
end

function b = local_button(parent, label, fcn, app_figure, opt, col)
b = uibutton(parent, 'push', 'Text', char(string(label)));
b.Layout.Row = 1;
b.Layout.Column = col;
b.ButtonPushedFcn = @(~,~) local_run(fcn, app_figure, opt);
end

function local_run(fcn, app_figure, opt)
if isempty(fcn)
    return;
end
dlg = [];
cleanup_obj = [];
try
    if opt.UseProgress
        dlg = uiprogressdlg(app_figure, 'Title', opt.ProgressTitle, 'Message', opt.ProgressMessage, 'Indeterminate', 'on');
        cleanup_obj = onCleanup(@() local_close(dlg));
    end
    fcn();
catch ME
    local_close(dlg);
    uialert(app_figure, ME.message, 'Error', 'Icon', 'error');
end
if ~isempty(cleanup_obj)
    clear cleanup_obj;
end
end

function local_close(dlg)
try
    if ~isempty(dlg) && isvalid(dlg)
        close(dlg);
    end
catch
end
end

function n = local_extra_count(extra)
if isempty(extra)
    n = 0;
elseif isstruct(extra)
    n = numel(fieldnames(extra));
elseif iscell(extra)
    n = floor(numel(extra) / 2);
else
    n = 0;
end
end
