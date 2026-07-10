function caustic_test ( )

%*****************************************************************************80
%
%% caustic_test() tests caustic().
%
%  Modified:
%
%    19 December 2022
%
%  Author:
%
%    John Burkardt
%
  addpath ( '../caustic' );

  timestamp ( )
  fprintf ( 1, '\n' );
  fprintf ( 1, 'caustic_test():\n' );
  fprintf ( 1, '  MATLAB/Octave version %s\n', version ( ) );
  fprintf ( 1, '  Test caustic().\n' );

  m = 102;
  n = 500;
  caustic ( m, n );
  filename = sprintf ( 'caustic_%d_%d.png', m, n );
  print ( '-dpng', filename );
  fprintf ( 1, '  Graphics saved as "%s"\n', filename );
%
%  Terminate.
%
  fprintf ( 1, '\n' );
  fprintf ( 1, 'caustic_test():\n' );
  fprintf ( 1, '  Normal end of execution.\n' );
  fprintf ( 1, '\n' );
  timestamp ( );

  rmpath ( '../caustic' );

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

