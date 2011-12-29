#!/usr/bin/perl -w
use strict;
use Math::Trig;
use LatticeLines;

my $puzzle_obj = square9_puzzle();

# now put together the svg string:
my $svg_string = '<?xml version="1.0" standalone="no"?> <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">' . "\n";
$svg_string .= '<svg width="2000" height="2000" version="1.1" xmlns="http://www.w3.org/2000/svg">' . "\n";

# svg body:
$svg_string .= $puzzle_obj->svg_string();

# end of svg:
$svg_string .= '</svg>' . "\n";

print $svg_string, "\n";

# end of main.

sub square9_puzzle{
  my $numbers_string = shift || '1,1,1,2,2,3,3,5,7';
  my $scale = shift || 100;
  my @numbers = split(',', $numbers_string);
  my $size = scalar @numbers;
  my $target_size = 9;
  my @entries = ();
  foreach (0..$target_size-1) {
    $entries[$_] = @numbers[$_ % $target_size];
  }

  $size = scalar @entries;
  die "In square9_puzzle. Number of numbers should be $target_size, but is $size. \n" if($size != $target_size);

  my $n_randomize = 4*$size;
  foreach (1..$n_randomize) {
    foreach my $i (0..$size-1) {
      my $j = int (rand() * $size);
      if ($j != $i) {		# switch ith and jth elements
	my $tmp = $entries[$j];
	$entries[$j] = $entries[$i];
	$entries[$i] = $tmp;
      }
    }
  }

  my $std_line_width = 2;
  my $thick_line_width = 6;
  my $angle = pi/2;
  my $LLobj = LatticeLines->new({
				 'basis' => [[$scale, 0], 
					     [$scale*cos($angle), -1*$scale*sin($angle)]], 
				 'offset' => [1*$scale, (1 + 5)*$scale], 
				 'font-size' => int($scale/3.3),
				 'text-anchor' => 'middle', 
				 'line_options' => {'stroke-width' => $std_line_width}
				});

  my $clue_A = $entries[0] * $entries[4] * $entries[8]; # diag

  my $clue_B = $entries[0] * $entries[1] * $entries[2]; #rows
  my $clue_C = $entries[3] * $entries[4] * $entries[5];
  my $clue_D = $entries[6] * $entries[7] * $entries[8];

  my $clue_E = $entries[2] * $entries[4] * $entries[6]; #diag

  my $clue_F = $entries[0] * $entries[3] * $entries[6]; #cols
  my $clue_G = $entries[1] * $entries[4] * $entries[7];
  my $clue_H = $entries[2] * $entries[5] * $entries[8];

  $LLobj->add_text($clue_A, '-0.5,3.5');
  $LLobj->add_text($clue_B, '-0.5,2.5');

  $LLobj->add_text($clue_C, '-0.5,1.5');
  $LLobj->add_text($clue_D, '-0.5,0.5');

  $LLobj->add_text($clue_E, '-0.5,-0.5');
  $LLobj->add_text($clue_F, '0.5,-0.5');
 $LLobj->add_text($clue_G, '1.5,-0.5');
  $LLobj->add_text($clue_H, '2.5,-0.5');

  # add the lines for a 9-number square puzzle
  # to the LatticeLines object:

  $LLobj->add_line('-1,3,0,3'); # horizontals
  $LLobj->add_line('-1,2,3,2');
  $LLobj->add_line('-1,1,3,1');
$LLobj->add_line('-1,0,0,0');


  $LLobj->add_line('0,4,0,3'); # verticals
  $LLobj->add_line('0,0,0,-1');
  $LLobj->add_line('1,3,1,-1');
 $LLobj->add_line('2,3,2,-1');
$LLobj->add_line('3,0,3,-1');

  # $LLobj->add_line('-1,3,1,1');
  # $LLobj->add_line('-1,4,2,1');
  # $LLobj->add_line('-1,5,0,4');

  # these are the heavy lines outlining the area with the 9 numbers
  $LLobj->add_line('0,3,3,3', {'stroke-width' => $thick_line_width});
  $LLobj->add_line('0,0,3,0', {'stroke-width' => $thick_line_width});

  $LLobj->add_line('0,3,0,0', {'stroke-width' => $thick_line_width});
  $LLobj->add_line('3,3,3,0', {'stroke-width' => $thick_line_width});

  return $LLobj;
}

sub tri9_puzzle{
  my $numbers_string = shift || '1,1,1,2,2,3,3,5,7';
  my $scale = shift || 100;
  my @numbers = split(',', $numbers_string);
  my $size = scalar @numbers;
  my $target_size = 9;
  my @entries = ();
  foreach (0..$target_size-1) {
    $entries[$_] = @numbers[$_ % $target_size];
  }

  $size = scalar @entries;
  die "In tri9_puzzle. Number of numbers should be $target_size, but is $size. \n" if($size != $target_size);

  my $n_randomize = 4*$size;
  foreach (1..$n_randomize) {
    foreach my $i (0..$size-1) {
      my $j = int (rand() * $size);
      if ($j != $i) {		# switch ith and jth elements
	my $tmp = $entries[$j];
	$entries[$j] = $entries[$i];
	$entries[$i] = $tmp;
      }
    }
  }

  my $std_line_width = 2;
  my $thick_line_width = 6;
  my $angle = pi/3;
  my $LLobj = LatticeLines->new({
				 'basis' => [[$scale, 0], 
					     [$scale*cos($angle), -1*$scale*sin($angle)]], 
				 'offset' => [1*$scale, (1 + 5)*$scale], 
				 'font-size' => int($scale/3.3),
				 'text-anchor' => 'middle', 
				 'line_options' => {'stroke-width' => $std_line_width}
				});

  my $clue_A = $entries[0] * $entries[2] * $entries[3] * $entries[7] * $entries[8];
  my $clue_B = $entries[1] * $entries[5] * $entries[6];

  my $clue_C = $entries[0] * $entries[1] * $entries[2] * $entries[4] * $entries[5];
  my $clue_D = $entries[3] * $entries[6] * $entries[7];

  my $clue_E = $entries[4] * $entries[5] * $entries[6] * $entries[7] * $entries[8];
  my $clue_F = $entries[1] * $entries[2] * $entries[3];

  $LLobj->add_text($clue_A, '-0.5,4');
  $LLobj->add_text($clue_B, '-0.5,3');

  $LLobj->add_text($clue_C, '0.5,0.5');
  $LLobj->add_text($clue_D, '1.5,0.5');

  $LLobj->add_text($clue_E, '3,1.5');
  $LLobj->add_text($clue_F, '2,2.5');
  # add the lines for a 9-number triangular puzzle
  # to the LatticeLines object:

  $LLobj->add_line('0,0,0,1');
  $LLobj->add_line('1,0,1,3');
  $LLobj->add_line('2,0,2,2');

  $LLobj->add_line('3,1,4,1');
  $LLobj->add_line('0,2,3,2');
  $LLobj->add_line('0,3,2,3');

  $LLobj->add_line('-1,3,1,1');
  $LLobj->add_line('-1,4,2,1');
  $LLobj->add_line('-1,5,0,4');

  # these are the heavy lines outlining the area with the 9 numbers
  $LLobj->add_line('0,1,0,4', {'stroke-width' => $thick_line_width});
  $LLobj->add_line('0,1,3,1', {'stroke-width' => $thick_line_width});
  $LLobj->add_line('0,4,3,1', {'stroke-width' => $thick_line_width});

  return $LLobj;
}


