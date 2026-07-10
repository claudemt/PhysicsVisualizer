function modules = discover_fourier_modules(root_dir)
%DISCOVER_FOURIER_MODULES Auto-discover object/phase/filter plane modules.

if nargin < 1 || isempty(root_dir)
    root_dir = fileparts(mfilename('fullpath'));
end

modules = struct();
modules.object = local_discover(fullfile(root_dir, 'object_plane'));
modules.phase = local_discover(fullfile(root_dir, 'phase_plane'));
modules.filter = local_discover(fullfile(root_dir, 'filter_plane'));
end

function entries = local_discover(folder)
listing = dir(fullfile(folder, '*.m'));
entries = repmat(struct('FunctionName', '', 'DisplayName', '', 'Description', ''), 0, 1);
for k = 1:numel(listing)
    func_name = erase(listing(k).name, '.m');
    try
        info = feval(func_name, 'info');
        display_name = char(string(info.Name));
        desc = char(string(info.Description));
    catch
        display_name = strrep(func_name, '_', ' ');
        desc = '';
    end
    entries(end + 1, 1) = struct( ...
        'FunctionName', func_name, ...
        'DisplayName', display_name, ...
        'Description', desc); %#ok<AGROW>
end

if isempty(entries)
    return
end

[~, idx] = sort(lower(string({entries.DisplayName})));
entries = entries(idx);
end
