function varargout = main
%MAIN Launch Graphite Levitation Studio.
% Put this folder at PhysicsVisualizer/projects/GraphiteLevitation and run main.

project_root = fileparts(mfilename('fullpath'));
repo_root = fileparts(fileparts(project_root));
utils_root = fullfile(repo_root, 'utils');

% Avoid MATLAB keeping older GraphiteLevitation folders earlier on path.
try
    p = strsplit(path, pathsep);
    hit = contains(p, [filesep 'GraphiteLevitation']);
    if any(hit)
        rmpath(strjoin(p(hit), pathsep));
    end
catch
end

if exist(utils_root, 'dir') == 7
    addpath(utils_root);
end
addpath(genpath(fullfile(project_root, 'app')));
addpath(genpath(fullfile(project_root, 'core')));
addpath(genpath(fullfile(project_root, 'docs')));

try
    clear create_magnetic_potential_tab compute_visualization_maps render_graphite_levitation_result
catch
end

tab_builders = { ...
    @create_magnetic_potential_tab};

fig = launch_gui_studio(project_root, tab_builders, ...
    'StudioName', 'Graphite Levitation Studio', ...
    'Position', [80 60 1360 840], ...
    'Maximized', true);

if nargout > 0
    varargout{1} = fig;
end
end
