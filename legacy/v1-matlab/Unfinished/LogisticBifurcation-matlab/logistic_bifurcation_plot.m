function logistic_bifurcation_plot ( )

%*****************************************************************************80
%
%% logistic_bifurcation_plot() plots the logistic bifurcation diagram.
%
%  Discussion:
%
%    For low values of r, the logistic map has a single fixed point.
%    As r increases, a cycle of length 2 appears, then a cycle of
%    length 4.  Then things become very complicated.
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
%
%  Clear the plot.
%
  clf ( );
  grid ( 'on' );
  hold ( 'on' );
%
%  Sample values of r between 0 and 4.
%
  rs = linspace ( 0.0, 4.0, 1001 );
%
%  For each value r, compute ts, the set of attractors for the iteration.
%
  for r = rs

    ts = logistic_attractors ( 0.1, r );
%
%  Plot the pairs (r,t).
%
    for t = ts
      plot ( r, t, "ko", 'MarkerSize', 1 );
    end

  end

  hold ( 'off' );
  filename = 'logistic_bifurcation.png';
  print ( '-dpng',  filename );
  fprintf ( 1, '  Graphics saved as "%s"\n', filename );
  close ( );

  return
end

