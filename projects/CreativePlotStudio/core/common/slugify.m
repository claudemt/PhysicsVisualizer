function out = slugify(txt)
txt = lower(char(txt));
txt = regexprep(txt,'[^a-z0-9]+','_');
txt = regexprep(txt,'_+','_');
txt = regexprep(txt,'^_|_$','');
out = txt;
end
