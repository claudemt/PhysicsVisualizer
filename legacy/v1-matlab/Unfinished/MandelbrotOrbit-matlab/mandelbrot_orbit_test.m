function mandelbrot_orbit_test ( )

%*****************************************************************************80
%
%% mandelbrot_orbit_test() tests mandelbrot_orbit().
%
%  Licensing:
%
%    This code is distributed under the MIT license.
%
%  Modified:
%
%    05 September 2022
%
%  Author:
%
%    John Burkardt
%
  addpath ( '../mandelbrot_orbit' );

  timestamp ( );
  fprintf ( 1, '\n' );
  fprintf ( 1, 'mandelbrot_orbit_test():\n' );
  fprintf ( 1, '  mandelbrot_orbit() applies n steps of the mandebrlot\n' );
  fprintf ( 1, '  iteration z = z^2 + c to a given starting point z0.\n' );

  n = 100;

  for test = 1 : 8

    if ( test == 1 )
      z0 = complex ( -0.04, 0.6 );
    elseif ( test == 2 )
      z0 = complex ( -1.0, 0.1 );
    elseif ( test == 3 )
      z0 = complex ( -0.8, 0.01 );
    elseif ( test == 4 )
      z0 = complex ( -0.6, 0.2 );
    elseif ( test == 5 )
      z0 = complex ( -0.4, 0.4 );
    elseif ( test == 6 )
      z0 = complex ( -0.2, 0.6 );
    elseif ( test == 7 )
      z0 = complex ( 0.0, 0.4 );
    elseif ( test == 8 )
      z0 = complex ( 0.1, 0.2 );
    end

    z = mandelbrot_orbit ( z0, n )

    clf ( );
    plot ( real ( z ), imag ( z ), '.', 'markersize', 15 );
    grid ( 'on' );
    axis ( 'equal' );
    s = sprintf ( 'z0=%g+%gi', real ( z0 ), imag ( z0 ) );
    title ( s );
    filename = sprintf ( 'mandelbrot_orbit_test%d.png', test );
    print ( '-dpng', filename );
    fprintf ( 1, '  Graphics saved as "%s"\n', filename );

  end
%
%  Terminate.
%
  fprintf ( 1, '\n' );
  fprintf ( 1, 'mandelbrot_orbit_test():\n' );
  fprintf ( 1, '  Normal end of execution.\n' );
  timestamp ( );
  rmpath ( '../mandelbrot_orbit' );

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

