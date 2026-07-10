function x = logistic_map ( x, r )

%*****************************************************************************80
%
%% logistic_map() evaluates the logistic map once.
%
%  Licensing:
%
%    This code is distributed under the MIT license. 
%
%  Modified:
%
%    22 August 2023
%
%  Author:
%
%    Original Python version by John D Cook
%    This version by John Burkardt
%
%  Reference:
%
%    John D Cook,
%    Logistic bifurcation diagram in detail,
%    11 January 2020,
%    https://www.johndcook.com/blog/
%
%  Input:
%
%    real x: the current iterate.
%
%    real r: the logistic parameter.  Values 0 < r < 4 are of interest.
%
%  Output:
%
%    real x: the next iterate.
%    
  x = r * x * ( 1.0 - x );

  return
end

