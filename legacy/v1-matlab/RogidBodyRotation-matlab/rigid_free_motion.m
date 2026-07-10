function result = rigid_free_motion(inputData)
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
