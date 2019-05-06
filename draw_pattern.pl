#!/usr/bin/perl -w
use strict;
use Math::Trig;

use lib '/home/tomfy/Non-work/SvgPatternMaker';
#use UnitCell;
use Square;
use SnubSquare;
use CairoPentagonal;
use Hex;
use Triangle;
use TruncatedSquare;
use PenroseRhombs;
use TLYVector qw(add_V scalar_mult_V rotate_2d_V);
use Getopt::Long;

# read data from stdin
# -p <pattern>  choose the pattern ss, cp, tr, hx, ...
# -r <nrows> number of rows
# -c <ncols> number of cols
# -s <scale> scale (20-100 typical)
# -a <angle> angle param used in def of unit cell (for some patterns)
# -o <portrait landscape square> 
# actual angle is pi times this parameter.

my $pattern = undef;
my $scale = 50.0;
my $offset_factor = 0.2;
my $nrows = 10;
my $ncols = undef;
my $angle_param = 1.0/3.0;      # angle in radians.
my $orientation = 'portrait';
# print "[$opt_p, $opt_r, $opt_c, $opt_s, $opt_a] \n";

GetOptions(
           'pattern=s' => \$pattern,
           'scale=f' => \$scale,
           'angle_param=f' => \$angle_param,
           'nrows=i' => \$nrows,
           'ncols=i' => \$ncols,
           'orientation=s' => \$orientation,
          );

if (!defined $pattern) {
   print "Usage: draw_pattern -p <pattern> -r <nrows> -c <ncols> -s <scale> -a <angle_param> \n";
   print " possible patterns: Square SnubSquare CairoPentagonal Triangle Hex TruncatedSquare PenroseRhombs\n";
   print " Pattern must be specified on command line; other parameters have following defaults: \n";
   print " nrows: 10; ncols: nrows; scale 50; angle_param: 1/3. \n";
   print " The actual angle used is pi*angle_param, which is pi/3 by default. \n";
   print " Outputs svg to stdout. \n";
   exit;
}

my $angle = pi*$angle_param;
$ncols = $nrows if(! defined $ncols);

my $stroke_width = 1.2;
my $rgb = "50,50,50";           #"180,180,180";
my $ss = 1;
# whole figure is rotated by $overall_rotation_angle, and then
# translated by ($xoffset, $yoffset)
my $overall_rotation_angle = 0.0; # additional rotation of the entire pattern compared to default. 
my ($xoffset, $yoffset) = ($offset_factor*$scale, $offset_factor*$scale); 

my $unit_cell_obj;
if ($pattern eq 'Square') {
   $unit_cell_obj = Square->new($scale, $angle);
} elsif ($pattern eq 'SnubSquare') {
   $unit_cell_obj = SnubSquare->new($scale, $angle);
} elsif ($pattern eq 'CairoPentagonal') {
   $unit_cell_obj = CairoPentagonal->new($scale, $angle);
} elsif ($pattern eq 'Hex') {
   $unit_cell_obj = Hex->new($scale, $angle);
} elsif ($pattern eq 'Triangle') {
   $unit_cell_obj = Triangle->new($scale, $angle);
} elsif ($pattern eq 'TruncatedSquare') {
   $unit_cell_obj = TruncatedSquare->new($scale, $angle);
} elsif ($pattern eq 'PenroseRhombs') {
   $unit_cell_obj = PenroseRhombs->new($scale);
}

# get the set of lines forming the pattern:
my $pattern_lines_ref = pattern_from_unit_cell($unit_cell_obj, $nrows, $ncols, $overall_rotation_angle, $xoffset, $yoffset);

# generate the svg code for this set of lines:
my $svg_output_string = svg_output_lines($pattern_lines_ref, $rgb, $stroke_width, $orientation);

my $gnuplot_output_string = gnuplot_output_lines($pattern_lines_ref);

# print the svg to stdout:
print $svg_output_string;

#print in gnuplot format
# print $gnuplot_output_string, "\n";

# end of main

sub gnuplot_output_lines{

   my $lines_ref = shift;
   my $rgb = shift || "99,99,99";
   my $stroke_width = shift || 1;
   my $gnuplot_string = "";
   foreach my $line_ref (@$lines_ref) {
      my ($x1, $y1) = @{$line_ref->[0]};
      my ($x2, $y2) = @{$line_ref->[1]};
      $gnuplot_string .= "$x1  $y1 \n" . "$x2 $y2 \n\n";
   }
   return $gnuplot_string;
}


sub svg_output_lines{
   # returns a string containing svg code to draw the set of lines
   # just lots of individual lines, not polylines

   my $lines_ref = shift; # this is an array ref. Each elem of array is a ref to two pts
   # specifying the endpoints of the line segment. Each point is specified as a ref to an array of 
   # x and y coordinates.
   my $rgb = shift || "99,99,99";
   my $stroke_width = shift || 1;
   my $orientation = shift || 'portrait';

   # example of svg code for line:
   # ponoko requires fill:none, and small stroke-width. Not sure why stroke:#0000ff (i.e. black) here.
   #   id="line31515" /><line
   #     x1="1090.9858"
   #     y1="875.58185"
   #     x2="1049.9911"
   #     y2="946.58704"
   #     style="stroke:#0000ff;stroke-width:0.02834646000000000;stroke-opacity:1;stroke-miterlimit:4;stroke-dasharray:none;fill:none"

   # Letter size: 990 x 765
   my ($width, $height) = ($orientation eq 'portrait')? (765, 990): (990, 765);
   if ($orientation eq 'square') {
      $width = 765; $height = 765;
   } 
   # apparently 90 pixels = 1 inch, 8 1/2 inches = 720 + 45 = 765, check.
   # Not really sure of the significance of the width and height here - but using values for letter, 90 pixels/inch
   my $svg_string = '<?xml version="1.0" standalone="no"?> <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">' . "\n";
   $svg_string .= '<svg width="' . $width . '" height="' . $height . '" version="1.1" xmlns="http://www.w3.org/2000/svg">' . "\n";

   foreach my $line_ref (@$lines_ref) {
      my ($x1, $y1) = @{$line_ref->[0]};
      my ($x2, $y2) = @{$line_ref->[1]}; 
      # print "$x1, $x2 \n";

      $svg_string .= "<line x1=\"$x1\" y1=\"$y1\" x2=\"$x2\" y2=\"$y2\" style=\"" .  "stroke:rgb($rgb);stroke-width:$stroke_width;fill:none\"/>" . "\n";

   }

   $svg_string .= '</svg>' . "\n";
   return $svg_string;
}

sub pattern_from_unit_cell{

   my $unit_cell_obj = shift;
   my $nrows = shift;
   my $ncols = shift;
   my $overall_rotation_angle = shift;
   my $xoffset = shift;
   my $yoffset = shift;
   #	my $unit_cell_obj = shift;

   my $unit_lines = $unit_cell_obj->get_lines();
   my $edge_lines_1 = $unit_cell_obj->get_edge_lines_1();
   my $translation1 = $unit_cell_obj->get_translation_1();
   my $edge_lines_2 = $unit_cell_obj->get_edge_lines_2();
   my $translation2 = $unit_cell_obj->get_translation_2();

   my @lines = ();
   for (my $i=0; $i<$ncols; $i++) {
      for (my $j=0; $j<$nrows; $j++) {
         my $translation = add_V(scalar_mult_V($i, $translation1), scalar_mult_V($j, $translation2));
         foreach my $line (@{$unit_lines}) {
            my $p1_ref = $line->[0];
            my $p2_ref = $line->[1];
            my ($x1, $y1) = @{add_V( $p1_ref, $translation ) };
            my ($x2, $y2) = @{add_V( $p2_ref, $translation ) };

            ($x1, $y1) = rotate_2d_V($x1, $y1, $overall_rotation_angle);
            ($x2, $y2) = rotate_2d_V($x2, $y2, $overall_rotation_angle);
            $x1 += $xoffset; $x2 += $xoffset; 
            $y1 += $yoffset; $y2 += $yoffset;

            push @lines, [[$x1, $y1], [$x2, $y2]];
         }
      }
      # close off the ragged edges at the end of the column
      foreach my $line (@{$edge_lines_2}) {
         my $p1_ref = $line->[0];
         my $p2_ref = $line->[1];
         my $x1 = $p1_ref->[0] + $i * $translation1->[0] + $nrows * $translation2->[0];
         my $y1 = $p1_ref->[1] + $i * $translation1->[1] + $nrows * $translation2->[1];
         my $x2 = $p2_ref->[0] + $i * $translation1->[0] + $nrows * $translation2->[0];
         my $y2 = $p2_ref->[1] + $i * $translation1->[1] + $nrows * $translation2->[1];

         ($x1, $y1) = rotate_2d_V($x1, $y1, $overall_rotation_angle);
         ($x2, $y2) = rotate_2d_V($x2, $y2, $overall_rotation_angle);
         $x1 += $xoffset; $x2 += $xoffset;
         $y1 += $yoffset; $y2 += $yoffset;

         push @lines, [[$x1, $y1], [$x2, $y2]];
      }
   }

   # close off the ragged edges at the ends of the rows
   for (my $j = 0; $j < $nrows; $j++) {
      foreach my $line (@{$edge_lines_1}) {
         my $p1_ref = $line->[0];
         my $p2_ref = $line->[1];
         my $x1 = $p1_ref->[0] + $ncols * $translation1->[0] + $j * $translation2->[0];
         my $y1 = $p1_ref->[1] + $ncols * $translation1->[1] + $j * $translation2->[1];
         my $x2 = $p2_ref->[0] + $ncols * $translation1->[0] + $j * $translation2->[0];
         my $y2 = $p2_ref->[1] + $ncols * $translation1->[1] + $j * $translation2->[1];

         ($x1, $y1) = rotate_2d_V($x1, $y1, $overall_rotation_angle);
         ($x2, $y2) = rotate_2d_V($x2, $y2, $overall_rotation_angle);
         $x1 += $xoffset; $x2 += $xoffset;
         $y1 += $yoffset; $y2 += $yoffset;

         push @lines, [[$x1, $y1], [$x2, $y2]];
      }
   }
   return \@lines;
}
