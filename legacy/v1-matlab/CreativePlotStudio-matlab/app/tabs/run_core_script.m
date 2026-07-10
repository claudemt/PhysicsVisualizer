function run_core_script(render_path, ax, style)
%RUN_CORE_SCRIPT Execute a core render.m script in a normal function workspace.
%
% The GUI calls this function instead of calling run(render_path) directly
% inside a nested callback. MATLAB nested callbacks use a static workspace;
% render scripts often create temporary variables such as v, pal, or flavor,
% which cannot be added to a static workspace. This function gives the script
% a normal function workspace containing ax and style.

if nargin < 3 || isempty(style)
    style = 'default';
end

if ~exist(render_path,'file')
    error('Core render file not found: %s', render_path);
end

run(render_path);
end
