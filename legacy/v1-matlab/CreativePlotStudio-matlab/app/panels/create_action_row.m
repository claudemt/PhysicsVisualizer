function buttons = create_action_row(parent, render_fcn, export_fcn)
%CREATE_ACTION_ROW Create the standard Render / Export row.

row = uigridlayout(parent, [1 2]);
row.ColumnWidth = {'1x', '1x'};
row.RowHeight = {30};
row.Padding = [0 0 0 0];
row.ColumnSpacing = 8;

buttons.render = uibutton(row);
buttons.render.Layout.Row = 1;
buttons.render.Layout.Column = 1;
buttons.render.Text = 'Render';
buttons.render.FontName = 'Times New Roman';
buttons.render.FontWeight = 'bold';
buttons.render.ButtonPushedFcn = render_fcn;

buttons.export = uibutton(row);
buttons.export.Layout.Row = 1;
buttons.export.Layout.Column = 2;
buttons.export.Text = 'Export';
buttons.export.FontName = 'Times New Roman';
buttons.export.FontWeight = 'bold';
buttons.export.ButtonPushedFcn = export_fcn;

end
