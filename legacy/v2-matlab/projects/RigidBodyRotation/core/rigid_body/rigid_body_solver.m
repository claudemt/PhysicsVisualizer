function result = rigid_body_solver(mode, inputData)
%RIGID_BODY_SOLVER Unified simulation entry point for rigid-body rotation.
%   result = rigid_body_solver('free', inputData)
%   result = rigid_body_solver('fixed', inputData)
%   result = rigid_body_solver('compare', inputData)
%
% The previous free/fixed/compare entry points were merged here so the
% project root can stay clean and dynamics code has a single public surface.

    if nargin < 1 || isempty(mode)
        error('A solver mode is required: free, fixed, or compare.');
    end
    if nargin < 2 || isempty(inputData)
        error('inputData is required.');
    end

    switch lower(char(string(mode)))
        case 'free'
            result = local_free_motion(inputData);
        case 'fixed'
            result = local_fixed_rotation(inputData);
        case {'compare', 'multi'}
            result = local_multi_compare(inputData);
        otherwise
            error('Unknown rigid body solver mode: %s.', char(string(mode)));
    end
end

function result = local_free_motion(inputData)
%RIGID_FREE_MOTION Free rigid-body rotation about the center of mass.
% Input fields:
%   I        [I1 I2 I3]
%   w0       [w1 w2 w3] in the body frame
%   phi0     rotation about the lab z-axis at t = 0
%   tEnd     final time
%   nSamples number of stored samples

    I = inputData.I(:);
    w0 = inputData.w0(:);
    t = linspace(0, inputData.tEnd, inputData.nSamples);
    Ib = diag(I);

    Lb0 = Ib * w0;
    Lmag = norm(Lb0);
    if Lmag < 1e-12
        error('Initial angular momentum is too small.');
    end

    e3lab = [0; 0; 1];
    Ralign = rigid_common_support('rotation_map', Lb0 / Lmag, e3lab);
    R0 = rigid_common_support('axis_angle', e3lab, inputData.phi0) * Ralign;
    q0 = rigid_common_support('rotm_to_quat', R0);

    y0 = [w0; q0];
    opts = odeset('RelTol', 1e-9, 'AbsTol', 1e-10);
    [~, Y] = ode113(@rhs, t, y0, opts);

    Wb = Y(:,1:3);
    Q = rigid_common_support('normalize_quat_array', Y(:,4:7));

    n = numel(t);
    Wlab = zeros(n,3);
    Lb = zeros(n,3);
    axisTips = zeros(n,3,3);
    Rall = zeros(3,3,n);
    for k = 1:n
        R = rigid_common_support('quat_to_rotm', Q(k,:).');
        wb = Wb(k,:).';
        lb = Ib * wb;
        Wlab(k,:) = (R * wb).';
        Lb(k,:) = lb.';
        axisTips(k,:,1) = R(:,1).';
        axisTips(k,:,2) = R(:,2).';
        axisTips(k,:,3) = R(:,3).';
        Rall(:,:,k) = R;
    end

    result = struct();
    result.mode = 'free';
    result.t = t(:);
    result.wBody = Wb;
    result.wLab = Wlab;
    result.LBody = Lb;
    result.R = Rall;
    result.axisTips = axisTips;
    result.input = inputData;
    result.constants.energy = 0.5 * sum((Wb.^2) .* reshape(I.', 1, 3), 2);
    result.constants.Lmag = sqrt(sum(Lb.^2, 2));
    result.constants.labL = repmat([0 0 Lmag], n, 1);

    function dydt = rhs(~, y)
        wb = y(1:3);
        q = y(4:7);
        dw = [((I(2) - I(3)) / I(1)) * wb(2) * wb(3); ...
              ((I(3) - I(1)) / I(2)) * wb(3) * wb(1); ...
              ((I(1) - I(2)) / I(3)) * wb(1) * wb(2)];
        dq = 0.5 * rigid_common_support('omega_matrix', wb) * q;
        dydt = [dw; dq];
    end
end


function result = local_fixed_rotation(inputData)
%RIGID_FIXED_ROTATION Heavy rigid body about a fixed point in gravity.
% This file supports general initial conditions, not only regular precession.
% Input fields:
%   I        [I1 I2 I3] about the fixed point, in body principal axes
%   aBody    vector from the fixed point to the center of mass, in body axes
%   mass     body mass
%   g        gravity magnitude
%   euler0   [phi theta psi] with a 3-1-3 convention
%   w0       [w1 w2 w3] initial body-frame angular velocity
%   tEnd     final time
%   nSamples number of stored samples

    I = inputData.I(:);
    aBody = inputData.aBody(:);
    m = inputData.mass;
    g = inputData.g;
    t = linspace(0, inputData.tEnd, inputData.nSamples);
    Ib = diag(I);

    q0 = rigid_common_support('euler313_to_quat', inputData.euler0(:));
    y0 = [inputData.w0(:); q0];

    opts = odeset('RelTol', 1e-9, 'AbsTol', 1e-10);
    [~, Y] = ode113(@rhs, t, y0, opts);

    Wb = Y(:,1:3);
    Q = rigid_common_support('normalize_quat_array', Y(:,4:7));

    n = numel(t);
    Wlab = zeros(n,3);
    Lb = zeros(n,3);
    axisTips = zeros(n,3,3);
    Rall = zeros(3,3,n);
    zcom = zeros(n,1);
    for k = 1:n
        R = rigid_common_support('quat_to_rotm', Q(k,:).');
        wb = Wb(k,:).';
        lb = Ib * wb;
        rcLab = R * aBody;
        Wlab(k,:) = (R * wb).';
        Lb(k,:) = lb.';
        axisTips(k,:,1) = R(:,1).';
        axisTips(k,:,2) = R(:,2).';
        axisTips(k,:,3) = R(:,3).';
        Rall(:,:,k) = R;
        zcom(k) = rcLab(3);
    end

    result = struct();
    result.mode = 'fixed';
    result.t = t(:);
    result.wBody = Wb;
    result.wLab = Wlab;
    result.LBody = Lb;
    result.R = Rall;
    result.axisTips = axisTips;
    result.input = inputData;
    result.constants.energy = 0.5 * sum((Wb.^2) .* reshape(I.', 1, 3), 2) + m * g * zcom;
    result.constants.Lmag = sqrt(sum(Lb.^2, 2));
    result.constants.labL = nan(n,3);

    function dydt = rhs(~, y)
        wb = y(1:3);
        q = y(4:7);
        R = rigid_common_support('quat_to_rotm', q);
        F_lab = [0; 0; -m * g];
        F_body = R.' * F_lab;
        tau = cross(aBody, F_body);
        dw = Ib \ (tau - cross(wb, Ib * wb));
        dq = 0.5 * rigid_common_support('omega_matrix', wb) * q;
        dydt = [dw; dq];
    end
end


function result = local_multi_compare(inputData)
%RIGID_MULTI_COMPARE Overlay up to five initial-condition sets.
% This helper runs either the free-rotation or fixed-point solver multiple
% times with shared physical parameters and different initial conditions.
%
% Free-mode compare rows:
%   [w1 w2 w3 phi0]
%
% Fixed-mode compare rows:
%   [phi theta psi w1 w2 w3]

    if ~isfield(inputData, 'mode')
        error('inputData.mode is required.');
    end
    if ~isfield(inputData, 'compareCases') || isempty(inputData.compareCases)
        error('compareCases is required for multi-IC comparison mode.');
    end

    baseMode = char(string(inputData.mode));
    cases = inputData.compareCases;
    nCases = size(cases, 1);
    if nCases < 1
        error('At least one compare row is required.');
    end
    if nCases > 5
        error('At most five compare rows are allowed.');
    end

    caseResults = cell(nCases, 1);
    caseInputs = cell(nCases, 1);
    caseLabels = cell(nCases, 1);

    for k = 1:nCases
        cInput = inputData;
        if isfield(cInput, 'compareCases')
            cInput = rmfield(cInput, 'compareCases');
        end
        cInput.compareMode = false;
        cInput.caseIndex = k;
        cInput.caseLabel = sprintf('p.%d', k);
        caseLabels{k} = cInput.caseLabel;

        switch lower(baseMode)
            case 'free'
                row = cases(k,:);
                cInput.w0 = row(1:3);
                cInput.phi0 = row(4);
                caseResults{k} = rigid_body_solver('free', cInput);

            case 'fixed'
                row = cases(k,:);
                cInput.euler0 = row(1:3);
                cInput.w0 = row(4:6);
                caseResults{k} = rigid_body_solver('fixed', cInput);

            otherwise
                error('Unknown comparison mode: %s.', baseMode);
        end

        caseInputs{k} = cInput;
    end

    result = struct();
    result.mode = [baseMode '_multi'];
    result.baseMode = baseMode;
    result.isMulti = true;
    result.nCases = nCases;
    result.caseLabels = caseLabels;
    result.caseInputs = caseInputs;
    result.caseResults = caseResults;
    result.t = caseResults{1}.t;
    result.input = inputData;
end

