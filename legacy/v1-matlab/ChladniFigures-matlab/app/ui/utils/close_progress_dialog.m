function close_progress_dialog(dlg)
%CLOSE_PROGRESS_DIALOG Close a progress dialog if it exists.

if isempty(dlg)
    return;
end
if isvalid(dlg)
    close(dlg);
end
end
