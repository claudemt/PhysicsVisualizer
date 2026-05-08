function cb = add_labeled_colorbar(ax, labelText, limits)
%ADD_LABELED_COLORBAR Add a shared-style colorbar.
if nargin >= 3 && ~isempty(limits)
    info = render_result('colorbar', ax, 'Label', labelText, 'Limits', limits);
else
    info = render_result('colorbar', ax, 'Label', labelText);
end
cb = info.cb;
end
