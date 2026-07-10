function modules = discover_plane_modules(root_dir)
%DISCOVER_PLANE_MODULES Auto-discover object/phase/filter modules.
if nargin < 1 || isempty(root_dir)
    root_dir = fileparts(mfilename('fullpath'));
end
addpath(genpath(root_dir));

modules = struct();
modules.object = localDiscover(fullfile(root_dir, 'object plane'));
modules.phase = localDiscover(fullfile(root_dir, 'phase plane'));
modules.filter = localDiscover(fullfile(root_dir, 'filter plane'));
end

function out = localDiscover(folder)
listing = dir(fullfile(folder, '*.m'));
out = repmat(struct('FunctionName', '', 'DisplayName', '', 'Description', ''), 0, 1);
for k = 1:numel(listing)
    fname = erase(listing(k).name, '.m');
    try
        info = feval(fname, 'info');
        display_name = string(info.Name);
        desc = string(info.Description);
    catch
        display_name = string(strrep(strrep(fname, '_', ' '), 'object ', ''));
        desc = "";
    end
    out(end+1,1) = struct( ...
        'FunctionName', fname, ...
        'DisplayName', char(display_name), ...
        'Description', char(desc)); %#ok<AGROW>
end
[~, idx] = sort(lower(string({out.DisplayName})));
out = out(idx);
end
