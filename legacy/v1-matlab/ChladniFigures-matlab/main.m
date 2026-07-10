function main()
%MAIN Launch the Chladni GUI project.

project_root = fileparts(mfilename('fullpath'));
addpath(genpath(project_root));
launch_chladni_studio(project_root);
end
