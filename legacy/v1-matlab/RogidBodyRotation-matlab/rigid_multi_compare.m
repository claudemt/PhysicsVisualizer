function result = rigid_multi_compare(inputData)
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
                caseResults{k} = rigid_free_motion(cInput);

            case 'fixed'
                row = cases(k,:);
                cInput.euler0 = row(1:3);
                cInput.w0 = row(4:6);
                caseResults{k} = rigid_fixed_rotation(cInput);

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
