function fractal_coastline_test ( )

%*****************************************************************************80
%
%% fractal_coastline_test() tests fractal_coastline().
%
%  Licensing:
%
%    This code is distributed under the MIT license. 
%
%  Modified:
%
%    31 July 2023
%
%  Author:
%
%    John Burkardt
%
  addpath ( '../fractal_coastline' );

  timestamp ( );
  fprintf ( 1, '\n' );
  fprintf ( 1, 'fractal_coastline():\n' );
  fprintf ( 1, '  MATLAB/Octave version %s\n', version ( ) );
  fprintf ( 1, '  Test fractal_coastline().\n' );

  australia_13 = load ( 'australia_13.txt' );
  coastline_display ( australia_13, 'australia_13' );

  mu = 0.10;
  australia_26 = coastline_perturb ( australia_13, mu );
  coastline_display ( australia_26, 'australia_26' );

  australia_52 = coastline_perturb ( australia_26, mu );
  coastline_display ( australia_52, 'australia_52' );

  mu = 0.20;
  bustralia_26 = coastline_perturb ( australia_13, mu );
  coastline_display ( bustralia_26, 'bustralia_26' );

  bustralia_52 = coastline_perturb ( bustralia_26, mu );
  coastline_display ( bustralia_52, 'bustralia_52' );

  florida_16 = load ( 'florida_16.txt' );
  coastline_display ( florida_16, 'florida_16' );

  mu = 0.10;
  florida_32 = coastline_perturb ( florida_16, mu );
  coastline_display ( florida_32, 'florida_32' );

  florida_64 = coastline_perturb ( florida_32, mu );
  coastline_display ( florida_64, 'florida_64' );
%
%  Terminate.
%
  fprintf ( 1, '\n' );
  fprintf ( 1, 'fractal_coastline():\n' );
  fprintf ( 1, '  Normal end of execution.\n' );
  fprintf ( 1, '\n' );
  timestamp ( );

  rmpath ( '../fractal_coastline' );

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

