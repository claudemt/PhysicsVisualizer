function prime_plot_test ( )

%*****************************************************************************80
%
%% prime_plot_test() tests prime_plot().
%
%  Licensing:
%
%    This code is distributed under the MIT license.
%
%  Modified:
%
%    06 February 2019
%
%  Author:
%
%    John Burkardt
%
  addpath ( '../prime_plot' )

  timestamp ( );
  fprintf ( 1, '\n' );
  fprintf ( 1, 'prime_plot_test():\n' );
  fprintf ( 1, '  MATLAB/Octave version %s\n', version ( ) );
  fprintf ( 1, '  Test prime_plot().\n' );

  prime_plot ( 100 );
%
%  Terminate.
%
  fprintf ( 1, '\n' );
  fprintf ( 1, 'prime_plot_test():\n' );
  fprintf ( 1, '  Normal end of execution.\n' );
  fprintf ( 1, '\n' );
  timestamp ( );

  rmpath ( '../prime_plot' )

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

