function result = incomplete_elliptic_pi_result(params)
phi = linspace(params.xmin,params.xmax,450);
A = result_data('arg_matrix',params);
if isempty(A), A = [0.2 0.5]; end
if size(A,2) ~= 2, error('Incomplete elliptic Pi requires tuples (n,m).'); end
curves = cell(1,size(A,1));
for k = 1:size(A,1)
    n = A(k,1); m = A(k,2);
    y = arrayfun(@(x)ellipticPi_scalar(n,x,m),phi);
    curves{k} = struct('x',phi,'y',y,'label',sprintf('$\\Pi(%g;\\phi\\,|\\,%g)$',n,m));
end
result = result_data('make_curve_result',curves,'Incomplete elliptic integral $\Pi(n;\phi|m)$','$\phi$','$\Pi(n;\phi|m)$');
end
function val = ellipticPi_scalar(n,phi,m)
sgn = sign(phi); upper = abs(phi);
f = @(t) 1 ./ ((1-n.*sin(t).^2).*sqrt(max(1-m.*sin(t).^2,eps)));
val = sgn*integral(f,0,upper,'ArrayValued',true,'RelTol',1e-8,'AbsTol',1e-10);
end
