function fibonacci_spiral_test ( )

%*****************************************************************************80
%
%% fibonacci_spiral_test() tests fibonacci_spiral().
%
%  Licensing:
%
%    This code is distributed under the MIT license.
%
%  Modified:
%
%    06 June 2022
%
%  Author:
%
%    John Burkardt
%
  addpath ( '../fibonacci_spiral' )

  timestamp ( );
  fprintf ( 1, '\n' );
  fprintf ( 1, 'fibonacci_spiral_test():\n' );
  fprintf ( 1, '  MATLAB/Octave version %s\n', version ( ) );
  fprintf ( 1, '  Test fibonacci_spiral().\n' );

  for n = [ 50, 100, 500, 1000 ]
    fibonacci_spiral ( n );
  end

  for n = [ 50, 100 ]
    fibonacci_spiral_connected ( n );
  end

%
%  Terminate.
%
  fprintf ( 1, '\n' );
  fprintf ( 1, 'fibonacci_spiral_test():\n' );
  fprintf ( 1, '  Normal end of execution.\n' );
  fprintf ( 1, '\n' );
  timestamp ( );

  rmpath ( '../fibonacci_spiral' )

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

