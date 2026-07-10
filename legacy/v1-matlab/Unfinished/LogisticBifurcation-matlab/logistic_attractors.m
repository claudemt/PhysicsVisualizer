function ts = logistic_attractors ( x, r )

%*****************************************************************************80
%
%% logistic_attractors() finds the attractors for a particular logistic map.
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
%    real x: the starting iterate.
%
%    real r: the logistic parameter.
%
%  Output:
%
%    real ts(*): the set of attractors.
%

%
%  "Warm up" the sequence by taking 100 steps.
%
  for c = 1 : 100
    x = logistic_map ( x, r );
  end

  x0 = round ( x, 4 );
  ts = [ x0 ];
%
%  Add unique logistic sequence values to the list.
%  For us, "unique" values must differ in the first four digits.
%
  for c = 1 : 1000

    x = logistic_map ( x, r );
    xr = round ( x, 4 );

    if ( any ( ts(:) == xr ) )
      break;
    end

    ts(end+1) = xr;

  end

  return
end

