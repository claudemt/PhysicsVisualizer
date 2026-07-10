function field = create_numeric_control(parent, label_text, default_value, tooltip_text)
%CREATE_NUMERIC_CONTROL Create a compact label + numeric edit row.

row = uigridlayout(parent, [1 2]);
row.ColumnWidth = {'1x', 82};
row.RowHeight = {24};
row.Padding = [0 0 0 0];
row.ColumnSpacing = 6;
row.RowSpacing = 0;

label = uilabel(row, ...
    'Text', label_text, ...
    'HorizontalAlignment', 'left');
label.Layout.Row = 1;
label.Layout.Column = 1;
if nargin >= 4 && ~isempty(tooltip_text)
    label.Tooltip = tooltip_text;
end

field = uieditfield(row, 'numeric', ...
    'Value', default_value, ...
    'HorizontalAlignment', 'center');
field.Layout.Row = 1;
field.Layout.Column = 2;
if nargin >= 4 && ~isempty(tooltip_text)
    field.Tooltip = tooltip_text;
end
end
