function out = sanitize_waveguide_name(text_value)
%SANITIZE_WAVEGUIDE_NAME Make a filesystem-safe name.

out = char(string(text_value));
out = regexprep(out, '[^A-Za-z0-9_\-\.]+', '_');
out = regexprep(out, '_+', '_');
out = regexprep(out, '^_+|_+$', '');
if isempty(out)
    out = 'waveguide';
end
end
