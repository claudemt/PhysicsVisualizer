function sol = solve_rect_free_sparse(nu, k, n)
%SOLVE_RECT_FREE_SPARSE Legacy FFFF sparse formulation.

h = 2.0 / ( n - 3 );
G = numgrid('S', n + 2);
D = delsq(G);

bl = G(3:n,3);
br = G(3:n,n);
bt = G(3,3:n)';
bb = G(n,3:n)';

gl = G(3:n,2);
gr = G(3:n,n+1);
gt = G(2,3:n)';
gb = G(n+1,3:n)';

L = D;
N = D;

N(bl,bl) = N(bl,bl) / 2.0;
N(br,br) = N(br,br) / 2.0;
N(bt,bt) = N(bt,bt) / 2.0;
N(bb,bb) = N(bb,bb) / 2.0;

L([gl;gr;gt;gb],:) = 0.0;

for idx = gl(1:end-1)'
    L([idx,idx+1],[idx,idx+1,idx+2*n,idx+2*n+1]) = ...
        L([idx,idx+1],[idx,idx+1,idx+2*n,idx+2*n+1]) ...
        + 0.5 * ( nu - 1.0 ) * [1.0,-1.0,-1.0,1.0;-1.0,1.0,1.0,-1.0];
end
for idx = gr(1:end-1)'
    L([idx,idx+1],[idx,idx+1,idx-2*n,idx-2*n+1]) = ...
        L([idx,idx+1],[idx,idx+1,idx-2*n,idx-2*n+1]) ...
        + 0.5 * ( nu - 1.0 ) * [1.0,-1.0,-1.0,1.0;-1.0,1.0,1.0,-1.0];
end
for idx = gt(1:end-1)'
    L([idx,idx+n],[idx+n,idx,idx+n+2,idx+2]) = ...
        L([idx,idx+n],[idx+n,idx,idx+n+2,idx+2]) ...
        - 0.5 * ( nu - 1.0 ) * [1.0,-1.0,-1.0,1.0;-1.0,1.0,1.0,-1.0];
end
for idx = gb(1:end-1)'
    L([idx,idx+n],[idx+n,idx,idx+n-2,idx-2]) = ...
        L([idx,idx+n],[idx+n,idx,idx+n-2,idx-2]) ...
        - 0.5 * ( nu - 1.0 ) * [1.0,-1.0,-1.0,1.0;-1.0,1.0,1.0,-1.0];
end

A = N * L;
A([gl;gr;gt;gb],:) = 0.0;

for idx = gl'
    A(idx,[idx+n,idx,idx+n-1,idx+n+1,idx+2*n]) = [ 2*(1+nu), -1, -nu, -nu, -1 ];
end
for idx = gr'
    A(idx,[idx-n,idx,idx-n-1,idx-n+1,idx-2*n]) = [ 2*(1+nu), -1, -nu, -nu, -1 ];
end
for idx = gt'
    A(idx,[idx+1,idx,idx+1+n,idx+1-n,idx+2]) = [ 2*(1+nu), -1, -nu, -nu, -1 ];
end
for idx = gb'
    A(idx,[idx-1,idx,idx-1+n,idx-1-n,idx-2]) = [ 2*(1+nu), -1, -nu, -nu, -1 ];
end

phys = G(3:n,3:n); phys = phys(:);
ghost = [ gl; gr; gt; gb ];
A0 = A(phys,phys) - A(phys,ghost) / A(ghost,ghost) * A(ghost,phys);

B = speye(n^2);
B(bl,bl) = B(bl,bl) / 2.0;
B(br,br) = B(br,br) / 2.0;
B(bt,bt) = B(bt,bt) / 2.0;
B(bb,bb) = B(bb,bb) / 2.0;
B0 = B(phys,phys);

[V, Lambda] = eigs(A0 / h^4, B0, k, 'SM');
lamVec = real(diag(Lambda));
[~, p] = sort(lamVec, 'ascend');

kUse = min(k, numel(p));
x = linspace(-1, 1, n-2);
modesU = cell(1, kUse);
lamDisp = zeros(1, kUse);

for j = 1:kUse
    idxMode = p(j);
    lam_j = lamVec(idxMode);
    lamDisp(j) = sqrt(max(lam_j, 0));
    if j <= 3
        lamDisp(j) = 0;
    end
    U = reshape(real(V(:,idxMode)), n-2, n-2);
    modesU{j} = U;
end

sol = struct('x', x, 'modesU', {modesU}, 'lamDisp', lamDisp);
end
