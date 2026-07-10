function main
%MAIN Entry point for Creative Plot Studio.
project_root = fileparts(mfilename('fullpath'));
addpath(genpath(project_root));
launch_creative_plot_studio(project_root);
end
