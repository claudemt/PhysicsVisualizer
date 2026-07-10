function henon_orbit ( c, data, filename )

%*****************************************************************************80
%
%% henon_orbit() plots the Henon dynamical system map for given starting values.
%
%  Discussion:
%
%    This code reproduces plots of Henon's dynamical system.
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
%  Input:
%
%    real c: the cosine of alpha, the dynamical system parameter.
%
%    data(*,3): sets of x, y, n initial values.
%
%    string filename: the name of the file in which the plot is to be saved.
%

%
%  Compute the sine of alpha.
%
  s = sqrt ( 1.0 - c * c );

  clf ( );
  hold ( 'on' );

  [ data_num, d ] = size ( data );

  for i = 1 : data_num

    x = data(i,1);
    y = data(i,2);
    n = data(i,3);
%
%  Choose a random RGB color for each starting point.
%
    r = rand ( );
    g = rand ( );
    b = rand ( );
    col = [ r, g, b ];

    for k = 1 : n

      if ( abs ( x ) < 1.0 && abs ( y ) < 1.0 )
        xnew = x * c - ( y - x * x ) * s;
        ynew = x * s + ( y - x * x ) * c;
        x = xnew;
        y = ynew;
        plot ( x, y, '.', 'markersize', 2.0, 'color', col );
      end

    end

  end

  axis ( 'equal' );
  title ( filename );
  hold ( 'off' );
  print ( '-dpng', filename );
  fprintf ( 1, '  Graphics saved as "%s"\n', filename );
  close ( );

  return
