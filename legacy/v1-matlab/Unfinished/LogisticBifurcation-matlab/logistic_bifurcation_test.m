function logistic_bifurcation_test ( )

%*****************************************************************************80
%
%% logistic_bifurcation_test() tests logistic_bifurcation().
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
  addpath ( '../logistic_bifurcation' );

  timestamp ( );

  fprintf ( 1, '\n' );
  fprintf ( 1, 'logistic_bifurcation_test():\n' );
  fprintf ( 1, '  MATLAB/Octave version: %s\n', version ( ) );
  fprintf ( 1, '  Draw the logistic map bifurcation diagram.\n' );

  logistic_bifurcation_plot ( )
%
%  Terminate.
%
  fprintf ( 1, '\n' );
  fprintf ( 1, 'logistic_bifurcation_test():\n' );
  fprintf ( 1, '  Normal end of execution.\n' );

  timestamp ( );

  rmpath ( '../logistic_bifurcation' );

  return
end
function timestamp ( )

%*****************************************************************************80
%
%% timestamp() prints the YMDHMS date as a timestamp.
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

