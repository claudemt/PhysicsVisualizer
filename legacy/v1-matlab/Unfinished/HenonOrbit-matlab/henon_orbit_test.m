function henon_orbit_test ( )

%*****************************************************************************80
%
%% henon_orbit_test() tests henon_orbit().
%
%  Licensing:
%
%    This code is distributed under the MIT license. 
%
%  Modified:
%
%    29 August 2023
%
%  Author:
%
%    Original Python version by John D Cook.
%    This version by John Burkardt.
%
%  Reference:
%
%    John D Cook,
%    Henon's dynamical system,
%    https://www.johndcook.com/blog/2023/02/08/henon/
%    Posted 08 February 2023.
%
%    Michel Henon,
%    Numerical study of quadratic area-preserving mappings. 
%    Quarterly of Applied Mathematics. 
%    October 1969, pages 291-312.
%
  addpath ( '../henon_orbit' );

  timestamp ( );

  fprintf ( 1, '\n' );
  fprintf ( 1, 'henon_orbit_test():\n' );
  fprintf ( 1, '  MATLAB/Octave version %s\n', version ( ) );
  fprintf ( 1, '  Test henon_orbit(), which plots examples of the\n' );
  fprintf ( 1, '  Henon dynamical system.\n' );
  fprintf ( 1, '' )

  fig4 = [ ...
      0.1,   0.0,    200.0; ...
      0.2,   0.0,    360.0; ...
      0.3,   0.0,    840.0; ...
      0.4,   0.0,    871.0; ...
      0.5,   0.0,    327.0; ...
      0.58,  0.0,   1164.0; ...
      0.61,  0.0,   1000.0; ...
      0.63,  0.2,    180.0; ...
      0.66,  0.22,   500.0; ...
      0.66,  0.0,    694.0; ...
      0.73,  0.0,    681.0; ...
      0.795, 0.0,    657.0 ...
  ];

  henon_orbit ( 0.4, fig4, "fig4.png" );

  fig5 = [ ...
      0.2,   0.0,    651.0; ...
      0.35,  0.0,    187.0; ...
      0.44,  0.0,   1000.0; ...
      0.60, -0.1,   1000.0; ...
      0.68,  0.0,    250.0; ...
      0.718, 0.0,   3000.0; ...
      0.75,  0.0,   1554.0; ...
      0.82,  0.0,    233.0 ...
  ];

  henon_orbit ( 0.24, fig5, "fig5.png" );

  fig7 = [ ...
      0.1,  0.0,  182.0; ...
      0.15, 0.0, 1500.0; ...
      0.35, 0.0,  560.0; ...
      0.54, 0.0,  210.0; ...
      0.59, 0.0,  437.0; ...
      0.68, 0.0,  157.0 ...
  ];

  henon_orbit ( -0.01, fig7, "fig7.png" );
%
%  Terminate.
%
  fprintf ( 1, '\n' );
  fprintf ( 1, 'henon_orbit_test():\n' );
  fprintf ( 1, '  Normal end of execution.\n' );

  timestamp ( );

  rmpath ( '../henon_orbit' );

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
