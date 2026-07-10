function ulam_spiral_test ( )

%*****************************************************************************80
%
%% ulam_spiral_test() tests ulam_spiral().
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
  addpath ( '../ulam_spiral' );

  timestamp ( );
  fprintf ( 1, '\n' );
  fprintf ( 1, 'ulam_spiral_test():\n' );
  fprintf ( 1, '  MATLAB/Octave version %s\n', version ( ) );
  fprintf ( 1, '  Test ulam_spiral()\n' );

  spiral_array_test ( );
  prime_spiral_test ( );
%
%  Terminate.
%
  fprintf ( 1, '\n' );
  fprintf ( 1, 'ulam_spiral_test():\n' );
  fprintf ( 1, '  Normal end of execution.\n' );
  fprintf ( 1, '\n' );
  timestamp ( );

  rmpath ( '../ulam_spiral' );

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

