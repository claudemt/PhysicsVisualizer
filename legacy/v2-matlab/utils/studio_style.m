function out = studio_style(action, varargin)
%STUDIO_STYLE Shared visual tokens and best-effort UI styling.
%
% This helper intentionally stays conservative: MATLAB UI component styling
% support differs across releases, so every component mutation is guarded.

if nargin < 1 || isempty(action)
    action = 'tokens';
end

action = lower(strrep(char(string(action)), ' ', '_'));
switch action
    case {'tokens','theme'}
        out = local_tokens();
    case {'apply_component','component'}
        out = local_apply_component(varargin{:});
    case {'apply_panel','panel'}
        out = local_apply_panel(varargin{:});
    case {'apply_button','button'}
        out = local_apply_button(varargin{:});
    case {'apply_label','label'}
        out = local_apply_label(varargin{:});
    case {'apply_grid','grid'}
        out = local_apply_grid(varargin{:});
    case {'apply_axes','axes'}
        out = local_apply_axes(varargin{:});
    case {'apply_legend','legend'}
        out = local_apply_legend(varargin{:});
    case {'notes_css','css'}
        out = local_notes_css();
    case {'visible_colormap','visible_cmap','colormap_visible'}
        if isempty(varargin), n = 256; else, n = varargin{1}; end
        out = local_visible_colormap(n);
    otherwise
        error('Unknown studio_style action: %s', action);
end
end

function s = local_tokens()
s = struct();
s.background = [0.955 0.960 0.965];
s.panelBackground = [0.985 0.987 0.990];
s.canvasBackground = [1.000 1.000 1.000];
s.controlBackground = [1.000 1.000 1.000];
s.fieldBackground = [1.000 1.000 1.000];
s.primary = [0.125 0.290 0.500];
s.primaryText = [1.000 1.000 1.000];
s.secondary = [0.910 0.925 0.940];
s.text = [0.105 0.125 0.150];
s.mutedText = [0.365 0.405 0.455];
s.border = [0.760 0.790 0.830];
s.softBorder = [0.865 0.885 0.910];
s.error = [0.690 0.180 0.180];
s.fontName = 'Segoe UI';
s.monoFontName = 'Consolas';
s.axesFontName = 'Times New Roman';
s.fontSize = 12;
s.smallFontSize = 11;
s.buttonFontSize = 12;
s.sectionFontSize = 12;
s.axesFontSize = 26;
s.axesTitleFontSize = 30;
s.controlHeight = 26;
s.toolbarHeight = 26;
s.sectionPadding = [10 9 10 9];
s.rootPadding = [10 10 10 10];
s.panelPadding = [8 8 8 8];
s.tightPadding = [6 6 6 6];
s.gap = 8;
s.smallGap = 5;
end

function h = local_apply_component(h, role)
if nargin < 2 || isempty(role), role = 'field'; end
s = local_tokens();
if isempty(h) || any(~isgraphics(h)), return; end
role = lower(char(string(role)));
try, h.FontName = s.fontName; catch, end
try, h.FontSize = s.fontSize; catch, end
switch role
    case {'field','edit','dropdown','list','listbox','textarea'}
        try, h.BackgroundColor = s.fieldBackground; catch, end
        try, h.FontColor = s.text; catch, end
    case {'text','report','notes'}
        try, h.BackgroundColor = s.controlBackground; catch, end
        try, h.FontColor = s.text; catch, end
    case {'mono','code'}
        try, h.FontName = s.monoFontName; catch, end
        try, h.BackgroundColor = s.controlBackground; catch, end
        try, h.FontColor = s.text; catch, end
    case {'empty','muted'}
        try, h.FontColor = s.mutedText; catch, end
end
end

function h = local_apply_panel(h, role)
if nargin < 2 || isempty(role), role = 'panel'; end
s = local_tokens();
if isempty(h) || any(~isgraphics(h)), return; end
try, h.BackgroundColor = s.panelBackground; catch, end
try, h.ForegroundColor = s.text; catch, end
try, h.FontName = s.fontName; catch, end
try, h.FontSize = s.sectionFontSize; catch, end
role = lower(char(string(role)));
if strcmp(role, 'flat')
    try, h.BorderType = 'none'; catch, end
end
end

function h = local_apply_button(h, role)
if nargin < 2 || isempty(role), role = 'secondary'; end
s = local_tokens();
if isempty(h) || any(~isgraphics(h)), return; end
role = lower(char(string(role)));
try, h.FontName = s.fontName; catch, end
try, h.FontSize = s.buttonFontSize; catch, end
try, h.FontWeight = 'normal'; catch, end
switch role
    case {'primary','generate','run'}
        try, h.BackgroundColor = s.primary; catch, end
        try, h.FontColor = s.primaryText; catch, end
    case {'danger','delete'}
        try, h.BackgroundColor = [0.965 0.900 0.895]; catch, end
        try, h.FontColor = s.error; catch, end
    otherwise
        try, h.BackgroundColor = s.secondary; catch, end
        try, h.FontColor = s.text; catch, end
end
end

function h = local_apply_label(h, role)
if nargin < 2 || isempty(role), role = 'label'; end
s = local_tokens();
if isempty(h) || any(~isgraphics(h)), return; end
try, h.FontName = s.fontName; catch, end
try, h.FontSize = s.fontSize; catch, end
try, h.FontColor = s.text; catch, end
if any(strcmpi(char(string(role)), {'muted','hint','empty'}))
    try, h.FontColor = s.mutedText; catch, end
    try, h.FontSize = s.smallFontSize; catch, end
end
end

function h = local_apply_grid(h, role)
if nargin < 2 || isempty(role), role = 'normal'; end
s = local_tokens();
if isempty(h) || any(~isgraphics(h)), return; end
role = lower(char(string(role)));
switch role
    case 'root'
        try, h.Padding = s.rootPadding; catch, end
        try, h.RowSpacing = s.gap; catch, end
        try, h.ColumnSpacing = s.gap; catch, end
    case 'panel'
        try, h.Padding = s.panelPadding; catch, end
        try, h.RowSpacing = s.gap; catch, end
        try, h.ColumnSpacing = s.gap; catch, end
    case 'tight'
        try, h.Padding = [0 0 0 0]; catch, end
        try, h.RowSpacing = s.smallGap; catch, end
        try, h.ColumnSpacing = s.smallGap; catch, end
end
end

function cmap = local_visible_colormap(n)
if nargin < 1 || isempty(n), n = 256; end
lambda = linspace(380, 780, n);
rgb = zeros(n, 3);
for ii = 1:n
    l = lambda(ii);
    if l >= 380 && l < 440
        r = -(l - 440) / (440 - 380); g = 0; b = 1;
    elseif l >= 440 && l < 490
        r = 0; g = (l - 440) / (490 - 440); b = 1;
    elseif l >= 490 && l < 510
        r = 0; g = 1; b = -(l - 510) / (510 - 490);
    elseif l >= 510 && l < 580
        r = (l - 510) / (580 - 510); g = 1; b = 0;
    elseif l >= 580 && l < 645
        r = 1; g = -(l - 645) / (645 - 580); b = 0;
    elseif l >= 645 && l <= 780
        r = 1; g = 0; b = 0;
    else
        r = 0; g = 0; b = 0;
    end
    if l >= 380 && l < 420
        f = 0.3 + 0.7*(l - 380)/(420 - 380);
    elseif l >= 420 && l <= 700
        f = 1.0;
    elseif l > 700 && l <= 780
        f = 0.3 + 0.7*(780 - l)/(780 - 700);
    else
        f = 0.0;
    end
    gamma = 0.8;
    rgb(ii, :) = (f .* [r g b]) .^ gamma;
end
cmap = max(min(rgb, 1), 0);
end

function out = local_apply_axes(ax, varargin)
s = local_tokens();
if nargin < 1 || isempty(ax) || any(~isgraphics(ax))
    out = ax;
    return;
end
if exist('apply_tex_style', 'file') == 2
    try
        args = local_with_defaults(varargin, {'FontName', s.axesFontName, ...
            'FontSize', s.axesFontSize, ...
            'TitleFontSize', s.axesTitleFontSize});
        out = apply_tex_style(ax, args{:});
        return;
    catch
    end
end
for ii = 1:numel(ax)
    a = ax(ii);
    if ~isgraphics(a), continue; end
    try, a.FontName = s.axesFontName; catch, end
    try, a.FontSize = s.axesFontSize; catch, end
    try, a.TickLabelInterpreter = 'latex'; catch, end
    try, box(a, 'on'); catch, end
end
out = ax;
end

function lgd = local_apply_legend(lgd, varargin)
s = local_tokens();
if nargin < 1 || isempty(lgd)
    lgd = legend('show');
elseif isgraphics(lgd, 'axes')
    lgd = legend(lgd, 'show');
end
if isempty(lgd) || any(~isgraphics(lgd)), return; end
if exist('render_result', 'file') == 2
    try
        args = local_with_defaults(varargin, {'FontName', s.axesFontName, ...
            'FontSize', s.axesFontSize});
        lgd = render_result('legend', lgd, args{:});
        return;
    catch
    end
end
try, lgd.Interpreter = 'latex'; catch, end
try, lgd.FontName = s.axesFontName; catch, end
try, lgd.FontSize = s.axesFontSize; catch, end
end

function args = local_with_defaults(args, defaults)
if isempty(args)
    args = {};
end
present = {};
for ii = 1:2:numel(args)
    if ischar(args{ii}) || isstring(args{ii})
        present{end+1} = lower(char(string(args{ii}))); %#ok<AGROW>
    end
end
for ii = 1:2:numel(defaults)
    key = lower(char(string(defaults{ii})));
    if ~any(strcmp(present, key))
        args = [defaults(ii:ii+1), args]; %#ok<AGROW>
    end
end
end

function css = local_notes_css()
s = local_tokens();
css = sprintf(['body{font-family:"Times New Roman",Georgia,serif;max-width:980px;margin:38px auto;padding:0 28px;line-height:1.62;color:%s;background:#fff;}' newline ...
    'h1,h2,h3{line-height:1.25;margin-top:1.4em;border-bottom:1px solid #e5e7eb;padding-bottom:.25em;color:%s;}' newline ...
    'code,pre{font-family:Consolas,Menlo,monospace;background:#f6f8fa;border-radius:6px;}' newline ...
    'pre{padding:12px;overflow:auto;} code{padding:2px 4px;}' newline ...
    'table{border-collapse:collapse;margin:1em 0;min-width:55%%;} th,td{border:1px solid #d0d7de;padding:6px 10px;vertical-align:top;} th{background:#f6f8fa;}' newline ...
    'blockquote{border-left:4px solid #d0d7de;margin-left:0;padding-left:1em;color:#57606a;}'], ...
    local_rgb_hex(s.text), local_rgb_hex(s.primary));
end

function hex = local_rgb_hex(rgb)
rgb = max(0, min(1, rgb));
hex = sprintf('#%02x%02x%02x', round(255*rgb(1)), round(255*rgb(2)), round(255*rgb(3)));
end
