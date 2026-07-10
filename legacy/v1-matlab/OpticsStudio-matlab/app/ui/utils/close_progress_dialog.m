function close_progress_dialog(dlg)
%CLOSE_PROGRESS_DIALOG Safely close a progress dialog.

if isempty(dlg)
    return;
end

if isvalid(dlg)
    delete(dlg);
end
end
