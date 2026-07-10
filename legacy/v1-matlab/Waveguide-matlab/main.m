function main()
%MAIN Launch the Waveguide GUI project.

project_root = fileparts(mfilename('fullpath'));
addpath(genpath(project_root));
launch_waveguide_studio(project_root);
end
