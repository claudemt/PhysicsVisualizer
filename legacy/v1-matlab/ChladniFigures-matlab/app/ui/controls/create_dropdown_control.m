function dd = create_dropdown_control(parent, label_text, items, default_value, tooltip_text)
%CREATE_DROPDOWN_CONTROL Create a compact label + dropdown row.

row = uigridlayout(parent, [1 2]);
row.ColumnWidth = {'1x', 118};
row.RowHeight = {24};
row.Padding = [0 0 0 0];
row.ColumnSpacing = 6;
row.RowSpacing = 0;

label = uilabel(row, ...
    'Text', label_text, ...
    'HorizontalAlignment', 'left');
label.Layout.Row = 1;
label.Layout.Column = 1;
if nargin >= 5 && ~isempty(tooltip_text)
    label.Tooltip = tooltip_text;
end

if ischar(items)
    items = {items};
end

dd = uidropdown(row, ...
    'Items', items, ...
    'Value', default_value);
dd.Layout.Row = 1;
dd.Layout.Column = 2;
if nargin >= 5 && ~isempty(tooltip_text)
    dd.Tooltip = tooltip_text;
end
end
