Creative Plot Studio

Run:
main

Structure:
app/      GUI only: launcher, tabs, panels
core/     all drawing implementation
docs/     plain-text documentation
output/   exported images
.cache/   temporary export cache

Core project layout:
core/<domain>/<category>/<project>/render.m
core/<domain>/<category>/<project>/notes.txt

Notes are concise plain text. Export Current View writes first to .cache and then copies to output, preserving manual rotations.


v8 fixed:
- GUI Docs tab removed.
- Core render scripts are executed through app/tabs/run_core_script.m.
- This avoids MATLAB static-workspace errors when render.m creates temporary variables such as v.
