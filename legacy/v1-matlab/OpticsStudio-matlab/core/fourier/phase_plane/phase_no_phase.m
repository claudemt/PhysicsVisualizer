function out = phase_no_phase(X, Y, params)
%PHASE_NO_PHASE Zero phase plane.
if nargin == 1 && ischar(X) && strcmpi(X, 'info')
    out = struct('Name', 'No phase', ...
        'Description', 'Identity phase plane. The object transmission remains purely amplitude modulated.');
    return
end
out = zeros(size(X)); %#ok<NASGU>
end
