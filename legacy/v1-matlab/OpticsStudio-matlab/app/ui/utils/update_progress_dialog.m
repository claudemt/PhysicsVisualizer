function update_progress_dialog(dlg, value, message_text)
%UPDATE_PROGRESS_DIALOG Update progress value and human-readable message.

if nargin < 3
    message_text = 'working';
end

if isempty(dlg) || ~isvalid(dlg)
    return;
end

value = max(0, min(1, value));
dlg.Value = value;
dlg.Message = sprintf('%d%% - %s', round(100 * value), message_text);
drawnow;
end
