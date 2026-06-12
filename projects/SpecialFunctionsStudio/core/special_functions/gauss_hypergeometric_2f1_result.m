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
% Evaluate 2F1(a,b;c;z) via power series.
% The series converges for |z| < 1; for |z| >= 1 the result may be
% inaccurate and a warning is issued.  The case c <= 0 integer (division
% by zero in recurrence) is also guarded.
if isscalar(c) && c == round(c) && c <= 0
    warning('Hypergeometric:cZero', ...
        '2F1(%g,%g;%g;z) has c <= 0 integer — series may be singular.', a, b, c);
end
if any(abs(z) >= 1 - 1e-12)
    warning('Hypergeometric:convergence', ...
        '2F1(%g,%g;%g;z) series converges slowly or diverges for |z| >= 1.', a, b, c);
end
y = ones(size(z)); term = ones(size(z));
for k = 1:700
    denom = (c+k-1).*k;
    if any(abs(denom(:)) < eps(1))
        warning('Hypergeometric:denomZero', ...
            'Division by near-zero denominator in 2F1 at k=%d, c=%g.', k, c);
        y(:) = NaN; return;
    end
    term = term .* ((a+k-1).*(b+k-1)./denom) .* z;
    ynew = y + term;
    if max(abs(term(:))) < 1e-12*max(1,max(abs(ynew(:))))
        y = ynew; return
    end
    y = ynew;
end
warning('Hypergeometric:noConvergence', ...
    '2F1(%g,%g;%g;z) did not converge in 700 terms.', a, b, c);
end
