function result = rigid_fixed_rotation(inputData)
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
