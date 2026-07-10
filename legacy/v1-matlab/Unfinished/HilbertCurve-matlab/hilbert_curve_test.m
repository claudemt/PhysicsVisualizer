function hilbert_curve_test ( )

%*****************************************************************************80
%
%% hilbert_curve_test() tests hilbert_curve().
%
%  Licensing:
%
%    This code is distributed under the MIT license.
%
%  Modified:
%
%    30 January 2019
%
%  Author:
%
%    John Burkardt
%
  addpath ( '../hilbert_curve' );

  timestamp ( )
  fprintf ( 1, '\n' );
  fprintf ( 1, 'hilbert_curve_test():\n' );
  fprintf ( 1, '  MATLAB/Octave version %s\n', version ( ) );
  fprintf ( 1, '  Test hilbert_curve().\n' );

  d2xy_test ( );
  rot_test ( );
  xy2d_test ( );
%
%  Terminate.
%
  fprintf ( 1, '\n' );
  fprintf ( 1, 'hilbert_curve_test():\n' );
  fprintf ( 1, '  Normal end of execution.\n' );
  fprintf ( 1, '\n' );
  timestamp ( );

  rmpath ( '../hilbert_curve' );

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

