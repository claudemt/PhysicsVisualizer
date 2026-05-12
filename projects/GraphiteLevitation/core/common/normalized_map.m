function Z = normalized_map(Z)
%NORMALIZED_MAP Zero-min, unit-max map for display.
Z = Z - min(Z(:));
mx = max(Z(:));
if mx > 0, Z = Z / mx; end
end
