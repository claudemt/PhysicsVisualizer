function P = prime_spiral ( thick, base )

%*****************************************************************************80
%
%% prime_spiral() produces a spiral array with 1's representing prime numbers.
%
%  Licensing:
%
%    This code is distributed under the MIT license.
%
%  Modified:
%
%    29 December 2022
%
%  Author:
%
%    John Burkardt
%
%  Input:
%
%    integer thick: the "radius" of the array, which can be 0 or more.
%
%    integer base: the starting value at the center of the spiral.
%    This is usually 1.
%
%  Output:
%
%    integer P[2*thick+1,2*thick+1]: an array of sequential integers, 
%    spiraling out from a central value of base.
%
  S = spiral_array ( thick, base );

  P = isprime ( S );

  return
end

