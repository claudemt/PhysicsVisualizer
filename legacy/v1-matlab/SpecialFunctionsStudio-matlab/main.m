function main()
project_root = fileparts(mfilename('fullpath'));
addpath(genpath(project_root));
launch_gui_studio(project_root, @create_special_functions_tab, ...
    'Name', 'Special Functions Studio');
end
