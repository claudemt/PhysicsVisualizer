function result = gauss_hypergeometric_2f1_result(params)
z = linspace(params.xmin,params.xmax,1200);
A = render_result('arg_matrix',params);
if isempty(A), A = [0.5 1 2]; end
if size(A,2) ~= 3, error('Hypergeometric input requires tuples (a,b,c).'); end
curves = cell(1,size(A,1));
for k = 1:size(A,1)
    a = A(k,1); b = A(k,2); c = A(k,3);
    y = hyper2f1_series(a,b,c,z);
    curves{k} = struct('x',z,'y',y,'label',sprintf('${}_2F_1(%g,%g;%g;z)$',a,b,c));
end
result = render_result('make_curve_result',curves,'Gauss hypergeometric function ${}_2F_1(a,b;c;z)$','$z$','$f(z)$');
end

function y = hyper2f1_series(a,b,c,z)
y = ones(size(z)); term = ones(size(z));
for k = 1:700
    term = term .* ((a+k-1).*(b+k-1)./((c+k-1).*k)) .* z;
    ynew = y + term;
    if max(abs(term(:))) < 1e-12*max(1,max(abs(ynew(:))))
        y = ynew; return
    end
    y = ynew;
end
end
