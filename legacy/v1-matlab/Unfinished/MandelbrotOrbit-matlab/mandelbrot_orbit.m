function z = mandelbrot_orbit ( z0, n )

%*****************************************************************************80
%
%% mandelbrot_orbit() follows the orbit of a point in a Mandelbrot iteration.
%
%  Discussion:
%
%    The iteration has the form:
%
%      Z = Z^2 + Z0
%
%  Example:
%
%    mandelbrot_orbit ( -0.04+0.6i, 100 )
%
%  Licensing:
%
%    This code is distributed under the MIT license. 
%
%  Modified:
%
%    05 September 2022
%
%  Author:
%
%    John Burkardt
%
%  Input:
%
%    complex Z0: the starting point.
%
%    integer N: the number of steps.
%
%  Output:
%
%    complex Z(n+1,1): the sequence of iterates.
%
  z = zeros ( n + 1, 1 );

  z(1,1) = z0;

  for j = 1 : n
    z(j+1,1) = z(j,1) ^ 2 + z0;
    if ( 2.0 < norm ( z(j+1,1) ) )
      break
    end
  end

  return
end
