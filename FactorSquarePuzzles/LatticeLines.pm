package LatticeLines;

use List::Util qw ( min max sum );
use lib '/home/tomfy/Non-work/SvgPatternMaker';
use TLYVector qw( add_V subtract_V );

# object to hold a set of line segments between lattice points.
#
# stroke:#000000;stroke-width:20;stroke-linecap:round

my %defaults = ('basis' => [[1,0], [0,1]],
		'offset' => [0,0],
		'min_x' => undef, 'min_y' => undef,
		'max_x' => undef, 'max_y' => undef,
		'font-size' => 24,
		'text-anchor' => 'middle',
		'lines' => undef,
		'line_options' =>
		{'stroke' => '#000000',
		 'stroke-width' => '1',
		 'stroke-linecap' => 'round'},
		'arrows' => undef,
		'show_clues' => 1,
		'show_answers' => 0,
		'show_arrows' => 1
	       );

sub new{
  my $class        = shift;
  my $self         = bless {}, $class;

  my $args_href = shift || undef; 
  foreach (keys %defaults) {
    $self->{$_} = $defaults{$_}; #
  }
  if (defined $args_href) {
    foreach (keys %$args_href) {
      if ($_ eq 'line_options') {
	foreach my $line_option (keys %{$args_href->{'line_options'}}) {
	  my $value = $args_href->{'line_options'}->{$line_option};
	  $self->{'line_options'}->{$line_option} = $value;
	}
      } else {
	$self->{$_} = $args_href->{$_};
      }
    }
  }
  my $dimensions = scalar @{$self->{'basis'}->[0]};
  foreach (@{$self->{'basis'}}) {
    my $dim = scalar @{$_};
    warn "dimensions of basis vectors not all same. $dim  $dimensions \n" if($dim != $dimensions);
  }
  $self->{'lines'} = {};
  return $self;
}

sub add_line{ # adds a line and updates the min and max 
# euclidean x and y.
  my $self = shift;
  my $endpoints = shift;	# string e.g. '0,1,1,0' 
  my $new_line_option_hashref = shift || {};
  my %line_option_hash = ();
  foreach (keys %{$self->{line_options}}) {
    $line_option_hash{$_} = $self->{line_options}->{$_};
  }
  foreach (keys %$new_line_option_hashref) {
    $line_option_hash{$_} = $new_line_option_hashref->{$_};
  }

  $self->{'lines'}->{$endpoints} = \%line_option_hash; #overrides any existing line with same endpoints.
  my ($a1, $a2, $b1, $b2) = split(",", $endpoints);
  my ($ax, $ay) = $self->_to_euclidean($a1, $a2);
  my ($bx, $by) = $self->_to_euclidean($b1, $b2);

  $self->{min_x} = (defined $self->{min_x})? 
    min($ax, $bx, $self->{min_x}) : min($ax, $bx);
 $self->{min_y} = (defined $self->{min_y})? min($ay, $by, $self->{min_y}) : min($ay, $by);
  $self->{max_x} = (defined $self->{max_x})? 
    max($ax, $bx, $self->{max_x}) : max($ax, $bx);
 $self->{max_y} = (defined $self->{max_y})? 
   max($ay, $by, $self->{max_y}) : max($ay, $by);
}

sub add_clue_text{
 my $self = shift;
  my $text_string = shift;	# string 
  my $position = shift;
  $self->{'clues'}->{$position} = $text_string; #overrides any existing text at same position.
}

sub add_answer_text{
 my $self = shift;
  my $text_string = shift;	# string
  my $position = shift;
  $self->{'answers'}->{$position} = $text_string; #overrides any existing text at same position.
}

sub add_arrow{
  my $self = shift;
  my $endpoints = shift;	# string e.g. '0,1,1,0' 
  my $new_line_option_hashref = shift || {};
  my %line_option_hash = ();
  foreach (keys %{$self->{line_options}}) {
    $line_option_hash{$_} = $self->{line_options}->{$_};
  }
  foreach (keys %$new_line_option_hashref) {
    $line_option_hash{$_} = $new_line_option_hashref->{$_};
  }
  my ($h, $t) = (0.15, 0.25);
  my ($a1, $a2, $b1, $b2) = split(",", $endpoints);
my ($aa1, $aa2, $bb1, $bb2) = ($aa1*(1-$h) + $bb1*$h, $aa2*(1-$h) + $bb2*$h,
  $aa1*$t + $bb1*(1-$t), $aa2*$t + $bb2*(1-$t));
$endpoints = "$aa1,$aa2,$bb1,$bb2";
  $self->{'arrows'}->{$endpoints} = \%line_option_hash; #overrides any existing line with same endpoints.
#  my ($a1, $a2, $b1, $b2) = split(",", $endpoints);
 #  my ($ax, $ay) = $self->_to_euclidean($a1, $a2);
 #  my ($bx, $by) = $self->_to_euclidean($b1, $b2);

 #  $self->{min_x} = (defined $self->{min_x})? 
 #    min($ax, $bx, $self->{min_x}) : min($ax, $bx);
 # $self->{min_y} = (defined $self->{min_y})? min($ay, $by, $self->{min_y}) : min($ay, $by);
 #  $self->{max_x} = (defined $self->{max_x})? 
 #    max($ax, $bx, $self->{max_x}) : max($ax, $bx);
 # $self->{max_y} = (defined $self->{max_y})? 
 #   max($ay, $by, $self->{max_y}) : max($ay, $by);
}


sub min_max_x_y{
  my $self = shift;
  my %endpts_options_hash = %{$self->{'lines'}};
  my ($min_x, $min_y, $max_x, $max_y) = (100000, 100000, -100000, -100000);
  foreach my $endpts_string (keys %endpts_options_hash) {
    my ($a1, $a2, $b1, $b2) = split(",", $endpts_string);
    my ($ax, $ay) = $self->_to_euclidean($a1, $a2);
    my ($bx, $by) = $self->_to_euclidean($b1, $b2);
    if ($ax < $min_x) {
      $min_x = $ax;
    }
    if ($bx < $min_x) {
      $min_x = $bx;
    }
    if ($ay < $min_y) {
      $min_y = $ay;
    }
    if ($by < $min_y) {
      $min_y = $by;
    }

    if ($ax > $max_x) {
      $max_x = $ax;
    }
    if ($bx > $max_x) {
      $max_x = $bx;
    }
    if ($ay > $max_y) {
      $max_y = $ay;
    }
    if ($by > $max_y) {
      $max_y = $by;
    }
  }

  return ($min_x, $min_y, $max_x, $max_y);
}

sub show_lines_and_options{
  my $self = shift;
  my %endpts_lineoptions = %{$self->{'lines'}};
  foreach my $endpts (keys %endpts_lineoptions) {
    print "endpoints: $endpts \n";
    my %lineoptions = %{$endpts_lineoptions{$endpts}};
    foreach (keys %lineoptions) {
      print "line style option $_  ", $lineoptions{$_}, "\n";
    }
  }
}

sub _to_euclidean{ # given a position represented as a linear combination
# of the basis vectors (the coefficients being given as arguments)
# return the corresponding euclidean (x and y) coordinates.
  my $self = shift;
  my ($a1, $a2) = @_;
my $basis = $self->{'basis'};

    my $a_x = $basis->[0]->[0] * $a1 + $basis->[1]->[0] * $a2; # + $offset->[0];
    my $a_y = $basis->[0]->[1] * $a1 + $basis->[1]->[1] * $a2; # + $offset->[1];
  return ($a_x, $a_y);
}

sub _offset{ # 
my $self = shift;
my ($ax, $ay) = @_;
my $offset = $self->{'offset'};
return ($ax + $offset->[0], $ay + $offset->[1]);
}

sub clues_svg{
my $self = shift;
 my %position_clue = %{$self->{clues}};
  my $text_svg_string = '';
  foreach my $clue_position (keys %position_clue) {
    my $clue_text = $position_clue{$clue_position};
    my @position_array = split(',', $clue_position);
    $text_svg_string .= $self->text_svg($clue_text, \@position_array);
  }
return $text_svg_string;
}

sub answers_svg{
my $self = shift;
 my %position_answer = %{$self->{answers}};
  my $text_svg_string = '';
  foreach my $answer_position (keys %position_answer) {
    my $answer_text = $position_answer{$answer_position};
    my @position_array = split(',', $answer_position);
    $text_svg_string .= $self->text_svg($answer_text, \@position_array);
  }
return $text_svg_string;
}



sub svg_string{
  my $self = shift;
  my $svg_string = '';
  my %endpt_lineoptions = %{$self->{'lines'}};
  my $basis = $self->{'basis'};
  my $offset = $self->{'offset'};
# print "top of svg_string \n";
my ($min_x, $min_y, $max_x, $max_y) = $self->min_max_x_y();
$min_xy = [$min_x, $min_y];
  foreach my $endpts (keys %endpt_lineoptions) {
    my ($a1, $a2, $b1, $b2) = split(",", $endpts);
# print "in svg_string: a1,a2,b1,b2: $a1, $a2, $b1, $b2 \n";
my ($a_x, $a_y) = $self->_to_euclidean($a1, $a2);
my ($b_x, $b_y) = $self->_to_euclidean($b1, $b2);

($a_x, $a_y) = @{subtract_V([$a_x, $a_y], $min_xy)};
($b_x, $b_y) = @{subtract_V([$b_x, $b_y], $min_xy)};

($a_x, $a_y) = @{add_V([$a_x, $a_y], $offset)};
($b_x, $b_y) = @{add_V([$b_x, $b_y], $offset)};

    $svg_string .= "<line \n" .
      "x1=\"$a_x\" y1=\"$a_y\"    " .
	"x2=\"$b_x\" y2=\"$b_y\"\n" .
	  "style=\"";
    # $svg_string .= 'style=\"';
    my %line_options = %{$endpt_lineoptions{$endpts}};
    #print "Line style OPTIONS: ", join("; ", keys %line_options), "\n";
    
    foreach my $option_name (keys %line_options) {
      #      print "$option_name ", $line_options{$option_name}, "\n";
      $svg_string .= $option_name . ':' . $line_options{$option_name} . ';';
    }
    $svg_string =~ s/;$//;	# remove final ';' if present.
    $svg_string .= "\"";
    $svg_string .= "\n" . 'id="' . $endpts . "\"/>\n";
  }

if($self->{show_clues}){
 $svg_string .= $self->clues_svg();
}
if($self->{show_answers}){
  $svg_string .= $self->answers_svg();
}
  return $svg_string;
}

sub point_position{
  my $self = shift;
  my $point = shift;		# array ref
  my ($c1, $c2) = @{$point};
  my $basis = $self->{basis};
#  my $offset = $self->{offset};

  my $b_x = $basis->[0]->[0] * $c1 + $basis->[1]->[0] * $c2; # + $offset->[0];
  my $b_y = $basis->[0]->[1] * $c1 + $basis->[1]->[1] * $c2; # + $offset->[1];
 
# ($b_x, $b_y) = @{add_V([$b_x, $b_y], $self->{'offset'})};
my $min_xy = [$self->{min_x}, $self->{min_y}];
($b_x, $b_y) = @{subtract_V([$b_x, $b_y], $min_xy)}; #[$self->{min_x}, $self->{min_y}])};
($b_x, $b_y) = @{add_V([$b_x, $b_y], $self->{'offset'})}; 
  return [$b_x, $b_y];
}

sub text_svg{ # print the text (1st arg) at the position (2nd arg).
# by default use the objects font-size and text-anchor
  my $self = shift;
  my $text = shift;
  my $point = shift;   # array ref giving coefficents of basis vectors
  my $font_size = shift || $self->{'font-size'};
  my $text_anchor = shift || $self->{'text-anchor'};
  my ($x, $y) = @{$self->point_position($point)};
  # <text x="250" y="150"  font-family="Verdana" font-size="55" fill="blue" > Hello, out there </text>

  my $svg_text_string = '<text x="' . $x . '" y="' . $y . '" ';
  $svg_text_string .= ' font-size="' . $font_size . '" style="text-anchor:' . $text_anchor . '" > ' . $text . "</text>\n";
  return $svg_text_string;
}


1;

