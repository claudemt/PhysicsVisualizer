function out = normalize_array(in)
%NORMALIZE_ARRAY Normalize to unit peak while preserving zeros.

peak = max(abs(in(:)));
if peak < eps
    out = in;
else
    out = in ./ peak;
end
end
