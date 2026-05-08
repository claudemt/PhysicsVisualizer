function varargout = elastic_film_formula(action, varargin)
% elastic_film_formula
% Core formulas for elastic-film P / SV / SH calculation.
%
% Usage
%   data = elastic_film_formula('defaultInput');
%   R    = elastic_film_formula('solve', data);
%
% This file only stores the computational part so that the GUI logic can
% stay in main_elastic_film_gui.m.

    if nargin == 0
        error('elastic_film_formula requires an action.');
    end

    switch lower(action)
        case 'defaultinput'
            varargout{1} = defaultInput();
        case 'solve'
            if isempty(varargin)
                error('Missing input data for solve.');
            end
            varargout{1} = solveElasticFilm(varargin{1});
        otherwise
            error('Unknown action: %s', action);
    end
end

function data = defaultInput()
    mu_a = 1.0;
    eta_a = 1.0;
    omega = 1.0;

    data.N = 1;
    data.omega = omega;
    data.kx = 0.1 * omega * sqrt(eta_a / mu_a);
    data.phii = 1.0;
    data.psii = 1.0;

    data.lambda_a = 1.3 * mu_a;
    data.mu_a = mu_a;
    data.eta_a = eta_a;

    data.lambda_g = 1.3 * mu_a;
    data.mu_g = 5.2 * mu_a;
    data.eta_g = 1.9 * eta_a;

    data.layers = struct( ...
        'lambda', 4.0 * mu_a, ...
        'mu',     1.5 * mu_a, ...
        'eta',    4.4 * eta_a, ...
        'h',      9.8 * sqrt(mu_a / (omega^2 * eta_a)));
end

function R = solveElasticFilm(data)
    a = makeMedium(data.a.lambda, data.a.mu, data.a.eta, data.kx, data.omega);
    g = makeMedium(data.g.lambda, data.g.mu, data.g.eta, data.kx, data.omega);

    Ptot = eye(4);
    Psh  = eye(2);

    if data.N > 0
        blankLayer = makeBlankLayer();
        layers = repmat(blankLayer, data.N, 1);
    else
        layers = repmat(makeBlankLayer(), 0, 1);
    end

    for m = 1:data.N
        med = makeMedium(data.layers(m).lambda, data.layers(m).mu, data.layers(m).eta, data.kx, data.omega);
        med.h = data.layers(m).h;
        med.phiP = med.kP * med.h * cos(med.thetaP);
        med.phiS = med.kS * med.h * cos(med.thetaS);
        layers(m) = med;

        Ptot = Ptot * psvTransfer(med);
        Psh  = Psh  * shTransfer(med);
    end

    c1 = [ ...
        -1; ...
         cot(a.thetaP); ...
         a.eta * a.kappa * sin(2*a.thetaP); ...
        -a.eta * cos(2*a.thetaS)];

    c2 = [ ...
        -cot(a.thetaS); ...
        -1; ...
         a.eta * cos(2*a.thetaS); ...
         a.eta * sin(2*a.thetaS)];

    c3 = Ptot * [ ...
        1; ...
        cot(g.thetaP); ...
        g.eta * g.kappa * sin(2*g.thetaP); ...
        g.eta * cos(2*g.thetaS)];

    c4 = Ptot * [ ...
       -cot(g.thetaS); ...
        1; ...
       -g.eta * cos(2*g.thetaS); ...
        g.eta * sin(2*g.thetaS)];

    A = [c1 c2 c3 c4];

    rhsP = [ ...
        1; ...
        cot(a.thetaP); ...
        a.eta * a.kappa * sin(2*a.thetaP); ...
        a.eta * cos(2*a.thetaS)] * data.phii;

    rhsSV = [ ...
       -cot(a.thetaS); ...
        1; ...
       -a.eta * cos(2*a.thetaS); ...
        a.eta * sin(2*a.thetaS)] * data.psii;

    solP  = A \ rhsP;
    solSV = A \ rhsSV;

    R = struct();
    R.a = a;
    R.g = g;
    R.layers = layers;
    R.Ptot = Ptot;
    R.Psh = Psh;

    R.phi_r_P = solP(1);
    R.psi_r_P = solP(2);
    R.phi_t_P = solP(3);
    R.psi_t_P = solP(4);

    R.phi_r_SV = solSV(1);
    R.psi_r_SV = solSV(2);
    R.phi_t_SV = solSV(3);
    R.psi_t_SV = solSV(4);

    R.rP_P  = R.phi_r_P / data.phii;
    R.RP_P  = abs(R.rP_P)^2;
    R.rSV_P = R.psi_r_P / data.phii;
    R.RSV_P = (a.cP * cos(a.thetaS)) / (a.cS * cos(a.thetaP)) * abs(R.rSV_P)^2;
    R.tP_P  = R.phi_t_P / data.phii;
    R.TP_P  = (g.eta * a.cP * cos(g.thetaP)) / (a.eta * g.cP * cos(a.thetaP)) * abs(R.tP_P)^2;
    R.tSV_P = R.psi_t_P / data.phii;
    R.TSV_P = (g.eta * a.cP * cos(g.thetaS)) / (a.eta * g.cS * cos(a.thetaP)) * abs(R.tSV_P)^2;
    R.EP = R.RP_P + R.RSV_P + R.TP_P + R.TSV_P;

    R.rP_SV  = R.phi_r_SV / data.psii;
    R.RP_SV  = (a.cS * cos(a.thetaP)) / (a.cP * cos(a.thetaS)) * abs(R.rP_SV)^2;
    R.rSV_SV = R.psi_r_SV / data.psii;
    R.RSV_SV = abs(R.rSV_SV)^2;
    R.tP_SV  = R.phi_t_SV / data.psii;
    R.TP_SV  = (g.eta * a.cS * cos(g.thetaP)) / (a.eta * g.cP * cos(a.thetaS)) * abs(R.tP_SV)^2;
    R.tSV_SV = R.psi_t_SV / data.psii;
    R.TSV_SV = (g.eta * a.cS * cos(g.thetaS)) / (a.eta * g.cS * cos(a.thetaS)) * abs(R.tSV_SV)^2;
    R.ESV = R.RP_SV + R.RSV_SV + R.TP_SV + R.TSV_SV;

    denSH = a.zeta * cos(a.thetaS) * (Psh(1,1) + Psh(1,2) * g.zeta * cos(g.thetaS)) + ...
            (Psh(2,1) + Psh(2,2) * g.zeta * cos(g.thetaS));
    numSH = a.zeta * cos(a.thetaS) * (Psh(1,1) + Psh(1,2) * g.zeta * cos(g.thetaS)) - ...
            (Psh(2,1) + Psh(2,2) * g.zeta * cos(g.thetaS));

    R.rSH = numSH / denSH;
    R.RSH = abs(R.rSH)^2;
    R.tSH = (a.kS / g.kS) * (2 * a.zeta * cos(a.thetaS)) / denSH;
    R.TSH = (g.zeta * cos(g.thetaS)) / (a.zeta * cos(a.thetaS)) * abs((g.kS / a.kS) * R.tSH)^2;
    R.ESH = R.RSH + R.TSH;

    R = cleanSmallImag(R);
end

function med = makeMedium(lambda, mu, eta, kx, omega)
    med = makeBlankLayer();
    med.lambda = lambda;
    med.mu = mu;
    med.eta = eta;
    med.kP = omega * sqrt(eta / (lambda + 2*mu));
    med.kS = omega * sqrt(eta / mu);
    med.cP = sqrt((lambda + 2*mu) / eta);
    med.cS = sqrt(mu / eta);
    med.kappa = mu / (lambda + 2*mu);
    med.thetaP = asin(kx / med.kP);
    med.thetaS = asin(kx / med.kS);
    med.zeta = eta * med.cS;
end

function med = makeBlankLayer()
    med = struct( ...
        'lambda', 0, ...
        'mu', 0, ...
        'eta', 0, ...
        'kP', 0, ...
        'kS', 0, ...
        'cP', 0, ...
        'cS', 0, ...
        'kappa', 0, ...
        'thetaP', 0, ...
        'thetaS', 0, ...
        'zeta', 0, ...
        'h', 0, ...
        'phiP', 0, ...
        'phiS', 0);
end

function Pm = psvTransfer(med)
    A1 = [ ...
        1, 1, -cot(med.thetaS),  cot(med.thetaS); ...
        cot(med.thetaP), -cot(med.thetaP), 1, 1; ...
        med.eta*med.kappa*sin(2*med.thetaP), -med.eta*med.kappa*sin(2*med.thetaP), -med.eta*cos(2*med.thetaS), -med.eta*cos(2*med.thetaS); ...
        med.eta*cos(2*med.thetaS), med.eta*cos(2*med.thetaS), med.eta*sin(2*med.thetaS), -med.eta*sin(2*med.thetaS)];

    A2 = [ ...
        exp(1i*med.phiP), exp(-1i*med.phiP), -cot(med.thetaS)*exp(1i*med.phiS),  cot(med.thetaS)*exp(-1i*med.phiS); ...
        cot(med.thetaP)*exp(1i*med.phiP), -cot(med.thetaP)*exp(-1i*med.phiP), exp(1i*med.phiS), exp(-1i*med.phiS); ...
        med.eta*med.kappa*sin(2*med.thetaP)*exp(1i*med.phiP), -med.eta*med.kappa*sin(2*med.thetaP)*exp(-1i*med.phiP), -med.eta*cos(2*med.thetaS)*exp(1i*med.phiS), -med.eta*cos(2*med.thetaS)*exp(-1i*med.phiS); ...
        med.eta*cos(2*med.thetaS)*exp(1i*med.phiP), med.eta*cos(2*med.thetaS)*exp(-1i*med.phiP), med.eta*sin(2*med.thetaS)*exp(1i*med.phiS), -med.eta*sin(2*med.thetaS)*exp(-1i*med.phiS)];

    Pm = A1 / A2;
end

function Pm = shTransfer(med)
    Pm = [ ...
        cos(med.phiS), -1i*sin(med.phiS)/(med.zeta*cos(med.thetaS)); ...
        -1i*med.zeta*cos(med.thetaS)*sin(med.phiS), cos(med.phiS)];
end

function out = cleanSmallImag(out)
    if isstruct(out)
        if numel(out) > 1
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
