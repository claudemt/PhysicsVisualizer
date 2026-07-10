function gaussian_prime_spiral_test ( )

%*****************************************************************************80
%
%% gaussian_prime_spiral_test() tests gaussian_prime_spiral().
%
%  Licensing:
%
%    This code is distributed under the MIT license.
%
%  Modified:
%
%    27 January 2023
%
%  Author:
%
%    John Burkardt
%
  addpath ( '../gaussian_prime_spiral' );

  timestamp ( );
  fprintf ( 1, '\n' );
  fprintf ( 1, 'gaussian_prime_spiral_test():\n' );
  fprintf ( 1, '  MATLAB/Octave version %s\n', version ( ) );
  fprintf ( 1, '  Test gaussian_prime_spiral()\n' );
%
%  Display Gaussian primes in a rectangular region.
%
  fprintf ( 1, '\n' );
  fprintf ( 1, '  gaussian_prime_display() displays Gaussian primes.\n' );

  clo = - 10 - 10i;
  chi = + 10 + 10i;
  gaussian_prime_display ( clo, chi );
%
%  Compute Gaussian prime spiral from given starting point.
%
  fprintf ( 1, '\n' );
  fprintf ( 1, '  gaussian_prime_spiral_trajectory() computes a spiral path.\n' );

  c = - 12 - 7i;
  d = +1;

  cvec = gaussian_prime_spiral_trajectory ( c, d );

  clf ( );
  hold ( 'on' );
    plot ( real ( cvec ), imag ( cvec ), 'b-' );
    plot ( real ( cvec ), imag ( cvec ), 'k.', 'markersize', 10 );
    for i = 1 : length ( cvec )
      if ( is_gaussian_prime ( cvec(i) ) )
        plot ( real ( cvec(i) ), imag ( cvec(i) ), 'r.', 'markersize', 10 );
      else
        plot ( real ( cvec(i) ), imag ( cvec(i) ), 'k.', 'markersize', 10 );
      end
    end
    plot ( real ( cvec(1) ), imag ( cvec(1) ), 'g.', 'markersize', 15 );
  hold ( 'off' );
  axis ( 'equal' );
  grid ( 'on' );
  title ( 'Gaussian prime spiral' );
  filename = 'gaussian_prime_spiral.png';
  print ( '-dpng', filename );
  fprintf ( 1, '  Graphics saved as "%s"\n', filename );
%
%  Terminate.
%
  fprintf ( 1, '\n' );
  fprintf ( 1, 'gaussian_prime_spiral_test():\n' );
  fprintf ( 1, '  Normal end of execution.\n' );
  fprintf ( 1, '\n' );
  timestamp ( );

  rmpath ( '../gaussian_prime_spiral' );

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

