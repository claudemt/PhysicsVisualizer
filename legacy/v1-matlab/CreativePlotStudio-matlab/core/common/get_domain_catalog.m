function catalog = get_domain_catalog(domain)
switch lower(char(domain))
    case 'art'
        catalog(1).category = 'Pixel & Texture';
        catalog(1).folder = 'pixel_texture';
        catalog(1).items = {'Bitwise Fractal','Tablecloth','Music Score'};
        catalog(2).category = 'Floral & Botanical';
        catalog(2).folder = 'floral_botanical';
        catalog(2).items = {'Sakura Tree','Blue Rose','Blooming Rose','Rose Ball'};
        catalog(3).category = 'Scenes & Objects';
        catalog(3).folder = 'scenes_objects';
        catalog(3).items = {'Crystal Cluster','Crystal Heart','Moonlit Mountains','Fireworks','Ice Cream Soft Serve','Ice Cream Bouquet','Art Candlesticks'};
        catalog(4).category = 'Generative Art';
        catalog(4).folder = 'generative_art';
        catalog(4).items = {'Phyllotaxis Sunflower','Superformula Bloom','Plasma Clouds'};

    case 'fractals'
        catalog(1).category = 'Escape-Time & Julia';
        catalog(1).folder = 'escape_time_julia';
        catalog(1).items = {'Mandelbrot Garden','Julia Nebula','Burning Ship Ember','Tricorn Mandelbar','Phoenix Julia','Multibrot Cubic','Celtic Mandelbrot','Perpendicular Burning Ship'};
        catalog(2).category = 'Newton & Orbit Traps';
        catalog(2).folder = 'newton_orbit_traps';
        catalog(2).items = {'Newton Basin','Nova Cubic Basin','Orbit Trap Pearls'};
        catalog(3).category = 'Recursive & IFS';
        catalog(3).folder = 'recursive_ifs';
        catalog(3).items = {'Barnsley Fern','Sierpinski Carpet','Apollonian Gasket','Dragon Curve','Koch Snowflake','Levy C Curve','Pythagoras Tree','Vicsek Fractal','DLA Cluster'};
        catalog(4).category = 'Fractal Fields';
        catalog(4).folder = 'fractal_fields';
        catalog(4).items = {'Lyapunov Carpet','Gray-Scott Coral'};

    case 'nonlinear'
        catalog(1).category = 'Strange Attractors';
        catalog(1).folder = 'strange_attractors';
        catalog(1).items = {'Lorenz Attractor','Rossler Ribbon','Chua Double Scroll','Clifford Attractor','Aizawa Attractor','Thomas Attractor','Dadras Attractor','De Jong Attractor','Hopalong Attractor'};
        catalog(2).category = 'Maps & Bifurcations';
        catalog(2).folder = 'maps_bifurcations';
        catalog(2).items = {'Henon Map','Standard Map Islands','Ikeda Map','Logistic Bifurcation','Circle Map Tongues','Lyapunov Carpet'};
        catalog(3).category = 'Oscillators & Vibration';
        catalog(3).folder = 'oscillators_vibration';
        catalog(3).items = {'Duffing Poincare','Duffing Sweep','Van der Pol Phase','Double Pendulum Trace','Chladni Resonance','Lissajous Knot'};
        catalog(4).category = 'Reaction Waves';
        catalog(4).folder = 'reaction_waves';
        catalog(4).items = {'Gray-Scott Coral','FitzHugh-Nagumo Spiral'};

    otherwise
        catalog = get_domain_catalog('art');
end
end
