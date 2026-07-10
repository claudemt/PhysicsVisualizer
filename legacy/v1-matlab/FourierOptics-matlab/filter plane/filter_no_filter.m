function out = filter_no_filter(XF, YF, params)
%FILTER_NO_FILTER Identity Fourier filter.
if nargin == 1 && ischar(XF) && strcmpi(XF, 'info')
    out = struct('Name', 'No filter', ...
        'Description', 'Identity transmission across the Fourier plane.');
    return
end
out = ones(size(XF)); %#ok<NASGU>
end
