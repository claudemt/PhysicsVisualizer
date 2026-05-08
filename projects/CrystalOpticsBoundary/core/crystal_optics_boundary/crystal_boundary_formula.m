function result = crystal_boundary_formula(cfg)
% crystal_boundary_formula
% Core numerical engine for isotropic (z>0) -> anisotropic crystal (z<0)
% boundary optics.
%
% Convention:
%   - interface: z = 0
%   - incident medium: isotropic, z > 0
%   - crystal: anisotropic dielectric, z < 0
%   - time factor: exp(i(k·r - omega t))
%   - crystal assumed lossless: epsilon is real-symmetric (or Hermitian)
%   - mu_r = 1 in both media
%
% Input (minimal):
%   cfg.n_inc                       scalar, incident refractive index
%   cfg.k_inc                       3x1 or 1x3, incident direction, must satisfy k_inc(3) < 0
%   cfg.pol.type                    1 | 2 | 3
%   cfg.eps_lab                     3x3 lab-frame relative permittivity tensor
%   OR
%   cfg.eps_diag                    [eps1 eps2 eps3]
%   cfg.orientation.mode            'none' | 'matrix' | 'euler_zyx' | 'axis'
%
% Polarization modes:
%   1) cfg.pol.vector               arbitrary 3-vector, auto-projected to E ⟂ k_inc and normalized
%   2) cfg.pol.angle_deg            E = cos(alpha)*sHat + sin(alpha)*pHatInc
%   3) cfg.pol.num_samples          sweep alpha uniformly in [0, 180 deg)
%
%   result.common                   shared geometry/tensor information
%   result.single                   for pol.type = 1 or 2
%   result.sweep                    for pol.type = 3 (cell array of single-case results)
%
% Notes:
%   - For generic incidence, the transmitted field splits into two branches.
%   - If the two physical transmitted basis states share the same q_z, the code
%     treats them as a degenerate branch; in that case the combined transmitted
%     field is used. This is the branch that can generate a cone/ring under a
%     polarization sweep near optic-axis conditions.

cfg = localFillDefaults(cfg);
state = localPrepareState(cfg);

result = struct();
result.common = localBuildCommonOutput(state);
result.input = cfg;

switch state.polType
    case 1
        Einc = localNormalizeIncidentVector(cfg.pol.vector, state.kIncHat);
        result.case_type = 'single';
        result.single = localSolveSingle(state, Einc);

    case 2
        alpha = state.polAngleRad;
        Einc = cos(alpha) * state.sHat + sin(alpha) * state.pHatInc;
        result.case_type = 'single';
        result.single = localSolveSingle(state, Einc);
        result.common.angle_reference = 'E_inc = cos(alpha)*sHat + sin(alpha)*pHatInc';

    case 3
        if isfield(cfg.pol, 'angle_list_deg') && ~isempty(cfg.pol.angle_list_deg)
            alphaListDeg = cfg.pol.angle_list_deg(:).';
        else
            alphaListDeg = linspace(0, 180, state.numSamples + 1);
            alphaListDeg(end) = [];
        end
        alphaListRad = alphaListDeg * pi / 180;

        result.case_type = 'sweep';
        result.sweep = struct();
        result.sweep.alpha_deg = alphaListDeg(:);
        result.sweep.alpha_rad = alphaListRad(:);
        result.sweep.sample = cell(numel(alphaListRad), 1);

        for i = 1:numel(alphaListRad)
            Einc = cos(alphaListRad(i)) * state.sHat + sin(alphaListRad(i)) * state.pHatInc;
            result.sweep.sample{i} = localSolveSingle(state, Einc);
        end

    otherwise
        error('Unsupported polarization type.');
end
end

function cfg = localFillDefaults(cfg)
if nargin < 1 || isempty(cfg)
    cfg = struct();
end

if ~isfield(cfg, 'n_inc') || isempty(cfg.n_inc)
    cfg.n_inc = 1.0;
end

if ~isfield(cfg, 'k_inc') || isempty(cfg.k_inc)
    cfg.k_inc = [0.2; 0.1; -sqrt(1 - 0.2^2 - 0.1^2)];
end

if ~isfield(cfg, 'pol') || isempty(cfg.pol)
    cfg.pol = struct();
end
if ~isfield(cfg.pol, 'type') || isempty(cfg.pol.type)
    cfg.pol.type = 2;
end
if ~isfield(cfg.pol, 'vector') || isempty(cfg.pol.vector)
    cfg.pol.vector = [1; 0; 0];
end
if ~isfield(cfg.pol, 'angle_deg') || isempty(cfg.pol.angle_deg)
    cfg.pol.angle_deg = 0.0;
end
if ~isfield(cfg.pol, 'num_samples') || isempty(cfg.pol.num_samples)
    cfg.pol.num_samples = 181;
end

if ~isfield(cfg, 'orientation') || isempty(cfg.orientation)
    cfg.orientation = struct();
end
if ~isfield(cfg.orientation, 'mode') || isempty(cfg.orientation.mode)
    cfg.orientation.mode = 'none';
end
if ~isfield(cfg.orientation, 'euler_deg') || isempty(cfg.orientation.euler_deg)
    cfg.orientation.euler_deg = [0, 0, 0];
end
if ~isfield(cfg.orientation, 'R')
    cfg.orientation.R = [];
end
if ~isfield(cfg.orientation, 'optic_axis')
    cfg.orientation.optic_axis = [];
end

if ~isfield(cfg, 'tol') || isempty(cfg.tol)
    cfg.tol = struct();
end
if ~isfield(cfg.tol, 'root') || isempty(cfg.tol.root)
    cfg.tol.root = 1e-6;
end
if ~isfield(cfg.tol, 'null') || isempty(cfg.tol.null)
    cfg.tol.null = 1e-8;
end
if ~isfield(cfg.tol, 'imag') || isempty(cfg.tol.imag)
    cfg.tol.imag = 1e-9;
end
if ~isfield(cfg.tol, 'rank') || isempty(cfg.tol.rank)
    cfg.tol.rank = 1e-8;
end
if ~isfield(cfg.tol, 'power') || isempty(cfg.tol.power)
    cfg.tol.power = 1e-10;
end
if ~isfield(cfg.tol, 'q_group') || isempty(cfg.tol.q_group)
    cfg.tol.q_group = 1e-7;
end
if ~isfield(cfg.tol, 'rcond_warn') || isempty(cfg.tol.rcond_warn)
    cfg.tol.rcond_warn = 1e-12;
end
if ~isfield(cfg.tol, 'linear') || isempty(cfg.tol.linear)
    cfg.tol.linear = 1e-8;
end
end

function state = localPrepareState(cfg)
state = struct();
state.nInc = cfg.n_inc;
state.tol = cfg.tol;

state.epsLab = localBuildEpsilonLab(cfg);
[state.epsPrincipal, state.principalAxesLab, state.opticAxesLab, state.crystalType] = ...
    localPrincipalSystem(state.epsLab);

kIncHat = cfg.k_inc(:);
kIncHat = kIncHat / norm(kIncHat);
if real(kIncHat(3)) >= 0
    error('k_inc must point from z>0 to z<0, so k_inc(3) must be negative after normalization.');
end
state.kIncHat = kIncHat;
state.qInc = state.nInc * state.kIncHat;
state.qRef = [state.qInc(1); state.qInc(2); -state.qInc(3)];
state.qRefHat = state.qRef / norm(state.qRef);

[state.sHat, state.pHatInc, state.pHatRef] = localBuildSPBasis(state.kIncHat);

state.polType = localPolarizationType(cfg.pol.type);
state.polAngleRad = cfg.pol.angle_deg * pi / 180;
state.numSamples = max(3, round(cfg.pol.num_samples));
end

function epsLab = localBuildEpsilonLab(cfg)
if isfield(cfg, 'eps_lab') && ~isempty(cfg.eps_lab)
    epsLab = cfg.eps_lab;
else
    if ~isfield(cfg, 'eps_diag') || isempty(cfg.eps_diag)
        error('Please provide either cfg.eps_lab or cfg.eps_diag.');
    end
    epsDiag = cfg.eps_diag(:);
    if numel(epsDiag) ~= 3
        error('cfg.eps_diag must contain exactly 3 entries.');
    end

    mode = lower(strtrim(cfg.orientation.mode));
    switch mode
        case 'none'
            R = eye(3);
        case 'matrix'
            R = cfg.orientation.R;
            if isempty(R) || ~isequal(size(R), [3, 3])
                error('cfg.orientation.R must be a 3x3 matrix.');
            end
        case 'euler_zyx'
            ang = cfg.orientation.euler_deg(:) * pi / 180;
            if numel(ang) ~= 3
                error('cfg.orientation.euler_deg must have 3 entries [alpha beta gamma].');
            end
            R = localRotZ(ang(1)) * localRotY(ang(2)) * localRotX(ang(3));
        case 'axis'
            if isempty(cfg.orientation.optic_axis)
                error('cfg.orientation.optic_axis is required for orientation.mode = ''axis''.');
            end
            d12 = abs(epsDiag(1) - epsDiag(2));
            d23 = abs(epsDiag(2) - epsDiag(3));
            d13 = abs(epsDiag(1) - epsDiag(3));
            if min([d12, d23, d13]) > 1e-10
                error(['orientation.mode = ''axis'' only fully specifies a uniaxial crystal. ', ...
                       'For biaxial eps_diag, please use orientation.mode = ''matrix'' or ''euler_zyx''.']);
            end
            R0 = localTriadFromAxis(cfg.orientation.optic_axis(:));
            if d12 <= d23 && d12 <= d13
                R = R0;                          % optic axis = principal axis 3
            elseif d23 <= d12 && d23 <= d13
                R = [R0(:,3), R0(:,1), R0(:,2)]; % optic axis = principal axis 1
            else
                R = [R0(:,1), R0(:,3), R0(:,2)]; % optic axis = principal axis 2
            end
        otherwise
            error('Unknown orientation mode: %s', cfg.orientation.mode);
    end

    epsLab = R * diag(epsDiag) * R.';
end

epsLab = (epsLab + epsLab') / 2;
end

function polType = localPolarizationType(inType)
if isnumeric(inType)
    polType = round(inType);
    return;
end

s = lower(strtrim(char(inType)));
switch s
    case {'1', 'vector', 'raw', 'arbitrary'}
        polType = 1;
    case {'2', 'angle', 'sp', 'transverse-angle'}
        polType = 2;
    case {'3', 'natural', 'sweep', 'unpolarized'}
        polType = 3;
    otherwise
        error('Unknown polarization type.');
end
end

function common = localBuildCommonOutput(state)
common = struct();
common.convention = 'q = k/k0, k0 = omega/c, time factor exp(i(k·r - omega t))';
common.n_inc = state.nInc;
common.eps_lab = state.epsLab;
common.eps_principal = state.epsPrincipal;
common.principal_axes_lab = state.principalAxesLab;
common.optic_axes_lab = state.opticAxesLab;
common.crystal_type = state.crystalType;
common.k_inc_hat = state.kIncHat;
common.q_inc = state.qInc;
common.q_ref = state.qRef;
common.q_ref_hat = state.qRefHat;
common.sHat = state.sHat;
common.pHatInc = state.pHatInc;
common.pHatRef = state.pHatRef;
common.assumptions = 'real-symmetric epsilon, mu_r = 1, single flat interface z = 0';
end

function single = localSolveSingle(state, Einc)
Einc = localNormalizeIncidentVector(Einc, state.kIncHat);
Hinc = cross(state.qInc, Einc);
Sinc = real(cross(Einc, conj(Hinc)));
Pin = -real(Sinc(3));
if Pin <= 0
    error('Incident normal power is non-positive. Check k_inc and polarization input.');
end

basisModes = localSolvePhysicalTransmittedBasis(state.epsLab, state.qInc(1), state.qInc(2), state.tol);

Ers = state.sHat;
Erp = state.pHatRef;
Hrs = cross(state.qRef, Ers);
Hrp = cross(state.qRef, Erp);

A = [Ers(1), Erp(1), -basisModes(1).E(1), -basisModes(2).E(1); ...
     Ers(2), Erp(2), -basisModes(1).E(2), -basisModes(2).E(2); ...
     Hrs(1), Hrp(1), -basisModes(1).H(1), -basisModes(2).H(1); ...
     Hrs(2), Hrp(2), -basisModes(1).H(2), -basisModes(2).H(2)];

rhs = -[Einc(1); Einc(2); Hinc(1); Hinc(2)];

if rcond(A) < state.tol.rcond_warn
    coeff = pinv(A) * rhs;
    solveMethod = 'pinv';
else
    coeff = A \ rhs;
    solveMethod = 'backslash';
end

rs = coeff(1);
rp = coeff(2);
tt = coeff(3:4);

Eref = rs * Ers + rp * Erp;
Href = cross(state.qRef, Eref);
Sref = real(cross(Eref, conj(Href)));
R = max(0, real(Sref(3)) / Pin);

single = struct();
single.solve_method = solveMethod;
single.incident = struct();
single.incident.E = Einc;
single.incident.H = Hinc;
single.incident.S = Sinc;
single.incident.S_hat = localSafeRealDirection(Sinc);
single.incident.E_linear_dir = localTryLinearDirection(Einc, state.tol.linear);
single.incident.power_z_in = Pin;

single.reflection = struct();
single.reflection.q = state.qRef;
single.reflection.q_hat = state.qRefHat;
single.reflection.rs = rs;
single.reflection.rp = rp;
single.reflection.jones_sp = [rs; rp];
single.reflection.E = Eref;
single.reflection.H = Href;
single.reflection.S = Sref;
single.reflection.S_hat = localSafeRealDirection(Sref);
single.reflection.E_linear_dir = localTryLinearDirection(Eref, state.tol.linear);
single.reflection.power_ratio = R;

single.transmission = struct();
single.transmission.basis = basisModes;
single.transmission.coefficients = tt;

sameQz = abs(basisModes(1).q(3) - basisModes(2).q(3)) <= ...
         state.tol.q_group * max([1, abs(basisModes(1).q(3)), abs(basisModes(2).q(3))]);

if sameQz
    q = basisModes(1).q;
    Edeg = tt(1) * basisModes(1).E + tt(2) * basisModes(2).E;
    Hdeg = cross(q, Edeg);
    Ddeg = state.epsLab * Edeg;
    Sdeg = real(cross(Edeg, conj(Hdeg)));

    branch = localBuildBranchStruct(q, Edeg, Hdeg, Ddeg, Sdeg, Pin, true, tt, basisModes, state.tol.linear);

    single.transmission.isDegenerate = true;
    single.transmission.branch = branch;
    Ttotal = branch.power_ratio;
else
    branch(1) = localBuildBranchStruct(basisModes(1).q, tt(1) * basisModes(1).E, ...
        tt(1) * basisModes(1).H, tt(1) * basisModes(1).D, abs(tt(1))^2 * basisModes(1).S, ...
        Pin, false, tt(1), basisModes(1), state.tol.linear);

    branch(2) = localBuildBranchStruct(basisModes(2).q, tt(2) * basisModes(2).E, ...
        tt(2) * basisModes(2).H, tt(2) * basisModes(2).D, abs(tt(2))^2 * basisModes(2).S, ...
        Pin, false, tt(2), basisModes(2), state.tol.linear);

    single.transmission.isDegenerate = false;
    single.transmission.branch = branch;
    Ttotal = branch(1).power_ratio + branch(2).power_ratio;
end

single.energy = struct();
single.energy.R = R;
single.energy.T_total = Ttotal;
single.energy.balance = R + Ttotal - 1;
end

function branch = localBuildBranchStruct(q, E, H, D, S, Pin, isDegenerate, coeff, basisInfo, tolLinear)
branch = struct();
branch.q = q;
branch.q_hat = localWaveNormalDirection(q);
branch.E = E;
branch.E_norm = localSafeComplexNormalize(E);
branch.E_linear_dir = localTryLinearDirection(E, tolLinear);
branch.H = H;
branch.H_norm = localSafeComplexNormalize(H);
branch.D = D;
branch.D_norm = localSafeComplexNormalize(D);
branch.D_linear_dir = localTryLinearDirection(D, tolLinear);
branch.S = S;
branch.S_hat = localSafeRealDirection(S);
branch.Sz = real(S(3));
branch.qz = q(3);
branch.isDegenerate = isDegenerate;
branch.isPropagating = abs(imag(q(3))) <= 1e-9;
branch.coefficient = coeff;
branch.basis = basisInfo;
branch.power_ratio = max(0, -real(S(3)) / Pin);
end

function modes = localSolvePhysicalTransmittedBasis(epsLab, qx, qy, tol)
poly = localQzPolynomial(epsLab, qx, qy);
qzRoots = roots(poly(:).');
qzGroups = localClusterRoots(qzRoots(:), tol.root);

candidates = struct([]);
for ig = 1:numel(qzGroups)
    qz = qzGroups(ig);
    q = [qx; qy; qz];
    q2 = q.' * q;
    M = epsLab - q2 * eye(3) + q * q.';
    B = localNullspace(M, tol.null);

    if ~localIsPhysicalGroup(q, epsLab, B, tol)
        continue;
    end

    for j = 1:size(B, 2)
        E = B(:, j);
        E = E / norm(E);
        E = localFixPhase(E);
        H = cross(q, E);
        D = epsLab * E;
        S = real(cross(E, conj(H)));

        cand = struct();
        cand.q = q;
        cand.qzGroup = qz;
        cand.E = E;
        cand.H = H;
        cand.D = D;
        cand.S = S;
        cand.ifaceColumn = [E(1); E(2); H(1); H(2)];
        cand.nullity = size(B, 2);
        cand.isPropagating = abs(imag(qz)) <= tol.imag;

        if isempty(candidates)
            candidates = cand;
        else
            candidates(end + 1) = cand; %#ok<AGROW>
        end
    end
end

if isempty(candidates)
    error('No physical transmitted basis state found.');
end

sortKey = zeros(numel(candidates), 2);
for i = 1:numel(candidates)
    sortKey(i, :) = [real(candidates(i).qzGroup), imag(candidates(i).qzGroup)];
end
[~, idx] = sortrows(sortKey, [1, 2]);
candidates = candidates(idx);

modes = localPickIndependentCandidates(candidates, 2, tol.rank);
if numel(modes) < 2
    error('Could not build two independent transmitted basis states.');
end
end

function tf = localIsPhysicalGroup(q, epsLab, B, tol)
qz = q(3);
if abs(imag(qz)) > tol.imag
    tf = imag(qz) < 0;
    return;
end

if real(qz) < 0
    tf = true;
    return;
end

tf = false;
for j = 1:size(B, 2)
    E = B(:, j);
    E = E / norm(E);
    H = cross(q, E);
    S = real(cross(E, conj(H)));
    if real(S(3)) < -tol.power
        tf = true;
        return;
    end
end

% fallback for numerical edge cases very close to grazing/degeneracy
q2 = q.' * q;
M = epsLab - q2 * eye(3) + q * q.';
resid = norm(M * B, 'fro');
tf = resid < 1e-6;
end

function modes = localPickIndependentCandidates(candidates, nWanted, tolRank)
C = zeros(4, 0);
r0 = 0;
modes = struct([]);

for i = 1:numel(candidates)
    c = candidates(i).ifaceColumn(:);
    if isempty(C)
        r1 = rank(c, tolRank);
    else
        r1 = rank([C, c], tolRank);
    end

    if r1 > r0
        if isempty(modes)
            modes = candidates(i);
        else
            modes(end + 1) = candidates(i); %#ok<AGROW>
        end
        C = [C, c]; %#ok<AGROW>
        r0 = r1;
        if numel(modes) >= nWanted
            break;
        end
    end
end
end

function poly = localQzPolynomial(epsLab, qx, qy)
P = cell(3, 3);
P{1, 1} = [-1, 0, epsLab(1, 1) - qy^2];
P{1, 2} = [epsLab(1, 2) + qx * qy];
P{1, 3} = [qx, epsLab(1, 3)];

P{2, 1} = [epsLab(2, 1) + qx * qy];
P{2, 2} = [-1, 0, epsLab(2, 2) - qx^2];
P{2, 3} = [qy, epsLab(2, 3)];

P{3, 1} = [qx, epsLab(3, 1)];
P{3, 2} = [qy, epsLab(3, 2)];
P{3, 3} = [epsLab(3, 3) - qx^2 - qy^2];

poly = localPolyAdd(localPolyAdd(conv(conv(P{1,1}, P{2,2}), P{3,3}), ...
                                  conv(conv(P{1,2}, P{2,3}), P{3,1})), ...
                    conv(conv(P{1,3}, P{2,1}), P{3,2}));
poly = localPolySub(poly, conv(conv(P{1,3}, P{2,2}), P{3,1}));
poly = localPolySub(poly, conv(conv(P{1,1}, P{2,3}), P{3,2}));
poly = localPolySub(poly, conv(conv(P{1,2}, P{2,1}), P{3,3}));
poly = localPolyTrim(poly);
end

function out = localPolyAdd(a, b)
na = numel(a);
nb = numel(b);
n = max(na, nb);
a = [zeros(1, n - na), a];
b = [zeros(1, n - nb), b];
out = a + b;
end

function out = localPolySub(a, b)
out = localPolyAdd(a, -b);
end

function out = localPolyTrim(a)
out = a;
while numel(out) > 1 && abs(out(1)) < 1e-14
    out(1) = [];
end
end

function qzGroups = localClusterRoots(qzRoots, tolRoot)
used = false(numel(qzRoots), 1);
qzGroups = [];

for i = 1:numel(qzRoots)
    if used(i)
        continue;
    end
    idxGroup = i;
    used(i) = true;

    for j = i + 1:numel(qzRoots)
        if used(j)
            continue;
        end
        scale = max([1, abs(qzRoots(i)), abs(qzRoots(j))]);
        if abs(qzRoots(j) - qzRoots(i)) <= tolRoot * scale
            idxGroup(end + 1) = j; %#ok<AGROW>
            used(j) = true;
        end
    end

    qzGroups(end + 1, 1) = mean(qzRoots(idxGroup)); %#ok<AGROW>
end
end

function B = localNullspace(M, tolNull)
[~, S, V] = svd(M);
s = diag(S);
if isempty(s)
    B = eye(size(M, 2));
    return;
end
th = tolNull * max(1, s(1));
idx = find(s <= th);
if isempty(idx)
    [~, idxMin] = min(s);
    idx = idxMin;
end
B = V(:, idx);
end

function [epsPrincipal, principalAxesLab, opticAxesLab, crystalType] = localPrincipalSystem(epsLab)
[V, D] = eig((epsLab + epsLab') / 2);
[epsPrincipal, idx] = sort(real(diag(D)), 'ascend');
principalAxesLab = V(:, idx);

% enforce right-handed frame if possible
if det(real(principalAxesLab)) < 0
    principalAxesLab(:, 1) = -principalAxesLab(:, 1);
end

opticAxesLab = [];
rel12 = abs(epsPrincipal(1) - epsPrincipal(2)) / max(1, abs(epsPrincipal(2)));
rel23 = abs(epsPrincipal(2) - epsPrincipal(3)) / max(1, abs(epsPrincipal(3)));

if rel12 < 1e-10 && rel23 < 1e-10
    crystalType = 'isotropic';
    return;
elseif rel12 < 1e-10
    crystalType = 'uniaxial';
    opticAxesLab = principalAxesLab(:, 3);
elseif rel23 < 1e-10
    crystalType = 'uniaxial';
    opticAxesLab = principalAxesLab(:, 1);
else
    crystalType = 'biaxial';
    vSq = 1 ./ epsPrincipal(:);
    tanXi = sqrt((vSq(1) - vSq(2)) / (vSq(2) - vSq(3)));
    xi = atan(tanXi);
    d1 = [sin(xi); 0; cos(xi)];
    d2 = [-sin(xi); 0; cos(xi)];
    opticAxesLab = principalAxesLab * [d1, d2];
end
end

function [sHat, pHatInc, pHatRef] = localBuildSPBasis(kIncHat)
zHat = [0; 0; 1];
sHat = cross(zHat, kIncHat);
if norm(sHat) < 1e-12
    trial = [1; 0; 0];
    sHat = trial - kIncHat * (kIncHat' * trial);
    if norm(sHat) < 1e-12
        trial = [0; 1; 0];
        sHat = trial - kIncHat * (kIncHat' * trial);
    end
end
sHat = sHat / norm(sHat);

pHatInc = cross(sHat, kIncHat);
pHatInc = pHatInc / norm(pHatInc);

kRefHat = [kIncHat(1); kIncHat(2); -kIncHat(3)];
kRefHat = kRefHat / norm(kRefHat);
pHatRef = cross(sHat, kRefHat);
pHatRef = pHatRef / norm(pHatRef);
end

function v = localNormalizeIncidentVector(v, kIncHat)
v = v(:);
v = v - kIncHat * (kIncHat' * v);
if norm(v) < 1e-12
    error('Incident polarization became zero after projection onto the plane transverse to k_inc.');
end
v = v / norm(v);
end

function dir = localWaveNormalDirection(q)
if norm(imag(q)) <= 1e-8 * max(1, norm(real(q)))
    dir = real(q) / norm(real(q));
else
    dir = NaN(3, 1);
end
end

function dir = localSafeRealDirection(v)
vr = real(v(:));
if norm(vr) < 1e-14
    dir = NaN(3, 1);
else
    dir = vr / norm(vr);
end
end

function vn = localSafeComplexNormalize(v)
if norm(v) < 1e-14
    vn = NaN(size(v));
else
    vn = v / norm(v);
end
end

function dir = localTryLinearDirection(v, tolLinear)
dir = NaN(3, 1);
if norm(v) < 1e-14
    return;
end
w = localFixPhase(v(:));
if norm(imag(w)) <= tolLinear * max(1, norm(real(w)))
    wr = real(w);
    if norm(wr) > 1e-14
        dir = wr / norm(wr);
    end
end
end

function v = localFixPhase(v)
idx = find(abs(v) > 1e-12, 1, 'first');
if isempty(idx)
    return;
end
v = v * exp(-1i * angle(v(idx)));
[~, j] = max(abs(v));
if real(v(j)) < 0
    v = -v;
end
end

function R = localTriadFromAxis(u3)
u3 = u3(:);
u3 = u3 / norm(u3);
ref = [0; 0; 1];
if abs(dot(u3, ref)) > 0.9
    ref = [1; 0; 0];
end
u1 = cross(ref, u3);
u1 = u1 / norm(u1);
u2 = cross(u3, u1);
u2 = u2 / norm(u2);
R = [u1, u2, u3];
end

function R = localRotX(a)
R = [1, 0, 0; 0, cos(a), -sin(a); 0, sin(a), cos(a)];
end

function R = localRotY(a)
R = [cos(a), 0, sin(a); 0, 1, 0; -sin(a), 0, cos(a)];
end

function R = localRotZ(a)
R = [cos(a), -sin(a), 0; sin(a), cos(a), 0; 0, 0, 1];
end
