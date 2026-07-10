function epicycloid_test ( )

%*****************************************************************************80
%
%% epicycloid_test() tests epicycloid().
%
%  Licensing:
%
%    This code is distributed under the MIT license.
%
%  Modified:
%
%    09 January 2019
%
%  Author:
%
%    John Burkardt
%
  addpath ( '../epicycloid' );

  timestamp ( );
  fprintf ( 1, '\n' );
  fprintf ( 1, 'epicycloid_test():\n' );
  fprintf ( 1, '  MATLAB/Octave version %s\n', version ( ) );
  fprintf ( 1, '  Test epicycloid().\n' );

  k = 2.1;
  s = 10.0;
  n = 501;

  fprintf ( 1, '\n' );
  fprintf ( 1, '  Ratio R/r = %g\n', k );
  fprintf ( 1, '  Number of rotations = %d\n', s );
  fprintf ( 1, '  Number of points computed will be %d\n', n );

  [ x, y ] = epicycloid_xy ( k, s, n );
  r8vec2_print_some ( n, x, y, 10, '  Some of the (X,Y) coordinates:' );

  filename = 'epicycloid.png';
  epicycloid_plot ( k, s, x, y, filename );
  fprintf ( 1, '\n' );
  fprintf ( 1, '  Saving plot in "%s"\n', filename );

  filename = 'epicycloid_xy.txt';
  r8vec2_write ( filename, n, x, y );
  fprintf ( 1, '  Saving (x,y) data in "%s"\n', filename );

  [ r, t ] = epicycloid_rt ( k, s, n );
  r8vec2_print_some ( n, x, y, 10, '  Some of the (X,Y) coordinates:' );

  filename = 'epicycloid_rt.txt';
  r8vec2_write ( filename, n, r, t );
  fprintf ( 1, '\n' );
  fprintf ( 1, '  Saving (r,t) data in "%s"\n', filename );
%
%  Terminate.
%
  fprintf ( 1, '\n' );
  fprintf ( 1, 'epicycloid_test():\n' );
  fprintf ( 1, '  Normal end of execution.\n' );
  fprintf ( 1, '\n' );
  timestamp ( );

  rmpath ( '../epicycloid' );

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
%    14 February 2003
%
%  Author:
%
%    John Burkardt
%
  t = now;
  c = datevec ( t );
  s = datestr ( c, 0 );
  fprintf ( 1, '%s\n', s );

  return
end

