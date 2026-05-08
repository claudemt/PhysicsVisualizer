function out = thin_film_model(action, varargin)
%THIN_FILM_MODEL Compact core facade for thin-film defaults, solve, and report.
%
% The long formula implementation stays in elastic_film_formula.m.  Small
% wrappers that used to be separate files are intentionally collected here.

switch lower(char(string(action)))
    case {'defaults','default_params'}
        out = local_defaults();
    case {'solve'}
        out = elastic_film_formula('solve', varargin{1});
    case {'report','compute_report'}
        data = varargin{1};
        R = elastic_film_formula('solve', data);
        out = struct('data', data, 'result', R, 'text', local_report(data, R));
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

function lines = local_result_lines(R, kind)
if strcmp(kind, 'P')
    lines = { ...
        sprintf('r_P = %s', local_fmt(R.rP_P)), ...
        sprintf('R_P = %s', local_fmt(R.RP_P)), ...
        sprintf('r_SV = %s', local_fmt(R.rSV_P)), ...
        sprintf('R_SV = %s', local_fmt(R.RSV_P)), ...
        sprintf('t_P = %s', local_fmt(R.tP_P)), ...
        sprintf('T_P = %s', local_fmt(R.TP_P)), ...
        sprintf('t_SV = %s', local_fmt(R.tSV_P)), ...
        sprintf('T_SV = %s', local_fmt(R.TSV_P)), ...
        sprintf('Energy sum = %s', local_fmt(R.EP))};
else
    lines = { ...
        sprintf('r_P = %s', local_fmt(R.rP_SV)), ...
        sprintf('R_P = %s', local_fmt(R.RP_SV)), ...
        sprintf('r_SV = %s', local_fmt(R.rSV_SV)), ...
        sprintf('R_SV = %s', local_fmt(R.RSV_SV)), ...
        sprintf('t_P = %s', local_fmt(R.tP_SV)), ...
        sprintf('T_P = %s', local_fmt(R.TP_SV)), ...
        sprintf('t_SV = %s', local_fmt(R.tSV_SV)), ...
        sprintf('T_SV = %s', local_fmt(R.TSV_SV)), ...
        sprintf('Energy sum = %s', local_fmt(R.ESV))};
end
end

function s = local_fmt(x)
x = local_clean_small_imag(x);
if isreal(x)
    s = num2str(real(x), '%.6g');
else
    xr = real(x); xi = imag(x);
    if abs(xr) < 1e-14, xr = 0; end
    if abs(xi) < 1e-14, xi = 0; end
    if xi >= 0
        s = [num2str(xr, '%.6g') ' + ' num2str(abs(xi), '%.6g') 'i'];
    else
        s = [num2str(xr, '%.6g') ' - ' num2str(abs(xi), '%.6g') 'i'];
    end
end
end

function out = local_clean_small_imag(out)
if isnumeric(out) && isscalar(out) && abs(imag(out)) < 1e-12 * max(1, abs(real(out)))
    out = real(out);
end
end
