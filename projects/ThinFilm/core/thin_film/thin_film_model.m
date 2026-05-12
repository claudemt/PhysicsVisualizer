function out = thin_film_model(action, varargin)
%THIN_FILM_MODEL Compact core facade for thin-film defaults, solve, and report.
%
% Elastic implementation: elastic_film_formula.m
% Optical stack: optical_film_formula.m

switch lower(char(string(action)))
    case {'defaults','default_params'}
        out = local_defaults();
    case {'defaults_optical','default_params_optical'}
        out = local_defaults_optical();
    case {'solve'}
        out = elastic_film_formula('solve', varargin{1});
    case {'solve_optical'}
        out = optical_film_formula('solve', varargin{1});
    case {'report','compute_report'}
        data = varargin{1};
        R = elastic_film_formula('solve', data);
        out = struct('data', data, 'result', R, 'text', local_report(data, R));
    case {'report_optical','compute_report_optical'}
        data = varargin{1};
        R = optical_film_formula('solve', data);
        out = struct('data', data, 'result', R, 'text', local_report_optical(data, R));
    otherwise
        error('Unknown thin_film_model action: %s', action);
end
end

function data = local_defaults()
raw = elastic_film_formula('defaultInput');
data = struct();
data.N = raw.N;
data.omega = raw.omega;
data.kx = raw.kx;
data.phii = raw.phii;
data.psii = raw.psii;
data.a = struct('lambda', raw.lambda_a, 'mu', raw.mu_a, 'eta', raw.eta_a);
data.g = struct('lambda', raw.lambda_g, 'mu', raw.mu_g, 'eta', raw.eta_g);
data.layers = raw.layers;
end

function data = local_defaults_optical()
raw = optical_film_formula('defaultInput');
data = struct();
data.N = raw.N;
data.omega = raw.omega;
data.theta_a = raw.theta_a;
data.a = struct('eps', raw.a.eps, 'mu', raw.a.mu);
data.g = struct('eps', raw.g.eps, 'mu', raw.g.mu);
data.layers = raw.layers;
end

function txt = local_report(data, R)
lines = {};
lines{end+1} = 'Elastic film result';
lines{end+1} = '===================';
lines{end+1} = '';
lines{end+1} = sprintf('N = %d', data.N);
lines{end+1} = sprintf('omega = %s', local_fmt(data.omega));
lines{end+1} = sprintf('k_x = %s', local_fmt(data.kx));
lines{end+1} = sprintf('phi_i = %s', local_fmt(data.phii));
lines{end+1} = sprintf('psi_i = %s', local_fmt(data.psii));
lines{end+1} = '';
lines{end+1} = 'Air side a';
lines{end+1} = sprintf('lambda_a = %s', local_fmt(data.a.lambda));
lines{end+1} = sprintf('mu_a = %s', local_fmt(data.a.mu));
lines{end+1} = sprintf('eta_a = %s', local_fmt(data.a.eta));
lines{end+1} = '';
lines{end+1} = 'Substrate side g';
lines{end+1} = sprintf('lambda_g = %s', local_fmt(data.g.lambda));
lines{end+1} = sprintf('mu_g = %s', local_fmt(data.g.mu));
lines{end+1} = sprintf('eta_g = %s', local_fmt(data.g.eta));
lines{end+1} = '';
for m = 1:data.N
    lines{end+1} = sprintf('Layer %d', m);
    lines{end+1} = sprintf('lambda_%d = %s', m, local_fmt(data.layers(m).lambda));
    lines{end+1} = sprintf('mu_%d = %s', m, local_fmt(data.layers(m).mu));
    lines{end+1} = sprintf('eta_%d = %s', m, local_fmt(data.layers(m).eta));
    lines{end+1} = sprintf('h_%d = %s', m, local_fmt(data.layers(m).h));
    lines{end+1} = '';
end
lines{end+1} = 'P incidence';
lines = [lines, local_result_lines(R, 'P')]; %#ok<AGROW>
lines{end+1} = '';
lines{end+1} = 'SV incidence';
lines = [lines, local_result_lines(R, 'SV')]; %#ok<AGROW>
lines{end+1} = '';
lines{end+1} = 'SH incidence';
lines{end+1} = sprintf('r_SH = %s', local_fmt(R.rSH));
lines{end+1} = sprintf('R_SH = %s', local_fmt(R.RSH));
lines{end+1} = sprintf('t_SH = %s', local_fmt(R.tSH));
lines{end+1} = sprintf('T_SH = %s', local_fmt(R.TSH));
lines{end+1} = sprintf('Energy sum = %s', local_fmt(R.ESH));
txt = sprintf('%s\n', lines{:});
end

function txt = local_report_optical(data, R)
lines = {};
lines{end+1} = 'Optical multilayer result';
lines{end+1} = '========================';
lines{end+1} = '';
lines{end+1} = sprintf('N = %d', data.N);
lines{end+1} = sprintf('omega = %s', local_fmt(data.omega));
lines{end+1} = sprintf('theta_a (rad, from normal in medium a) = %s', local_fmt(data.theta_a));
lines{end+1} = sprintf('k_x = %s', local_fmt(R.k_x));
lines{end+1} = '';
lines{end+1} = 'Medium a (incident)';
lines{end+1} = sprintf('eps_a = %s', local_fmt(data.a.eps));
lines{end+1} = sprintf('mu_a = %s', local_fmt(data.a.mu));
lines{end+1} = sprintf('zeta_a = %s', local_fmt(R.a.zeta));
lines{end+1} = sprintf('cos_theta_a = %s', local_fmt(R.a.cos_theta));
lines{end+1} = '';
lines{end+1} = 'Medium g (substrate)';
lines{end+1} = sprintf('eps_g = %s', local_fmt(data.g.eps));
lines{end+1} = sprintf('mu_g = %s', local_fmt(data.g.mu));
lines{end+1} = sprintf('zeta_g = %s', local_fmt(R.g.zeta));
lines{end+1} = sprintf('cos_thet