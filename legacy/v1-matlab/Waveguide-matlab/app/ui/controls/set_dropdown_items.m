function set_dropdown_items(dd, items, fallback)
%SET_DROPDOWN_ITEMS Replace dropdown items while preserving a valid value.

current = char(string(dd.Value));
dd.Items = items;
if any(strcmp(items, current))
    dd.Value = current;
else
    dd.Value = fallback;
end
end
