function result = spherical_harmonic_surface_result(params)
[theta,phi] = meshgrid(linspace(0,pi,100),linspace(0,2*pi,180));
pairs = build_lm_pairs(params);
items = cell(1,size(pairs,1));
for k = 1:size(pairs,1)
    l = pairs(k,1); m = pairs(k,2);
    Ylm = spharmY(l,m,theta,phi);
    R = abs(Ylm);
    R = 0.25 + 0.95*R./max(R(:)+eps);
    X = R.*sin(theta).*cos(phi);
    Y = R.*sin(theta).*sin(phi);
    Z = R.*cos(theta);
    C = real(Ylm);
    items{k} = struct('kind','surface','x',X,'y',Y,'z',Z,'c',C, ...
        'x_crop',X,'y_crop',Y,'z_crop',Z, ...
        'title',sprintf('$l=%d,\\ m=%d$',l,m), ...
        'filename',sprintf('spherical_harmonics_l%d_m%d.png', l, m));
end
result = struct('kind','3d','items',{items},'title','Spherical harmonics');
end

function pairs = build_lm_pairs(params)
A = render_result('arg_matrix',params);
if isempty(A), A = [3 1]; end
if size(A,2) ~= 2, error('Spherical harmonics require tuples (l,m).'); end
pairs = round(A);
pairs(:,1) = max(0,pairs(:,1));
valid = abs(pairs(:,2)) <= pairs(:,1);
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
