function value = get_nested_field(s, dottedName)
%GET_NESTED_FIELD Read a struct field from a dotted path.
parts = regexp(char(string(dottedName)), '\.', 'split');
value = s;
for k = 1:numel(parts)
    value = value.(parts{k});
end
end
