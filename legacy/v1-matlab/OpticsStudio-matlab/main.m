function main
%MAIN Entry point for Unified Optics Studio.
%   This script adds the project subfolders to the MATLAB path and launches
%   the tabbed GUI.

project_root = fileparts(mfilename('fullpath'));
addpath(genpath(project_root));
launch_unified_optics_studio(project_root);
end
