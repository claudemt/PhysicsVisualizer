function out = parse_crystal_boundary_params(action, varargin)
switch lower(char(string(action)))
    case 'defaults'
        out = local_defaults();
    case 'vector'
        out = create_control_panel([], 'parse_vector', varargin{1});
    case 'matrix'
        out = create_control_panel([], 'parse_matrix', varargin{1});
    otherwise
        error('Unknown parse_crystal_boundary_params action.');
end
end

function cfg = local_defaults()
cfg = struct();
cfg.n_inc = 1.0;
cfg.k_inc = [0.60; 0.64; -0.48];
cfg.pol = struct('type', 2, 'angle_deg', 0.0, 'vector', [1;0;0], 'num_samples', 181);
cfg.eps_diag = [2.25, 2.56, 3.24];
cfg.eps_lab = diag(cfg.eps_diag);
cfg.orientation = struct();
cfg.orientation.mode = 'none';
cfg.orientation.optic_axis = [0; 0; 1];
cfg.orientation.euler_deg = [0, 0, 0];
cfg.orientation.R = eye(3);
end
