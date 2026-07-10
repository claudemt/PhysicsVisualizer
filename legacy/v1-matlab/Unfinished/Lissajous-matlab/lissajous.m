function lissajous ( a1, b1, a2, b2, tstop, n )

%*****************************************************************************80
%
%% lissajous() draws a Lissajous curve.
%
%  Licensing:
%
%    This code is distributed under the MIT license.
%
%  Modified:
%
%    27 December 2022
%
%  Author:
%
%    John Burkardt
%
%  Input:
%
%    real a1, b1, a2, b2: the parameters in the Lissajous curve.
%
%    real tstop: the final value of t.
%
%    integer n: the number of points to draw.
%
  fprintf ( 1, '\n' );
  fprintf ( 1, 'lissajous_plot():\n' );
%
%  Generate the data.
%
  t1 = 0.0;
  t = linspace ( t1, tstop, n );
  x = sin ( a1 * t + b1 );
  y = sin ( a2 * t + b2 );
%
%  Plot it.
%
  clf ( );
  plot ( x, y, 'LineWidth', 2, 'Color', 'm' );
  grid ( 'on' );
  axis ( [ -1.1, +1.1, -1.1, +1.1 ] )
  axis ( 'equal' );
  xlabel ( '<--- X --->', 'Fontsize', 16 );
  ylabel ( '<--- Y --->', 'Fontsize', 16 );
  title ( 'Lissajous curve' );
%
%  Save the plot as a PNG file.
%
  filename = 'lissajous.png';
  print ( '-dpng', filename );
  fprintf ( 1, '\n' );
  fprintf ( 1, '  Graphics saved as "%s"\n', filename );

  return
end
