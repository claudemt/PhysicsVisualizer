function q = coastline_perturb ( p, mu )

%*****************************************************************************80
%
%% coastline_perturb() inserts intermediate points in a closed curve.
%
%  Licensing:
%
%    This code is distributed under the MIT license. 
%
%  Modified:
%
%    01 August 2023
%
%  Author:
%
%    John Burkardt
%
%  Reference:
%
%    David Kahaner, Cleve Moler, Steven Nash,
%    Numerical Methods and Software,
%    Prentice Hall, 1989,
%    ISBN: 0-13-627258-4,
%    LC: TA345.K34.
%
%  Input:
%
%    real p(n,2): the coordinates of a closed polygonal curve.
%
%    real mu: controls the degree of peturbation.
%    0 <= mu <= 0.25 is recommended.
%
%  Output:
%
%    real q(2*n,2): the coordinates of the perturbed curve.
%
  [ n, d ] = size ( p );

  sig = mu^2;
  w = mu + sig * randn ( n, 1 );
%
%  A value w = 0 returns the average of the two neighbors.
%
  perturb =  ...
     0.5 * ( p                   + circshift ( p, 1 ) ) ...
    + w .* ( p                   + circshift ( p, 1 ) ) ...
    - w .* ( circshift ( p, -1 ) + circshift ( p, 2 ) );
%
%  Shift the sequence by one place to make it easier to merge.
%
  perturb = circshift ( perturb, -1 );
%
%  Q is twice the length of P.
%  Odd values contain the original P.
%  Even values are intermediate perturbulants.
%
  q = zeros ( 2 * n, d );
  q(1:2:2*n-1,1:d) = p(1:n,1:d);
  q(2:2:2*n,1:d) = perturb(1:n,1:d);

  return
end

