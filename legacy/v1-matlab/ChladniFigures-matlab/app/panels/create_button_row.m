function buttons = create_button_row(parent, generate_fcn, reset_fcn, export_fcn)
%CREATE_BUTTON_ROW Create a row of standard action buttons.

row = uigridlayout(parent, [1 3]);
row.ColumnWidth = {'1x', '1x', '1x'};
row.RowHeight = {28};
row.Padding = [0 0 0 0];
row.ColumnSpacing = 6;

buttons.run = uibutton(row, 'push', ...
    'Text', 'Generate', ...
    'ButtonPushedFcn', generate_fcn, ...
    'FontWeight', 'bold');
buttons.run.Layout.Row = 1;
buttons.run.Layout.Column = 1;

buttons.reset = uibutton(row, 'push', ...
    'Text', 'Reset', ...
    'ButtonPushedFcn', reset_fcn);
buttons.reset.Layout.Row = 1;
buttons.reset.Layout.Column = 2;

buttons.export = uibutton(row, 'push', ...
    'Text', 'Export', ...
    'ButtonPushedFcn', export_fcn);
buttons.export.Layout.Row = 1;
buttons.export.Layout.Column = 3;
end
