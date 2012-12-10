package LatticeLines;

use Math::Trig;
use List::Util qw ( min max sum );
use lib '/home/tomfy/Non-Work/SvgPatternMaker';
use lib '/home/tomfy/Non-work/SvgPatternMaker';
use TLYVector qw( add_V subtract_V scalar_mult_V rotate_2d_V );

# object to hold a set of line segments between lattice points.
#
# stroke:#000000;stroke-width:20;stroke-linecap:round

my %defaults = (
    'basis' => [ [ 1, 0 ], [ 0, 1 ] ],

    #    'offset'       => [ 0, 0 ],
    'min_x'        => undef,
    'min_y'        => undef,
    'max_x'        => undef,
    'max_y'        => undef,
    'font-size'    => 0.4,
    'text-anchor'  => 'middle',
    'lines'        => undef,
    'circles' => undef,
    'line_options' => {
        'stroke'         => '#000000',
        'stroke-width'   => '1',
        'stroke-linecap' => 'round'
    },
    'arrows'       => {},
    'show_clues'   => 1,
    'show_answers' => 0,
    'show_arrows'  => 1,
    'clues'        => {},
    'answers'      => {}
);

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    my $args_href = shift || undef;
    foreach ( keys %defaults ) {
        $self->{$_} = $defaults{$_};    #
    }
    if ( defined $args_href ) {
        foreach ( keys %$args_href ) {
            if ( $_ eq 'line_options' ) {
                foreach
                  my $line_option ( keys %{ $args_href->{'line_options'} } )
                {
                    my $value = $args_href->{'line_options'}->{$line_option};
                    $self->{'line_options'}->{$line_option} = $value;
                }
            }
            else {
                $self->{$_} = $args_href->{$_};
            }
        }
    }
    my $dimensions = scalar @{ $self->{'basis'}->[0] };
    foreach ( @{ $self->{'basis'} } ) {
        my $dim = scalar @{$_};
        warn "dimensions of basis vectors not all same. $dim  $dimensions \n"
          if ( $dim != $dimensions );
    }
    $self->{'lines'} = {};
    $self->{'circles'} = {};
    return $self;
}

sub put_ll_corner_at_origin {

}

sub translate_by {
    my $self = shift;
    my ( $dx, $dy ) = @_;    # vector to shift by

}

sub add_line {               # adds a line and updates the min and max
    my $self = shift;
    my $endpoints =
      shift;    # string e.g. '0,1,1,0'; these are coefficients of basis vectors

    # or array ref [0,1,1,0]
    if ( ref($endpoints) eq 'ARRAY' ) {    # stringify
        $endpoints = join( ",", @$endpoints );
    }
    my $new_line_option_hashref = shift || {};
    my %line_option_hash = ();
    foreach ( keys %{ $self->{line_options} } ) {
        $line_option_hash{$_} = $self->{line_options}->{$_};
    }
    foreach ( keys %$new_line_option_hashref ) {
        $line_option_hash{$_} = $new_line_option_hashref->{$_};
    }

    $self->{'lines'}->{$endpoints} =
      \%line_option_hash;    #overrides any existing line with same endpoints.
    my ( $a1, $a2, $b1, $b2 ) = split( ",", $endpoints );

    my ( $ax, $ay ) = $self->_to_euclidean( $a1, $a2 );
    my ( $bx, $by ) = $self->_to_euclidean( $b1, $b2 );

    $self->update_x_y_bounds( $ax, $ay );
    $self->update_x_y_bounds( $bx, $by );
}

sub update_x_y_bounds {
    my $self = shift;
    my ( $x, $y ) = @_;
    $self->{min_x} =
      ( defined $self->{min_x} ) ? min( $x, $self->{min_x} ) : $x;
    $self->{min_y} =
      ( defined $self->{min_y} ) ? min( $y, $self->{min_y} ) : $y;
    $self->{max_x} =
      ( defined $self->{max_x} ) ? max( $x, $self->{max_x} ) : $x;
    $self->{max_y} =
      ( defined $self->{max_y} ) ? max( $y, $self->{max_y} ) : $y;
}

sub add_clue_text {
    my $self        = shift;
    my $text_string = shift;    # string
    my $position    = shift;
    if ( ref($position) eq 'ARRAY' ) {    # stringify
        $position = join( ",", @$position );
    }
    $self->{'clues'}->{$position} =
      $text_string;    #overwrites any existing text at same position.
}

sub add_answer_text {
    my $self        = shift;
    my $text_string = shift;    # string
    my $position    = shift;
    if ( ref($position) eq 'ARRAY' ) {    # stringify
        $position = join( ",", @$position );
    }
    $self->{'answers'}->{$position} =
      $text_string;    #overwrites any existing text at same position.
}

sub add_arrow {
    my $self                    = shift;
    my $endpoints               = shift;         # string e.g. '0,1,1,0'
    my $new_line_option_hashref = shift || {};
    if ( ref($endpoints) eq 'ARRAY' ) {          # stringify
        $endpoints = join( ",", @$endpoints );
    }

    my %line_option_hash = ();
    foreach ( keys %{ $self->{line_options} } ) {
        $line_option_hash{$_} = $self->{line_options}->{$_};
    }
    foreach ( keys %$new_line_option_hashref ) {
        $line_option_hash{$_} = $new_line_option_hashref->{$_};
    }
    my ( $h, $t ) = ( 0.5, 0.2 );
    my ( $a1, $a2, $b1, $b2 ) = split( ",", $endpoints );

    #print "$a1, $a2, $b1, $b2\n";
    my ( $aa1, $aa2, $bb1, $bb2 ) = (
        $a1 * ( 1 - $h ) + $b1 * $h,
        $a2 * ( 1 - $h ) + $b2 * $h,
        $a1 * $t + $b1 * ( 1 - $t ),
        $a2 * $t + $b2 * ( 1 - $t )
    );

    $endpoints = "$aa1,$aa2,$bb1,$bb2";

    $self->{'arrows'}->{$endpoints} =
      \%line_option_hash;    #overrides any existing line with same endpoints.
}

sub add_circle {
    my $self   = shift;
    my $center = shift
      ; # string e.g. '0,1'; these are coefficients of basis vectors, not (necessarily) euclidean
    my $radius = shift;
    $self->{'circles'}->{$center} = $radius;    #
}

sub min_max_x_y {
    my $self                = shift;
    my %endpts_options_hash = %{ $self->{'lines'} };
    my ( $min_x, $min_y, $max_x, $max_y ) =
      ( 100000, 100000, -100000, -100000 );
    foreach my $endpts_string ( keys %endpts_options_hash ) {
        my ( $a1, $a2, $b1, $b2 ) = split( ",", $endpts_string );
        my ( $ax, $ay ) = $self->_to_euclidean( $a1, $a2 );
        my ( $bx, $by ) = $self->_to_euclidean( $b1, $b2 );
        if ( $ax < $min_x ) {
            $min_x = $ax;
        }
        if ( $bx < $min_x ) {
            $min_x = $bx;
        }
        if ( $ay < $min_y ) {
            $min_y = $ay;
        }
        if ( $by < $min_y ) {
            $min_y = $by;
        }

        if ( $ax > $max_x ) {
            $max_x = $ax;
        }
        if ( $bx > $max_x ) {
            $max_x = $bx;
        }
        if ( $ay > $max_y ) {
            $max_y = $ay;
        }
        if ( $by > $max_y ) {
            $max_y = $by;
        }
    }

    return ( $min_x, $min_y, $max_x, $max_y );
}

sub show_lines_and_options {
    my $self               = shift;
    my %endpts_lineoptions = %{ $self->{'lines'} };
    foreach my $endpts ( keys %endpts_lineoptions ) {
        print "endpoints: $endpts \n";
        my %lineoptions = %{ $endpts_lineoptions{$endpts} };
        foreach ( keys %lineoptions ) {
            print "line style option $_  ", $lineoptions{$_}, "\n";
        }
    }
}

sub _to_euclidean {    # given a position represented as a linear combination
        # of the basis vectors (the coefficients being given as arguments)
        # return the corresponding euclidean (x and y) coordinates.
    my $self = shift;
    my ( $a1, $a2 ) = @_;
    my $basis = $self->{'basis'};

    my $a_x = $basis->[0]->[0] * $a1 + $basis->[1]->[0] * $a2;
    my $a_y = $basis->[0]->[1] * $a1 + $basis->[1]->[1] * $a2;
    return ( $a_x, $a_y );
}

sub _offset {    #
    my $self = shift;
    my ( $ax, $ay ) = @_;
    my $offset = $self->{'offset'};
    return ( $ax + $offset->[0], $ay + $offset->[1] );
}

sub lines_svg {    # return svg

    # for the line segments in the object's 'lines' hash.
    my $self       = shift;
    my $offset     = shift;    # array ref
    my $scale      = shift;
    my $svg_string = '';

    my %endpt_lineoptions = %{ $self->{lines} };
    my $basis             = $self->{basis};

    my $min_xy = [ $self->{min_x}, $self->{min_y} ];
    foreach my $endpts ( keys %endpt_lineoptions ) {
        my ( $a1, $a2, $b1, $b2 ) = split( ",", $endpts );
        my ( $a_x, $a_y ) = $self->_to_euclidean( $a1, $a2 );
        my ( $b_x, $b_y ) = $self->_to_euclidean( $b1, $b2 );
        $svg_string .=
          $self->line_svg( [ $a_x, $a_y ], [ $b_x, $b_y ], $offset, $scale );

        my $line_options = $endpt_lineoptions{$endpts};

        #	$line_options->{'stroke-width'} *= $scale;
        $svg_string .= $self->line_options_svg( $line_options, $scale );
        $svg_string .= 'id="' . $endpts . "\"/>\n";
    }
    return $svg_string;
}

sub circles_svg {
    my $self       = shift;
    my $offset     = shift;
    my $scale      = shift;
    my $svg_string = '';
    foreach my $center ( keys %{$self->{'circles'}} ) {
        my $radius = $self->{'circles'}->{$center};
        my ( $a_x, $a_y ) = $self->_to_euclidean( split( ",", $center ) );
        my $a = [ $a_x, $a_y ];
        $a = subtract_V( $a, [ $self->{min_x}, $self->{min_y} ] );

        # now scale
        #    print STDERR "in line_svg. scale: [$scale]\n";
        $a = scalar_mult_V( $scale, $a );
        $b = scalar_mult_V( $scale, $b );

        ( $a_x, $a_y ) = @{ add_V( $a, $offset ) };

        $svg_string .=
	  '<circle cx="' . $a_x . '" cy="' . $a_y . '" r="' . $scale*$radius 
	    . '" stroke="black" stroke-width="2" style="fill: rgba(0, 0, 0, 0)"/>';

    }
    return $svg_string;
}

sub line_options_svg {
    my $self         = shift;
    my $line_options = shift;
    my $scale        = shift || 1;
    my $svg_string   = '';
    foreach my $option_name ( keys %$line_options ) {
        my $option_value = $line_options->{$option_name};
        $option_value *= $scale if ( $option_name eq 'stroke-width' );
        $svg_string .= $option_name . ':' . $option_value . ';';
    }
    $svg_string =~ s/;$//;    # remove final ';' if present.
    $svg_string .= "\"\n";
    return $svg_string;
}

sub clues_svg {
    my $self            = shift;
    my $offset          = shift;                 # array ref
    my $scale           = shift;
    my %position_clue   = %{ $self->{clues} };
    my $text_svg_string = '';
    foreach my $clue_position ( keys %position_clue ) {
        my $clue_text = $position_clue{$clue_position};
        my @position_array = split( ',', $clue_position );
        $text_svg_string .=
          $self->text_svg( $clue_text, \@position_array, $offset, $scale );
    }
    return $text_svg_string;
}

sub answers_svg {
    my $self            = shift;
    my $offset          = shift;                   # array ref
    my $scale           = shift;
    my %position_answer = %{ $self->{answers} };
    my $text_svg_string = '';
    foreach my $answer_position ( keys %position_answer ) {
        my $answer_text = $position_answer{$answer_position};
        my @position_array = split( ',', $answer_position );
        $text_svg_string .=
          $self->text_svg( $answer_text, \@position_array, $offset, $scale );
    }
    return $text_svg_string;
}

sub svg_string {
    my $self             = shift;
    my $offset           = shift;
    my $scale            = shift;
    my $what_to_show_arg = shift || {};
    for ( keys %$what_to_show_arg ) {
        $self->{$_} = $what_to_show_arg->{$_};
    }

    my $svg_string = $self->lines_svg( $offset, $scale );
$svg_string .= $self->circles_svg( $offset, $scale );

    if ( $self->{show_clues} ) {
        $svg_string .= $self->clues_svg( $offset, $scale );
    }
    if ( $self->{show_answers} ) {
        $svg_string .= $self->answers_svg( $offset, $scale );
    }
    if ( $self->{show_arrows} ) {
        $svg_string .= $self->arrows_svg( $offset, $scale );
    }

#$svg_string .= '<circle cx="100" cy="50" r="40" stroke="black" stroke-width=2 />';
    return $svg_string;
}

sub point_position {
    my $self   = shift;
    my $point  = shift;    # array ref
    my $offset = shift;    # array ref
    my $scale  = shift;

    my ( $b_x, $b_y ) = $self->_to_euclidean( @{$point} );
    my $min_xy = [ $self->{min_x}, $self->{min_y} ];
    my $b = subtract_V( [ $b_x, $b_y ], $min_xy );

    # print STDERR "in point_position. scale: [$scale]\n";
    $b = scalar_mult_V( $scale, $b );
    $b = add_V( $b, $offset );
    return $b;
}

sub text_svg {    # print the text (1st arg) at the position (2nd arg).

    # by default use the objects font-size and text-anchor
    my $self   = shift;
    my $text   = shift;
    my $point  = shift;    # array ref giving coefficents of basis vectors
    my $offset = shift;    # array ref
    my $scale  = shift;
    my $font_size = int( $scale * $self->{'font-size'} );

    #   print STDERR "font size: $font_size , scale: $scale \n";
    my $text_anchor = shift || $self->{'text-anchor'};
    my $p = $self->point_position( $point, $offset, $scale );

    my $svg_text_string = '<text x="' . $p->[0] . '" y="' . $p->[1] . '" ';
    $svg_text_string .=
        ' font-size="'
      . $font_size
      . '" style="text-anchor:'
      . $text_anchor . '" > '
      . $text
      . "</text>\n";
    return $svg_text_string;
}

sub arrows_svg {
    my $self              = shift;
    my $offset            = shift;
    my $scale             = shift;
    my $svg_string        = '';
    my %endpt_lineoptions = %{ $self->{'arrows'} };
    my $basis             = $self->{'basis'};

    foreach my $endpts ( keys %endpt_lineoptions ) {
        my ( $a1, $a2, $b1, $b2 ) = split( ",", $endpts );

        my ( $a_x, $a_y ) = $self->_to_euclidean( $a1, $a2 );
        my ( $b_x, $b_y ) = $self->_to_euclidean( $b1, $b2 );

        $svg_string .=
          $self->line_svg( [ $a_x, $a_y ], [ $b_x, $b_y ], $offset, $scale );
        my $line_options = $endpt_lineoptions{$endpts};

        #	$line_options->{'stroke-width'} *= $scale;
        $svg_string .= $self->line_options_svg( $line_options, $scale );
        $svg_string .= 'id="' . $endpts . "\"/>\n";

        my $short_shaft_xy = scalar_mult_V( 0.4, [ $a_x - $b_x, $a_y - $b_y ] );
        my @barb1_xy = rotate_2d_V( @$short_shaft_xy, pi / 5 );
        my @barb2_xy = rotate_2d_V( @$short_shaft_xy, -1 * pi / 5 );

        $svg_string .= $self->line_svg(
            add_V( \@barb1_xy, [ $b_x, $b_y ] ),
            [ $b_x, $b_y ],
            $offset, $scale
        );
        $svg_string .= $self->line_options_svg( $line_options, $scale );
        $svg_string .= 'id="' . $endpts . ";b1\"/>\n";

        $svg_string .= $self->line_svg(
            add_V( \@barb2_xy, [ $b_x, $b_y ] ),
            [ $b_x, $b_y ],
            $offset, $scale
        );
        $svg_string .= $self->line_options_svg( $line_options, $scale );
        $svg_string .= 'id="' . $endpts . ";b2\"/>\n";
    }
    return $svg_string;
}

sub line_svg {    # takes euclidean endpoints a and b
    my $self   = shift;
    my $a      = shift;
    my $b      = shift;
    my $offset = shift || [ 0, 0 ];
    my $scale  = shift;

    $a = subtract_V( $a, [ $self->{min_x}, $self->{min_y} ] );
    $b =
      subtract_V( $b, [ $self->{min_x}, $self->{min_y} ] )
      ;           # so LL corner of bounding box is at origin

    # now scale
    #    print STDERR "in line_svg. scale: [$scale]\n";
    $a = scalar_mult_V( $scale, $a );
    $b = scalar_mult_V( $scale, $b );

    my ( $a_x, $a_y ) = @{ add_V( $a, $offset ) };
    my ( $b_x, $b_y ) = @{ add_V( $b, $offset ) };

    my $svg_string =
        "<line \n"
      . "x1=\"$a_x\" y1=\"$a_y\"    "
      . "x2=\"$b_x\" y2=\"$b_y\"\n"
      . "style=\"";
    return $svg_string;
}

sub get_xy_bounds {
    my $self = shift;
    return ( $self->{min_x}, $self->{min_y}, $self->{max_x}, $self->{max_y} );
}

1;

