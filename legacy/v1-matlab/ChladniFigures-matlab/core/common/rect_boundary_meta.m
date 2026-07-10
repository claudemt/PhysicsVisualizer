function meta = rect_boundary_meta(boundary)
%RECT_BOUNDARY_META Normalize rectangular boundary codes.
% Rectangular edge order is ULDR = up, left, down, right.

bc = upper(strtrim(char(string(boundary))));
switch lower(bc)
    case 'free'
        code = 'FFFF';
    case 'simply'
        code = 'SSSS';
    case 'clamped'
        code = 'CCCC';
    otherwise
        code = upper(bc);
end

if numel(code) ~= 4 || any(~ismember(code, 'CSF'))
    error('Rectangular boundary must be a 4-letter ULDR code using only C, S, F, e.g. CFFF, SSFF, or CFSF.');
end

meta = struct();
meta.solver_key = lower(code);
meta.title_tag = code;
meta.file_tag = code;
meta.code = code;
meta.top = code(1);
meta.left = code(2);
meta.bottom = code(3);
meta.right = code(4);
meta.is_all_free = strcmp(code, 'FFFF');
meta.is_all_simply = strcmp(code, 'SSSS');
meta.is_all_clamped = strcmp(code, 'CCCC');
end
