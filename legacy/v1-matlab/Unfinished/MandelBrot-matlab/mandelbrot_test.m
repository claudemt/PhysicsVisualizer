function mandelbrot_test ( )

%*****************************************************************************80
%
%% mandelbrot_test() tests mandelbrot().
%
%  Licensing:
%
%    This code is distributed under the MIT license.
%
%  Modified:
%
%    08 February 2019
%
%  Author:
%
%    John Burkardt
%
  addpath ( '../mandelbrot' );

  timestamp ( );
  fprintf ( 1, '\n' );
  fprintf ( 1, 'mandelbrot_test():\n' );
  fprintf ( 1, '  MATLAB/Octave version %s\n', version ( ) );
  fprintf ( 1, '  Test mandelbrot().\n' );
  fprintf ( 1, '\n' );

  mandelbrot ( 101, 101, 21 );
  filename = 'mandelbrot_101_101_21.png';
  print ( '-dpng', filename );
  fprintf ( 1, '  Graphics saved as "%s"\n', filename );

  mandelbrot ( 101, 101, 41 );
  filename = 'mandelbrot_101_101_41.png';
  print ( '-dpng', filename );
  fprintf ( 1, '  Graphics saved as "%s"\n', filename );

  mandelbrot ( 101, 101, 81 );
  filename = 'mandelbrot_101_101_81.png';
  print ( '-dpng', filename );
  fprintf ( 1, '  Graphics saved as "%s"\n', filename );

  mandelbrot ( 201, 201, 21 );
  filename = 'mandelbrot_201_201_21.png';
  print ( '-dpng', filename );
  fprintf ( 1, '  Graphics saved as "%s"\n', filename );

  mandelbrot ( 401, 401, 21 );
  filename = 'mandelbrot_401_401_21.png';
  print ( '-dpng', filename );
  fprintf ( 1, '  Graphics saved as "%s"\n', filename );
%
%  Terminate.
%
  fprintf ( 1, '\n' );
  fprintf ( 1, 'mandelbrot_test():\n' );
  fprintf ( 1, '  Normal end of execution.\n' );
  fprintf ( 1, '\n' );
  timestamp ( );

  rmpath ( '../mandelbrot' );

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

