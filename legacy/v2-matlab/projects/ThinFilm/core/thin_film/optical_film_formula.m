function varargout = optical_film_formula(action, varargin)
%OPTICAL_FILM_FORMULA Multilayer dielectric stack: s/p reflection and transmission.
%
% Transfer matrices P (s) and Q (p); tangential k_x is fixed by incidence in medium a.
%
% Usage
%   data = optical_film_formula('defaultInput');
%   h    = optical_film_formula('resolve_h', spec, omega, theta_a, eps_a, mu_a, eps_m, mu_m);
%   data = optical_film_formula('quarterwave', data);          % optional: φ=π/2 per layer
%   data = optical_film_formula('alternating_quarterwave', p); % optional: scripted stacks
%   R    = optical_film_formula('solve', data);

    if nargin == 0
        error('optical_film_formula requires an action.');
    end

    switch lower(action)
        case 'defaultinput'
            varargout{1} = defaultInput();
        case 'solve'
            if isempty(varargin)
                error('Missing input data for solve.');
            end
            varargout{1} = solveOpticalFilm(varargin{1});
        case {'resolve_h','parse_layer_h','layer_h'}
            if numel(varargin) < 7
                error('resolve_h requires (spec, omega, theta_a, eps_a, mu_a, eps_m, mu_m).');
            end
            varargout{1} = parseOpticalLayerThickness(varargin{:});
        case {'quarterwave','quarter_wave','qw'}
            varargout{1} = applyQuarterWaveThicknesses(varargin{1});
        case {'alternating_quarterwave','alternating_stack'}
            varargout{1} = buildAlternatingQuarterWaveStack(varargin{1});
        otherwise
            error('Unknown action: %s', action);
    end
end

function data = defaultInput()
    eps_a = 1;
    mu_a  = 1;
    eps_g = 2.25;
    mu_g  = 1;
    omega = 1;
    theta_a = round(pi / 6, 3);

    data.N = 1;
    data.omega = omega;
    data.theta_a = theta_a;

    data.a = struct('eps', eps_a, 'mu', mu_a);
    data.g = struct('eps', eps_g, 'mu', mu_g);

    k_x = omega * sqrt(eps_a * mu_a) * sin(data.theta_a);
    k_z1 = sqrt(omega^2 * 2.25 - k_x^2);
    h1 = pi / (2 * max(real(k_z1), realmin));
    data.layers = struct('eps', 2.25, 'mu', 1, 'h', roundnice(h1));
end

function data = applyQuarterWaveThicknesses(data)
    if data.N < 1
        return;
    end
    omega = data.omega;
    theta_a = data.theta_a;
    k_x = omega * sqrt(data.a.eps * data.a.mu) * sin(theta_a);
    for m = 1:data.N
        med = makeOpticalMedium(data.layers(m).eps, data.layers(m).mu, omega, k_x);
        data.layers(m).h = roundnice(pi / (2 * max(real(med.k_z), realmin)));
    end
end

function data = buildAlternatingQuarterWaveStack(p)
    data = struct();
    data.N = p.N;
    data.omega = p.omega;
    data.theta_a = p.theta_a;
    data.a = p.a;
    data.g = p.g;
    first_high = isfield(p, 'first_high') && logical(p.first_high);
    data.layers = repmat(struct('eps', 0, 'mu', 0, 'h', 0), p.N, 1);
    for m = 1:p.N
        use_high = xor(mod(m, 2) == 1, ~first_high);
        if use_high
            data.layers(m).eps = p.eps_hi;
            data.layers(m).mu = p.mu_hi;
        else
            data.layers(m).eps = p.eps_lo;
            data.layers(m).mu = p.mu_lo;
        end
    end
    data = applyQuarterWaveThicknesses(data);
end

function x = roundnice(x)
    x = double(x);
    ax = abs(x);
    if ax >= 1 || ax == 0
        x = round(x, 3);
    else
        x = round(x, 4);
    end
end

function R = solveOpticalFilm(data)
    omega = data.omega;
    theta_a = data.theta_a;
    k_x = omega * sqrt(data.a.eps * data.a.mu) * sin(theta_a);

    a = makeOpticalMedium(data.a.eps, data.a.mu, omega, k_x);
    g = makeOpticalMedium(data.g.eps, data.g.mu, omega, k_x);

    Ptot = eye(2);
    Qtot = eye(2);

    if data.N > 0
        layers = repmat(makeBlankOpticalLayer(), data.N, 1);
    else
        layers = repmat(makeBlankOpticalLayer(), 0, 1);
    end

    for m = 1:data.N
        med = makeOpticalMedium(data.layers(m).eps, data.layers(m).mu, omega, k_x);
        med.h = data.layers(m).h;
        med.phi = med.k_z * med.h;
        layers(m) = med;

        Ptot = Ptot * layerMatrixP(med);
        Qtot = Qtot * layerMatrixQ(med);
    end

    zeta_a = a.zeta;
    zeta_g = g.zeta;
    ca = a.cos_theta;
    cg = g.cos_theta;

    P = Ptot;
    Qm = Qtot;

    comboP = P(1,1) + zeta_g * cg * P(1,2);
    comboP21 = P(2,1) + zeta_g * cg * P(2,2);

    den_s = zeta_a * ca * comboP + comboP21;
    num_rs = zeta_a * ca * comboP - comboP21;
    R.rs = num_rs / den_s;
    R.ts = (2 * zeta_a * ca) / den_s;

    comboQ1 = Qm(1,1) * zeta_g + Qm(1,2) * cg;
    comboQ2 = Qm(2,1) * zeta_g + Qm(2,2) * cg;

    den_p = ca * comboQ1 + zeta_a * comboQ2;
    num_rp = ca * comboQ1 - zeta_a * comboQ2;
    R.rp = num_rp / den_p;
    R.tp = (2 * zeta_a * ca) / den_p;

    R.Rs = abs(R.rs)^2;
    R.Rp = abs(R.rp)^2;
    R.Ts = (zeta_g * cg) / (zeta_a * ca) * abs(R.ts)^2;
    R.Tp = (zeta_g * cg) / (zeta_a * ca) * abs(R.tp)^2;

    R.Es = R.Rs + R.Ts;
    R.Ep = R.Rp + R.Tp;

    R.a = a;
    R.g = g;
    R.layers = layers;
    R.P = Ptot;
    R.Q = Qtot;
    R.k_x = k_x;

    R = cleanSmallImag(R);
end

function med = makeOpticalMedium(eps, mu, omega, k_x)
    med = makeBlankOpticalLayer();
    med.eps = eps;
    med.mu = mu;
    med.omega = omega;
    n_sq = eps * mu;
    n = sqrt(n_sq);
    med.k_x = k_x;
    k_z_sq = omega^2 * n_sq - k_x^2;
    med.k_z = sqrt(k_z_sq);
    med.sin_theta = k_x / (omega * n);
    med.cos_theta = med.k_z / (omega * n);
    med.zeta = sqrt(eps / mu);
end

function med = makeBlankOpticalLayer()
    med = struct( ...
        'eps', 0, 'mu', 0, 'omega', 0, ...
        'k_x', 0, 'k_z', 0, ...
        'sin_theta', 0, 'cos_theta', 0, ...
        'zeta', 0, 'h', 0, 'phi', 0);
end

function M = layerMatrixP(med)
    ph = med.phi;
    z = med.zeta;
    ct = med.cos_theta;
    cph = cos(ph);
    sph = sin(ph);
    M = [ ...
        cph, -1i / z * sph / ct; ...
        -1i * z * ct * sph, cph];
end

function M = layerMatrixQ(med)
    ph = med.phi;
    z = med.zeta;
    ct = med.cos_theta;
    cph = cos(ph);
    sph = sin(ph);
    M = [ ...
        cph, -1i * z * sph / ct; ...
        -1i / z * ct * sph, cph];
end

function h = parseOpticalLayerThickness(spec, omega, theta_a, eps_a, mu_a, eps_m, mu_m)
%PARSEOPTICALLAYERTHICKNESS Numeric h or "coeff*lambda" optical thickness.
%
% lambda is the wavelength in incident medium a: lambda_a = 2*pi/(omega*n_a),
% n_a = sqrt(eps_a*mu_a). Optical thickness means n_m*cos(theta_m)*h = coeff*lambda_a,
% with n_m*cos(theta_m) = real(k_z_m/omega) for propagating waves.

    spec = strtrim(char(string(spec)));
    tok = regexp(lower(spec), '^([+-]?[\d.eE+-]+)\s*\*\s*lambda\s*$', 'tokens', 'once');
    if ~isempty(tok)
        alpha = str2double(tok{1});
        if isnan(alpha)
            error('optical_film_formula:parseInvalidCoefficient', 'Invalid coefficient before *lambda in ''%s''.', spec);
        end
        n_a = sqrt(eps_a * mu_a);
        lambda_a = (2 * pi) / (omega * max(real(n_a), realmin));
        k_x = omega * n_a * sin(theta_a);
        k_z_m = sqrt(omega^2 * eps_m * mu_m - k_x^2);
        nm_cos = real(k_z_m / omega);
        nm_cos = max(nm_cos, realmin);
        h = alpha * lambda_a / nm_cos;
        return;
    end
    v = str2double(spec);
    if isnan(v)
        error('optical_film_formula:parseInvalidThickness', ...
            'Layer thickness must be a number or coeff*lambda (example: 1.8*lambda or 1.8 * lambda); got ''%s''.', spec);
    end
    h = v;
end

function out = cleanSmallImag(out)
    if isstruct(out)
        if numel(out) == 0
            return;
        elseif numel(out) > 1
            for jj = 1:numel(out)
                out(jj) = cleanSmallImag(out(jj));
            end
        else
            fn = fieldnames(out);
            for ii = 1:numel(fn)
                out.(fn{ii}) = cleanSmallImag(out.(fn{ii}));
            end
        end
    elseif isnumeric(out) && isscalar(out)
        if abs(imag(out)) < 1e-12 * max(1, abs(real(out)))
            out = real(out);
        end
    end
end
