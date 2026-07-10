function julia_set_test ( )

%*****************************************************************************80
%
%% julia_set_test() tests julia_set().
%
%  Licensing:
%
%    This code is distributed under the MIT license. 
%
%  Modified:
%
%    23 December 2022
%
%  Author:
%
%    John Burkardt
%
  addpath ( '../julia_set' );

  timestamp ( );
  fprintf ( 1, '\n' );
  fprintf ( 1, 'julia_set_test():\n' );
  fprintf ( 1, '  MATLAB/Octave version %s\n', version ( ) );
  fprintf ( 1, '  Compute and plot a Julia set.\n' );
  fprintf ( 1, '  under the transformation A=A^2-0.8+0.156i\n' );

  w = 500;
  h = 1000;
  xl = -1.5;
  xr = 1.5;
  yb = -1.5;
  yt = 1.5;

  [ J, X, Y ] = julia_set ( w, h, xl, xr, yb, yt );
%
%  Use a plot() command directly on the X, Y values.
%
  figure ( 1 );
  clf ( );
  plot ( X(J), Y(J), 'r.' );
  grid ( 'on' );
  filename = 'julia_plot.png';
  print ( '-dpng', filename );
  fprintf ( 1, '  Graphics saved as "%s"\n', filename );
%
%  Use a spy() command on the logical 0/1 J array.
%
  figure ( 2 );
  clf ( );
  spy ( J );
  filename = 'julia_spy.png';
  print ( '-dpng', filename );
  fprintf ( 1, '  Graphics saved as "%s"\n', filename );
%
%  Terminate.
%
  fprintf ( 1, '\n' );
  fprintf ( 1, 'julia_set_test():\n' );
  fprintf ( 1, '  Normal end of execution.\n' );

  timestamp ( );

  rmpath ( '../julia_set' );

  return
end
function timestamp ( )

%*****************************************************************************80
%
%% timestamp() prints the current YMDHMS date as a timestamp.
%
%  Licensing:
%
%    This code is distributed under the MIT license.
%
%  Modified:
%
%    14 November 2022
%
%  Author:
%
%    John Burkardt
%
  t = now ( );
  c = datevec ( t );
  s = datestr ( c, 0 );
  fprintf ( 1, '%s\n', s );

  return
end



