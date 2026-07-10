function set_control_enabled(control, enabled, active_tooltip, inactive_tooltip)
%SET_CONTROL_ENABLED Show or hide a control row depending on the current selection.

if enabled
    control.Enable = 'on';
    local_set_row_visible(control, true);
    if nargin >= 3 && ~isempty(active_tooltip)
        control.Tooltip = active_tooltip;
    end
else
    control.Enable = 'off';
    local_set_row_visible(control, false);
    if nargin >= 4 && ~isempty(inactive_tooltip)
        control.Tooltip = inactive_tooltip;
    elseif nargin >= 3 && ~isempty(active_tooltip)
        control.Tooltip = active_tooltip;
    else
        control.Tooltip = '';
    end
end
end

function local_set_row_visible(control, is_visible)
row = control.Parent;
try
    row.Visible = matlab.lang.OnOffSwitchState(is_visible);
catch
    if is_visible
        row.Visible = 'on';
    else
        row.Visible = 'off';
    end
end

parent = row.Parent;
if isa(parent, 'matlab.ui.container.GridLayout')
    idx = row.Layout.Row;
    heights = parent.RowHeight;
    if is_visible
        heights{idx} = 'fit';
    else
        heights{idx} = 0;
    end
    parent.RowHeight = heights;
end
end
