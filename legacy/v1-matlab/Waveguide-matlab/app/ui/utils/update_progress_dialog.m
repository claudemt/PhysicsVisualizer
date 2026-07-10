function update_progress_dialog(dlg, value, message)
%UPDATE_PROGRESS_DIALOG Update a progress dialog if it exists.

if isempty(dlg)
    return;
end
if ~isvalid(dlg)
    return;
end

clamped = max(0, min(1, value));
dlg.Value = clamped;
if nargin >= 3 && ~isempty(message)
    dlg.Message = message;
else
    dlg.Message = 'working';
end
drawnow limitrate;
end
