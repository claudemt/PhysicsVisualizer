function out = parse_mie_scattering_params(action, varargin)
switch lower(char(string(action)))
    case 'defaults'
        out = local_defaults();
    case 'str2complex'
        out = local_str2complex(varargin{1});
    case 'custom_items'
        [items, ~] = local_custom_items();
        out = items;
    case 'custom_labels'
        [~, labels] = local_custom_items();
        out = labels;
    otherwise
        error('Unknown parse_mie_scattering_params action.');
end
end

function cfg = local_defaults()
cfg = struct();
cfg.eps1 = '2+0.1i';
cfg.mu1 = '0.8+0.05i';
cfg.R_over_lambda = 0.5;
cfg.nu = 1.1;
cfg.psi = 0.2;
cfg.geometry = 'sphere';
cfg.mode = 'custom';
cfg.customSelection = {'sca_rex','sca_rey','sca_rez','sca_aex','sca_aey','sca_aez','sca_emag'};
cfg.gridHalfWidth = 2.5;
cfg.N = 500;
cfg.nmaxExtra = 15;
cfg.maskInside = true;
cfg.sliceType = 'xz';
cfg.slicePos_over_lambda = 0.0;
end

function z = local_str2complex(s)
if isnumeric(s)
    z = s;
    return;
end
expr = char(strtrim(string(s)));
expr = strrep(expr, 'j', 'i');
z = str2num(expr); %#ok<ST2NM>
if isempty(z) || ~isscalar(z)
    error('Could not parse complex scalar: %s', expr);
end
end

function [items, labels] = local_custom_items()
items = { ...
    'sca_rex', 'sca_rey', 'sca_rez', 'sca_aex', 'sca_aey', 'sca_aez', 'sca_emag', ...
    'tot_rex', 'tot_rey', 'tot_rez', 'tot_aex', 'tot_aey', 'tot_aez', 'tot_emag'};
labels = { ...
    'sca Re Ex', 'sca Re Ey', 'sca Re Ez', 'sca |Ex|', 'sca |Ey|', 'sca |Ez|', 'sca Emag', ...
    'tot Re Ex', 'tot Re Ey', 'tot Re Ez', 'tot |Ex|', 'tot |Ey|', 'tot |Ez|', 'tot Emag'};
end
