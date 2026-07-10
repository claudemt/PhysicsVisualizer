function lissajous_test ( )

%*****************************************************************************80
%
%% lissajous_test() tests lissajous().
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
  addpath ( '../lissajous' );

  timestamp ( );
  fprintf ( 1, '\n' );
  fprintf ( 1, 'lissajous_test():\n' );
  fprintf ( 1, '  MATLAB/Octave version %s\n', version ( ) );
  fprintf ( 1, '  Display a Lissajous figure, using N points, of the form:\n' );
  fprintf ( 1, '    x(i) = sin ( A1 * t + B1 ).\n' );
  fprintf ( 1, '    y(i) = sin ( A2 * t + B2 ).\n' );
  fprintf ( 1, '  for 0 <= t <= TSTOP.\n' );

  a1 = 5.0;
  b1 = pi / 2.0;
  a2 = 4.0;
  b2 = 0.0;
  tstop = 2.0 * pi;
  n = 500;

  lissajous ( a1, b1, a2, b2, tstop, n );
%
%  Terminate.
%
  fprintf ( 1, '\n' );
  fprintf ( 1, 'lissajous_test():\n' );
  fprintf ( 1, '  Normal end of execution.\n' );

  timestamp ( );

  rmpath ( '../lissajous' );

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



