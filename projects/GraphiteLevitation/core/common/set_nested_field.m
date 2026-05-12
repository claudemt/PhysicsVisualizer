function s = set_nested_field(s, dottedName, value)
%SET_NESTED_FIELD Set a struct field from a dotted path.
name = char(string(dottedName));
name = strtrim(regexprep(name, '\s*/\s*', '.'));
name = regexprep(name, '\s+', '');
parts = regexp(name, '\.', 'split');
if numel(parts) == 1
    s.(parts{1}) = value;
else
    head = parts{1};
    rest = strjoin(parts(2:end), '.');
    if ~isfield(s, head) || ~isstruct(s.(head))
        s.(head) = struct();
    end
    s.(head) = set_nested_field(s.(head), rest, value);
end
end
