function buttons = bind_workflow(parent, app_figure, generate_fcn, reset_fcn, export_fcn, varargin)
%BIND_WORKFLOW Standard Generate / Reset / Export button row.
%
% buttons = bind_workflow(parent, fig, @run, @reset, @export, ...)
%
% Options:
%   GenerateText, ResetText, ExportText
%   UseProgress, ProgressTitle, ProgressMessage
%   ConfirmExport

p = inputParser;
p.addParameter('GenerateText', 'Generate', @(s) ischar(s) || isstring(s));
p.addParameter('ResetText', 'Reset', @(s) ischar(s) || isstring(s));
p.addParameter('ExportText', 'Export', @(s) ischar(s) || isstring(s));
p.addParameter('UseProgress', true, @(v) islogical(v) || isnumeric(v));
p.addParameter('ProgressTitle', 'Processing', @(s) ischar(s) || isstring(s));
p.addParameter('ProgressMessage', 'Please wait...', @(s) ischar(s) || isstring(s));
p.addParameter('ConfirmExport', false, @(v) islogical(v) || isnumeric(v));
p.parse(varargin{:});
opt = p.Results;

grid = uigridlayout(parent, [1 3]);
grid.RowHeight = {'fit'};
grid.ColumnWidth = {'1x','1x','1x'};
grid.Padding = [0 0 0 0];
grid.ColumnSpacing = 8;
try
    grid.Layout.Row = 1;
    grid.Layout.Column = 1;
catch
end

buttons.generate = uibutton(grid, 'push', 'Text', char(string(opt.GenerateText)));
buttons.generate.Layout.Column = 1;
buttons.reset = uibutton(grid, 'push', 'Text', char(string(opt.ResetText)));
buttons.reset.Layout.Column = 2;
buttons.export = uibutton(grid, 'push', 'Text', char(string(opt.ExportText)));
buttons.export.Layout.Column = 3;

% Compatibility aliases.
buttons.run = buttons.generate;
buttons.panel = grid;
buttons.grid = grid;

buttons.generate.ButtonPushedFcn = @(src, evt) local_invoke(app_figure, generate_fcn, opt, 'generate');
buttons.reset.ButtonPushedFcn = @(src, evt) local_invoke(app_figure, reset_fcn, opt, 'reset');
buttons.export.ButtonPushedFcn = @(src, evt) local_export(app_figure, export_fcn, opt);
end

function local_export(fig, fcn, opt)
if opt.ConfirmExport
    selection = uiconfirm(fig, 'Export current result?', 'Export', ...
        'Options', {'Export','Cancel'}, ...
        'DefaultOption', 1, ...
        'CancelOption', 2);
    if ~strcmp(selection, 'Export')
        return;
    end
end
local_invoke(fig, fcn, opt, 'export');
end

function local_invoke(fig, fcn, opt, action)
dlg = [];
try
    if opt.UseProgress && ~strcmp(action, 'reset')
        local_ensure_visible(fig);
        dlg = uiprogressdlg(fig, ...
            'Title', char(string(opt.ProgressTitle)), ...
            'Message', char(string(opt.ProgressMessage)), ...
            'Value', 0.05, ...
            'Indeterminate', 'on', ...
            'Cancelable', 'off');
        drawnow;
    end

    if isa(fcn, 'function_handle')
        fcn();
    end

    if ~isempty(dlg) && isvalid(dlg)
        dlg.Value = 1;
        dlg.Message = 'Done';
        drawnow;
        delete(dlg);
    end
catch ME
    if ~isempty(dlg) && isvalid(dlg)
        delete(dlg);
    end
    local_alert(fig, ME);
end
end


function local_ensure_visible(fig)
if isempty(fig) || ~isgraphics(fig)
    return;
end
try
    if isprop(fig, 'Visible') && ~strcmpi(char(string(fig.Visible)), 'on')
        fig.Visible = 'on';
        drawnow;
    end
catch
end
end

function local_alert(fig, ME)
msg = ME.message;
if isempty(msg)
    msg = 'Unknown error.';
end
if isempty(fig) || ~isgraphics(fig)
    warning('%s', msg);
    return;
end
try
    local_ensure_visible(fig);
    visible_state = 'on';
    if isprop(fig, 'Visible')
        visible_state = char(string(fig.Visible));
    end
    if ~strcmpi(visible_state, 'on')
        warning('%s', msg);
        return;
    end
    uialert(fig, msg, 'Error', 'Icon', 'error');
catch
    warning('%s', msg);
end
end
