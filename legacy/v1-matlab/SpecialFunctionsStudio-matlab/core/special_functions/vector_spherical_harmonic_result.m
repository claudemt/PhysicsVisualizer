function result = vector_spherical_harmonic_result(params,mode)
[theta,phi] = meshgrid(linspace(0.03,pi-0.03,56),linspace(0,2*pi,112));
pairs = build_lm_pairs(params);
items = cell(1,size(pairs,1));

for k = 1:size(pairs,1)
    l = pairs(k,1); m = pairs(k,2);
    Ylm = spharmY(l,m,theta,phi);
    [dYdtheta,~] = gradient(Ylm,theta(1,2)-theta(1,1),phi(2,1)-phi(1,1));
    safe_sin = sin(theta);
    safe_sin(abs(safe_sin)<1e-8) = 1e-8;
    nrm = sqrt(max(l*(l+1),eps));

    switch mode
        case 'x'
            Atheta = 1i*m.*Ylm./safe_sin/nrm;
            Aphi = -dYdtheta/nrm;
            tp = '\mathrm{X}';
        case 'psi'
            Atheta = dYdtheta/nrm;
            Aphi = 1i*m.*Ylm./safe_sin/nrm;
            tp = '\Psi';
        case 'radial'
            Atheta = zeros(size(Ylm));
            Aphi = zeros(size(Ylm));
            tp = '\hat r Y';
        otherwise
            error('Unknown VSH mode: %s',mode);
    end

    if strcmp(mode,'radial')
        Ar = real(Ylm); C = Ar;
    else
        Ar = zeros(size(Ylm)); C = real(sqrt(abs(Atheta).^2+abs(Aphi).^2));
    end

    ex = sin(theta).*cos(phi); ey = sin(theta).*sin(phi); ez = cos(theta);
    etx = cos(theta).*cos(phi); ety = cos(theta).*sin(phi); etz = -sin(theta);
    epx = -sin(phi); epy = cos(phi); epz = zeros(size(phi));

    U = real(Ar.*ex + Atheta.*etx + Aphi.*epx);
    V = real(Ar.*ey + Atheta.*ety + Aphi.*epy);
    W = real(Ar.*ez + Atheta.*etz + Aphi.*epz);

    idx1 = 1:6:size(theta,1);
    idx2 = 1:9:size(theta,2);

    items{k} = struct('kind','vectorfield', ...
        'sphere_x',ex,'sphere_y',ey,'sphere_z',ez,'c',C, ...
        'xq',ex(idx1,idx2),'yq',ey(idx1,idx2),'zq',ez(idx1,idx2), ...
        'uq',U(idx1,idx2),'vq',V(idx1,idx2),'wq',W(idx1,idx2), ...
        'x_crop',ex,'y_crop',ey,'z_crop',ez, ...
        'title',sprintf('$%s:\\ l=%d,\\ m=%d$',tp,l,m));
end

result = struct('kind','3d','items',{items},'title','Vector spherical harmonics');
end

function pairs = build_lm_pairs(params)
A = result_data('arg_matrix',params);
if isempty(A), A = [2 1]; end
if size(A,2) ~= 2, error('Vector spherical harmonics require tuples (l,m).'); end
pairs = round(A);
valid = pairs(:,1) >= 1 & abs(pairs(:,2)) <= pairs(:,1);
pairs = pairs(valid,:);
if isempty(pairs), error('No valid (l,m) pairs remain after filtering |m| <= l.'); end
pairs = unique(pairs,'rows','stable');
[~,idx] = sortrows([pairs(:,2),pairs(:,1)]);
pairs = pairs(idx,:);
end

function Y = spharmY(l,m,theta,phi)
ma = abs(m);
ct = cos(theta(:).');
P = legendre(l,ct);
Pm = reshape(squeeze(P(ma+1,:)),size(theta));
N = sqrt((2*l+1)/(4*pi)*factorial(l-ma)/factorial(l+ma));
Ypos = N.*Pm.*exp(1i*ma*phi);
if m >= 0
    Y = Ypos;
else
    Y = (-1)^ma*conj(Ypos);
end
end
