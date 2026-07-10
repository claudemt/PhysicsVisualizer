function out = latex_text(label_text)
%LATEX_TEXT Build a safe inline LaTeX text label for MATLAB graphics.
%
% Escapes underscores and spaces without relying on sprintf, which can emit
% warnings for sequences like "\ " when used in format strings.

if isstring(label_text)
    label_text = char(label_text);
end

label_text = strrep(label_text, '\\', '\\\\');
label_text = strrep(label_text, '_', '\_');
label_text = strrep(label_text, ' ', '\ ');
out = ['$\mathrm{' label_text '}$'];
end
