#!/usr/bin/perl -w
use strict;
use List::Util qw ' min max sum ';
use Math::Trig;

use lib '/home/tomfy/Non-Work/SvgPatternMaker/FactorSquarePuzzles';
use LatticeLines;
use Getopt::Std;

use vars qw($opt_p $opt_s $opt_w $opt_a $opt_o $opt_r $opt_c $opt_n $opt_f);

# -p <puzzle pattern. Options are  2x3 (default), 3x3, 2x4, 3x4, 3x8, 6x6, triangle,
# -s <scale. e.g. 50>
# -w <what to show? clues, answers, both, neither. (default is clues)>
# -a <show arrows? 0/1, default: 0>
# -o <orientation p: portrait l: landscape. default: p>
# -r <number of rows. Default: 1>
# -c <number of columns. Default: 1>
# -n <number of pages. Default: 1>
# -f <output filename. Default: print to STDOUT>
# typical usage: perl bootstrap_ortholog.pl -i $align_filename -T ML -k -n 1 -N 100 -S 12345 -r mindl -m 0.015 -q castorbean > outfile

# get options
getopts("p:s:w:a:o:r:c:n:f:");

# defaults:
my $type        = $opt_p || '2x3';
my $scale       = $opt_s || 54;
my $orientation = $opt_o || 'p';     # default is portrait
my $n_rows      = $opt_r || 1;
my $n_cols      = $opt_c || 1;
my $what_to_show = $opt_w
  || 'clues';    # by default show the clues but not the answers.
my $n_pages         = $opt_n || 1;
my $output_filename = $opt_f;
my $show_clues      = 1;
my $show_answers    = 0;

my $show_arrows = ( defined $opt_a and uc $opt_a eq 'N' ) ? 0 : 1;
if ( $what_to_show eq 'answers' ) {
    $show_clues   = 0;
    $show_answers = 1;
}
elsif ( $what_to_show eq 'both' ) {
    $show_clues   = 1;
    $show_answers = 1;
}
elsif ( $what_to_show eq 'clues' ) {
    $show_clues   = 1;
    $show_answers = 0;
}
elsif ( $what_to_show = 'neither' ) {
    $show_clues   = 0;
    $show_answers = 0;
}
else {
    warn '$what_to_show has invalid value: ', $what_to_show,
"; using default value 'clues'. Valid values are 'clues', 'answers', 'both' \n";
}
my ( $width, $height ) =
  ( $orientation eq 'l' ) ? ( 990, 765 ) : ( 765, 990 );    # letter size
my $svg_top_stuff =
'<?xml version="1.0" standalone="no"?> <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">'
  . "\n";
$svg_top_stuff .=
    '<svg width="' 
  . $width
  . '" height="'
  . $height
  . '" version="1.1" xmlns="http://www.w3.org/2000/svg">' . "\n";
my $svg_bottom_stuff    = '</svg>' . "\n";
my $page_separator_line = '<!-- PAGE SEPARATOR -->' . "\n";

# now put together the svg string:

my ($svg_string, $svg_solutions_string) = ('', '');

#my $n_pages = 2;
for my $i_page ( 1 .. $n_pages ) {
    $svg_string           .= $svg_top_stuff;
    $svg_solutions_string .= $svg_top_stuff;

    my ( $puzzle_page_svg, $puzzle_solution_page_svg ) =
      multi_puzzles( $type, $width, $height, $n_rows, $n_cols );
    $svg_string           .= $puzzle_page_svg;
    $svg_solutions_string .= $puzzle_solution_page_svg;

    # end of svg:
    $svg_string           .= $svg_bottom_stuff;
    $svg_solutions_string .= $svg_bottom_stuff;

    # page separator
    if ( $i_page < $n_pages ) {
        $svg_string           .= $page_separator_line;
        $svg_solutions_string .= $page_separator_line;
    }
}
if ( defined $output_filename ) {
  my $solutions_filename = $output_filename . '_solutions.svg';
$output_filename .= '.svg';
    open my $fhout, ">$output_filename";
    print $fhout $svg_string;
    close $fhout;
 
    open $fhout, ">$solutions_filename";
    print $fhout $svg_solutions_string;
    close $fhout;
}
else {
    print $svg_string;
    open my $fhout, ">solutions.svg";
    print $fhout $svg_solutions_string;
    close $fhout;
}

# end of main.

sub multi_puzzles {
    my $type                 = shift || '2x3';
    my $printing_area_width  = shift;
    my $printing_area_height = shift;
    my $n_rows               = shift;
    my $n_cols               = shift;
    my $margin               = shift || 50;
    $printing_area_width  -= 2 * $margin;
    $printing_area_height -= 2 * $margin;

    #   my $sum_of_gaps = 0.5*min($printing_area_width, $printing_area_height);
    my $h_gap_size = 0.3 * $printing_area_width / $n_cols;
    my $v_gap_size = 0.3 * $printing_area_height / $n_rows;
    my $max_puzzle_width =
      ( $printing_area_width - $n_cols * $h_gap_size ) / $n_cols;
    my $max_puzzle_height =
      ( $printing_area_height - $n_rows * $v_gap_size ) / $n_rows;

    my ($svg_string, $svg_solutions_string) = ('', '');

    #  $svg_string .= "<line \n" . "x1=\"0\" y1=\"0\" " .
    #      "x2=\"$printing_area_width\" y2=\"$printing_area_height\" " .
    #      "style=\"stroke:rgb(255,0,0);stroke-width:2\"/> \n";

    for my $row ( 0 .. $n_rows - 1 ) {
        for my $col ( 0 .. $n_cols - 1 ) {

            #	$show_clues = ! $show_clues;
            # $show_answers = ! $show_answers;
            my $x_off =
              0.5 * $h_gap_size +
              $col * ( $max_puzzle_width + $h_gap_size ) +
              $margin;
            my $y_off =
              0.5 * $v_gap_size +
              $row * ( $max_puzzle_height + $v_gap_size ) +
              $margin;
            my $puzzle_obj;
            if ( $type eq '2x3' ) {
                $puzzle_obj = rectangle2x3_puzzle('1,2,3,5,7,11');
            }
            elsif ( $type eq '2x4' ) {
                $puzzle_obj = rectangle2x4_puzzle('1,2,3,5,7,11,2,3');
            }
            elsif ( $type eq '3x4' ) {
                $puzzle_obj = rectangle3x4_puzzle();
            }
            elsif ( $type eq '3x8' ) {
                $puzzle_obj = rectangle3x8_puzzle('1,1,1,1,1, 2,2,2,2,2,2, 3,3,3,3,3, 5,5,5,5, 7,7, 11, 13');
            }
            elsif ( $type eq '3x3' ) {
                $puzzle_obj = square3x3_puzzle('2,3,5,1,2,3,5');
            }
            elsif ( $type eq '6x6' ) {
                $puzzle_obj =
                  square6x6_puzzle('1,2,3,5,7,11, 1,2,3,5, 1,2,3,5,7,11,13');
            }
            else {
                $puzzle_obj = triangle9_puzzle('1,1,2,2,2,3,3,5,7');
            }
            my ( $min_x, $min_y, $max_x, $max_y ) = $puzzle_obj->min_max_x_y();
            my ( $w, $h ) = ( $max_x - $min_x, $max_y - $min_y );
            my $scale = min( $max_puzzle_width / $w, $max_puzzle_height / $h );

# svg body:
#	print "w, h, scale : $w, $h, $scale, max puzzle width, height: $max_puzzle_width, $max_puzzle_height.\n";
            $svg_string .= $puzzle_obj->svg_string(
                [
                    $x_off + 0.5 * ( $max_puzzle_width - $scale * $w ),
                    $y_off + 0.5 * ( $max_puzzle_height - $scale * $h )
                ],
                $scale,
                {
                    show_clues   => $show_clues,
                    show_answers => $show_answers,
                    show_arrows  => $show_arrows
                }
            );
            $svg_solutions_string .= $puzzle_obj->svg_string(
                [
                    $x_off + 0.5 * ( $max_puzzle_width - $scale * $w ),
                    $y_off + 0.5 * ( $max_puzzle_height - $scale * $h )
                ],
                $scale,
                {
                    show_clues   => 1,
                    show_answers => 1,
                    show_arrows  => $show_arrows
                }
            );
        }
    }
    return ( $svg_string, $svg_solutions_string );
}    # end of multi_puzzles

sub rectangle2x3_puzzle {

    #   my $scale          = shift || 100;
    my $numbers_string = shift || '1,2,3,5,7,11';

    my $target_size = 6;
    my @entries = @{ randomize_numbers( $numbers_string, $target_size ) };

    my $std_line_width   = 0.02;                # 2 * $scale / 100;
    my $thick_line_width = 0.06;                # 6 * $scale / 100;
    my $angle            = pi / 2;
    my $LLobj            = LatticeLines->new(
        {
            'basis' => [ [ 1, 0 ], [ 1 * cos($angle), -1 * 1 * sin($angle) ] ],

            #         'font-size'    => 0.4,
            'text-anchor'  => 'middle',
            'line_options' => { 'stroke-width' => $std_line_width },
            'show_arrows'  => 1,
        }
    );

    # column clues
    my $clue_A = $entries[0] * $entries[3];
    my $clue_B = $entries[1] * $entries[4];
    my $clue_C = $entries[2] * $entries[5];

    # diagonal clues
    my $clue_D = $entries[3] * $entries[1];
    my $clue_E = $entries[4] * $entries[2];

    # other diagonal clues
    my $clue_F = $entries[4] * $entries[0];
    my $clue_G = $entries[5] * $entries[1];

    $LLobj->add_clue_text( $clue_A, '0.5,2.4' );
    $LLobj->add_clue_text( $clue_B, '1.5,2.4' );
    $LLobj->add_clue_text( $clue_C, '2.5,2.4' );

    $LLobj->add_clue_text( $clue_D, '-0.5,-0.6' );
    $LLobj->add_clue_text( $clue_E, '0.5,-0.6' );

    $LLobj->add_clue_text( $clue_F, '2.5,-0.6' );
    $LLobj->add_clue_text( $clue_G, '3.5,-0.6' );

    $LLobj->add_answer_text( $entries[0], '0.5,1.4' );
    $LLobj->add_answer_text( $entries[1], '1.5,1.4' );
    $LLobj->add_answer_text( $entries[2], '2.5,1.4' );

    $LLobj->add_answer_text( $entries[3], '0.5,0.4' );
    $LLobj->add_answer_text( $entries[4], '1.5,0.4' );
    $LLobj->add_answer_text( $entries[5], '2.5,0.4' );

    # add the lines for a 2x3 rectangular puzzle
    # to the LatticeLines object:
    $LLobj->add_line('-1,-1,1,-1');    # horizontals
    $LLobj->add_line('2,-1,4,-1');
    $LLobj->add_line('0,1,3,1');
    $LLobj->add_line('-1,0,0,0');
    $LLobj->add_line('3,0,4,0');
    $LLobj->add_line('0,3,3,3');

    $LLobj->add_line('-1,-1,-1,0');    # verticals
    $LLobj->add_line('0,-1,0,0');
    $LLobj->add_line('0,2,0,3');
    $LLobj->add_line('1,-1,1,3');
    $LLobj->add_line('2,-1,2,3');
    $LLobj->add_line('3,-1,3,0');
    $LLobj->add_line('3,2,3,3');
    $LLobj->add_line('4,-1,4,0');

    # these are the heavy lines outlining the area with the 6 answer numbers
    $LLobj->add_line( '0,0,0,2', { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( '0,0,3,0', { 'stroke-width' => $thick_line_width } );

    $LLobj->add_line( '0,2,3,2', { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( '3,0,3,2', { 'stroke-width' => $thick_line_width } );

    $LLobj->add_arrow('0.5,2.5,0.5,2');
    $LLobj->add_arrow('1.5,2.5,1.5,2');
    $LLobj->add_arrow('2.5,2.5,2.5,2');

    $LLobj->add_arrow('-0.5,-0.5,0.0,0');
    $LLobj->add_arrow('0.5,-0.5,1.0,0');
    $LLobj->add_arrow('2.5,-0.5,2.0,0');
    $LLobj->add_arrow('3.5,-0.5,3.0,0');

    return $LLobj;
}

sub rectangle2x4_puzzle {

    #   my $scale          = shift || 100;
    #   my $offset_x       = shift || 0.5;
    #   my $offset_y       = shift || 0.5;
    my $numbers_string = shift || '1,2,3,5,7,11,2,3';

    my $target_size = 8;
    my @entries = @{ randomize_numbers( $numbers_string, $target_size ) };

    my $std_line_width   = 0.02;                # 2 * $scale / 100;
    my $thick_line_width = 0.06;                #  * $scale / 100;
    my $angle            = pi / 2;
    my $LLobj            = LatticeLines->new(
        {
            'basis' => [ [ 1, 0 ], [ 1 * cos($angle), -1 * 1 * sin($angle) ] ],

            #          'offset' => [ $offset_x * $scale, $offset_y * $scale ],
            # 'margin' => [1*$scale, 1*$scale],
            #  'font-size'    => int( $scale / 3.3 ),
            'text-anchor'  => 'middle',
            'line_options' => { 'stroke-width' => $std_line_width },
            'show_arrows'  => 1,
        }
    );

    # column clues
    my $clue_A = $entries[0] * $entries[4];
    my $clue_B = $entries[1] * $entries[5];
    my $clue_C = $entries[2] * $entries[6];
    my $clue_D = $entries[3] * $entries[7];

    # diagonal clues
    my $clue_E = $entries[4] * $entries[1];
    my $clue_F = $entries[5] * $entries[2];
    my $clue_G = $entries[6] * $entries[3];

    # other diagonal clues
    my $clue_H = $entries[5] * $entries[0];
    my $clue_I = $entries[6] * $entries[1];
    my $clue_J = $entries[7] * $entries[2];

    $LLobj->add_clue_text( $clue_A, '0.5,2.45' );
    $LLobj->add_clue_text( $clue_B, '1.5,2.45' );
    $LLobj->add_clue_text( $clue_C, '2.5,2.45' );
    $LLobj->add_clue_text( $clue_D, '3.5,2.45' );

    $LLobj->add_clue_text( $clue_E, '-0.5,-0.6' );
    $LLobj->add_clue_text( $clue_F, '0.5,-0.6' );
    $LLobj->add_clue_text( $clue_G, '1.5,-0.6' );

    $LLobj->add_clue_text( $clue_H, '2.5,-0.6' );
    $LLobj->add_clue_text( $clue_I, '3.5,-0.6' );
    $LLobj->add_clue_text( $clue_J, '4.5,-0.6' );

    $LLobj->add_answer_text( $entries[0], '0.5,1.4' );
    $LLobj->add_answer_text( $entries[1], '1.5,1.4' );
    $LLobj->add_answer_text( $entries[2], '2.5,1.4' );
    $LLobj->add_answer_text( $entries[3], '3.5,1.4' );

    $LLobj->add_answer_text( $entries[4], '0.5,0.4' );
    $LLobj->add_answer_text( $entries[5], '1.5,0.4' );
    $LLobj->add_answer_text( $entries[6], '2.5,0.4' );
    $LLobj->add_answer_text( $entries[7], '3.5,0.4' );

    # add the lines for a 2x3 rectangular puzzle
    # to the LatticeLines object:

    $LLobj->add_line('-1,-1,5,-1');    # horizontals
    $LLobj->add_line('-1,0,5,0');
    $LLobj->add_line('0,1,4,1');
    $LLobj->add_line('3,2,4,2');
    $LLobj->add_line('0,3,4,3');

    $LLobj->add_line('-1,-1,-1,0');    # verticals
    $LLobj->add_line('0,-1,0,0');
    $LLobj->add_line('0,2,0,3');
    $LLobj->add_line('1,-1,1,3');
    $LLobj->add_line('2,-1,2,3');
    $LLobj->add_line('3,-1,3,3');
    $LLobj->add_line('4,-1,4,0');
    $LLobj->add_line('4,2,4,3');

    $LLobj->add_line('5,-1,5,0');

    # these are the heavy lines outlining the area with the 6 answer numbers
    $LLobj->add_line( '0,0,0,2', { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( '0,0,4,0', { 'stroke-width' => $thick_line_width } );

    $LLobj->add_line( '0,2,4,2', { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( '4,0,4,2', { 'stroke-width' => $thick_line_width } );

    $LLobj->add_arrow('0.5,2.5,0.5,2');
    $LLobj->add_arrow('1.5,2.5,1.5,2');
    $LLobj->add_arrow('2.5,2.5,2.5,2');
    $LLobj->add_arrow('3.5,2.5,3.5,2');

    $LLobj->add_arrow('-0.5,-0.5,0.0,0');
    $LLobj->add_arrow('0.5,-0.5,1.0,0');
    $LLobj->add_arrow('1.5,-0.5,2.0,0');

    $LLobj->add_arrow('2.5,-0.5,2.0,0');
    $LLobj->add_arrow('3.5,-0.5,3.0,0');
    $LLobj->add_arrow('4.5,-0.5,4.0,0');

    return $LLobj;
}

sub rectangle3x4_puzzle {

    #   my $scale          = shift || 100;
    #   my $offset_x       = shift || 0.5;
    #   my $offset_y       = shift || 0.5;
    my $numbers_string = shift || '1,1,2,2,3,3, 5,5,7,7,11,2';

    my $target_size = 12;    # the number of answer numbers to be filled in.
    my @entries = @{ randomize_numbers( $numbers_string, $target_size ) };

    my $std_line_width   = 0.02;                # * $scale / 100;
    my $thick_line_width = 0.06;                # * $scale / 100;
    my $angle            = pi / 2;
    my $LLobj            = LatticeLines->new(
        {
            'basis' => [ [ 1, 0 ], [ 1 * cos($angle), -1 * 1 * sin($angle) ] ],

            #        'offset' => [ $offset_x * $scale, $offset_y * $scale ],
            # 'margin' => [1*$scale, 1*$scale],
            #           'font-size'    => int( $scale / 3.3 ),
            'text-anchor'  => 'middle',
            'line_options' => { 'stroke-width' => $std_line_width },
            'show_arrows'  => 1,
        }
    );

    # column clues
    my $clue_A = $entries[0] * $entries[4] * $entries[8];
    my $clue_B = $entries[1] * $entries[5] * $entries[9];
    my $clue_C = $entries[2] * $entries[6] * $entries[10];
    my $clue_D = $entries[3] * $entries[7] * $entries[11];

    # diagonal clues (NE pointing)
    my $clue_E = $entries[4] * $entries[1];
    my $clue_F = $entries[8] * $entries[5] * $entries[2];
    my $clue_G = $entries[9] * $entries[6] * $entries[3];
    my $clue_H = $entries[10] * $entries[7];

    # other diagonal clues (NW pointing)
    my $clue_I = $entries[4] * $entries[9];
    my $clue_J = $entries[0] * $entries[5] * $entries[10];
    my $clue_K = $entries[1] * $entries[6] * $entries[11];
    my $clue_L = $entries[2] * $entries[7];

    $LLobj->add_clue_text( $clue_A, '0.5,3.45' );
    $LLobj->add_clue_text( $clue_B, '1.5,3.45' );
    $LLobj->add_clue_text( $clue_C, '2.5,3.45' );
    $LLobj->add_clue_text( $clue_D, '3.5,3.45' );

    $LLobj->add_clue_text( $clue_E, '-0.5,0.4' );
    $LLobj->add_clue_text( $clue_F, '-0.5,-0.6' );
    $LLobj->add_clue_text( $clue_G, '0.5,-0.6' );
    $LLobj->add_clue_text( $clue_H, '1.5,-0.6' );

    $LLobj->add_clue_text( $clue_I, '2.5,-0.6' );
    $LLobj->add_clue_text( $clue_J, '3.5,-0.6' );
    $LLobj->add_clue_text( $clue_K, '4.5,-0.6' );
    $LLobj->add_clue_text( $clue_L, '4.5,0.4' );

    $LLobj->add_answer_text( $entries[0], '0.5,2.4' );
    $LLobj->add_answer_text( $entries[1], '1.5,2.4' );
    $LLobj->add_answer_text( $entries[2], '2.5,2.4' );
    $LLobj->add_answer_text( $entries[3], '3.5,2.4' );

    $LLobj->add_answer_text( $entries[4], '0.5,1.4' );
    $LLobj->add_answer_text( $entries[5], '1.5,1.4' );
    $LLobj->add_answer_text( $entries[6], '2.5,1.4' );
    $LLobj->add_answer_text( $entries[7], '3.5,1.4' );

    $LLobj->add_answer_text( $entries[8],  '0.5,0.4' );
    $LLobj->add_answer_text( $entries[9],  '1.5,0.4' );
    $LLobj->add_answer_text( $entries[10], '2.5,0.4' );
    $LLobj->add_answer_text( $entries[11], '3.5,0.4' );

    # add the lines for a 2x3 rectangular puzzle
    # to the LatticeLines object:
    $LLobj->add_line('-1,-1,5,-1');    # horizontals
    $LLobj->add_line('-1,0,5,0');
    $LLobj->add_line('-1,1,5,1');
    $LLobj->add_line('0,2,4,2');
    $LLobj->add_line('0,3,4,3');
    $LLobj->add_line('0,4,4,4');

    $LLobj->add_line('-1,-1,-1,1');    # verticals
    $LLobj->add_line('0,-1,0,0');
    $LLobj->add_line('0,3,0,4');
    $LLobj->add_line('1,-1,1,4');
    $LLobj->add_line('2,-1,2,4');
    $LLobj->add_line('3,-1,3,4');
    $LLobj->add_line('4,-1,4,0');
    $LLobj->add_line('4,3,4,4');

    $LLobj->add_line('5,-1,5,1');

    # these are the heavy lines outlining the area with the 6 answer numbers
    $LLobj->add_line( '0,0,0,3', { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( '0,0,4,0', { 'stroke-width' => $thick_line_width } );

    $LLobj->add_line( '0,3,4,3', { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( '4,0,4,3', { 'stroke-width' => $thick_line_width } );

    # Downward arrows
    $LLobj->add_arrow('0.5,3.5,0.5,3');
    $LLobj->add_arrow('1.5,3.5,1.5,3');
    $LLobj->add_arrow('2.5,3.5,2.5,3');
    $LLobj->add_arrow('3.5,3.5,3.5,3');

    # NE diagonal arrows
    $LLobj->add_arrow('-0.5,0.5,0.0,1');
    $LLobj->add_arrow('-0.5,-0.5,0.0,0');
    $LLobj->add_arrow('0.5,-0.5,1.0,0');
    $LLobj->add_arrow('1.5,-0.5,2.0,0');

    # NW diagonal arrows
    $LLobj->add_arrow('2.5,-0.5,2.0,0');
    $LLobj->add_arrow('3.5,-0.5,3.0,0');
    $LLobj->add_arrow('4.5,-0.5,4.0,0');
    $LLobj->add_arrow('4.5,0.5,4.0,1');

    return $LLobj;
}    # end of sub rectangle3x4_puzzle

sub rectangle3x8_puzzle {

    #   my $scale          = shift || 100;
    #   my $offset_x       = shift || 0.5;
    #   my $offset_y       = shift || 0.5;
    my $numbers_string = shift || '1,1,2,2,3,3, 5,5,7,7,11,2';

    my $target_size = 24;    # the number of answer numbers to be filled in.
    my @entries = @{ randomize_numbers( $numbers_string, $target_size ) };

    my $std_line_width   = 0.02;                # * $scale / 100;
    my $thick_line_width = 0.06;                # * $scale / 100;
    my $angle            = pi / 2;
    my $LLobj            = LatticeLines->new(
        {
            'basis' => [ [ 1, 0 ], [ 1 * cos($angle), -1 * 1 * sin($angle) ] ],

            #        'offset' => [ $offset_x * $scale, $offset_y * $scale ],
            # 'margin' => [1*$scale, 1*$scale],
            #           'font-size'    => int( $scale / 3.3 ),
            'text-anchor'  => 'middle',
            'line_options' => { 'stroke-width' => $std_line_width },
            'show_arrows'  => 1,
        }
    );

    # column clues
    my $clue_A = $entries[0] * $entries[8] * $entries[16];
    my $clue_B = $entries[1] * $entries[9] * $entries[17];
    my $clue_C = $entries[2] * $entries[10] * $entries[18];
    my $clue_D = $entries[3] * $entries[11] * $entries[19];
    my $clue_E = $entries[4] * $entries[12] * $entries[20];
    my $clue_F = $entries[5] * $entries[13] * $entries[21];
    my $clue_G = $entries[6] * $entries[14] * $entries[22];
    my $clue_H = $entries[7] * $entries[15] * $entries[23];

    # diagonal clues (NE pointing)
    my $clue_I = $entries[8] * $entries[1];
    my $clue_J = $entries[16] * $entries[9] * $entries[2];
    my $clue_K = $entries[17] * $entries[10] * $entries[3];
    my $clue_L = $entries[18] * $entries[11] * $entries[4];
    my $clue_M = $entries[19] * $entries[12] * $entries[5];
    my $clue_N = $entries[20] * $entries[13] * $entries[6];

    # other diagonal clues (NW pointing)
    my $clue_T = $entries[15] * $entries[6];
    my $clue_S = $entries[23] * $entries[14] * $entries[5];
    my $clue_R = $entries[22] * $entries[13] * $entries[4];
    my $clue_Q = $entries[21] * $entries[12] * $entries[3];
    my $clue_P = $entries[20] * $entries[11] * $entries[2];
    my $clue_O = $entries[19] * $entries[10] * $entries[1];

    $LLobj->add_clue_text( $clue_A, '0.5,3.45' );
    $LLobj->add_clue_text( $clue_B, '1.5,3.45' );
    $LLobj->add_clue_text( $clue_C, '2.5,3.45' );
    $LLobj->add_clue_text( $clue_D, '3.5,3.45' );
    $LLobj->add_clue_text( $clue_E, '4.5,3.45' );
    $LLobj->add_clue_text( $clue_F, '5.5,3.45' );
    $LLobj->add_clue_text( $clue_G, '6.5,3.45' );
    $LLobj->add_clue_text( $clue_H, '7.5,3.45' );

    $LLobj->add_clue_text( $clue_I, '-0.5,0.4' );
    $LLobj->add_clue_text( $clue_J, '-0.5,-0.6' );
    $LLobj->add_clue_text( $clue_K, '0.5,-0.6' );
    $LLobj->add_clue_text( $clue_L, '1.5,-0.6' );
    $LLobj->add_clue_text( $clue_M, '2.5,-0.6' );
    $LLobj->add_clue_text( $clue_N, '3.5,-0.6' );

    $LLobj->add_clue_text( $clue_O, '4.5,-0.6' );
    $LLobj->add_clue_text( $clue_P, '5.5,-0.6' );
    $LLobj->add_clue_text( $clue_Q, '6.5,-0.6' );
    $LLobj->add_clue_text( $clue_R, '7.5,-0.6' );
    $LLobj->add_clue_text( $clue_S, '8.5,-0.6' );
    $LLobj->add_clue_text( $clue_T, '8.5,0.4' );

    $LLobj->add_answer_text( $entries[0], '0.5,2.4' );
    $LLobj->add_answer_text( $entries[1], '1.5,2.4' );
    $LLobj->add_answer_text( $entries[2], '2.5,2.4' );
    $LLobj->add_answer_text( $entries[3], '3.5,2.4' );
    $LLobj->add_answer_text( $entries[4], '4.5,2.4' );
    $LLobj->add_answer_text( $entries[5], '5.5,2.4' );
    $LLobj->add_answer_text( $entries[6], '6.5,2.4' );
    $LLobj->add_answer_text( $entries[7], '7.5,2.4' );

    $LLobj->add_answer_text( $entries[8],  '0.5,1.4' );
    $LLobj->add_answer_text( $entries[9],  '1.5,1.4' );
    $LLobj->add_answer_text( $entries[10], '2.5,1.4' );
    $LLobj->add_answer_text( $entries[11], '3.5,1.4' );
    $LLobj->add_answer_text( $entries[12], '4.5,1.4' );
    $LLobj->add_answer_text( $entries[13], '5.5,1.4' );
    $LLobj->add_answer_text( $entries[14], '6.5,1.4' );
    $LLobj->add_answer_text( $entries[15], '7.5,1.4' );

    $LLobj->add_answer_text( $entries[16], '0.5,0.4' );
    $LLobj->add_answer_text( $entries[17], '1.5,0.4' );
    $LLobj->add_answer_text( $entries[18], '2.5,0.4' );
    $LLobj->add_answer_text( $entries[19], '3.5,0.4' );
    $LLobj->add_answer_text( $entries[20], '4.5,0.4' );
    $LLobj->add_answer_text( $entries[21], '5.5,0.4' );
    $LLobj->add_answer_text( $entries[22], '6.5,0.4' );
    $LLobj->add_answer_text( $entries[23], '7.5,0.4' );

    # add the lines for a 3x8 rectangular puzzle
    # to the LatticeLines object:
    $LLobj->add_line('-1,-1,9,-1');    # horizontals
    $LLobj->add_line('-1,0,9,0');
    $LLobj->add_line('-1,1,9,1');
    $LLobj->add_line('0,2,8,2');
    $LLobj->add_line('0,3,8,3');
    $LLobj->add_line('0,4,8,4');

    $LLobj->add_line('-1,-1,-1,1');    # verticals

    $LLobj->add_line('0,-1,0,0');
    $LLobj->add_line('0,3,0,4');

    $LLobj->add_line('1,-1,1,4');
    $LLobj->add_line('2,-1,2,4');
    $LLobj->add_line('3,-1,3,4');
    $LLobj->add_line('4,-1,4,4');
    $LLobj->add_line('5,-1,5,4');
    $LLobj->add_line('6,-1,6,4');
    $LLobj->add_line('7,-1,7,4');

    $LLobj->add_line('8,-1,8,0');
    $LLobj->add_line('8,3,8,4');

    $LLobj->add_line('9,-1,9,1');

    # these are the heavy lines outlining the area with the 6 answer numbers
    $LLobj->add_line( '0,0,0,3', { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( '0,0,8,0', { 'stroke-width' => $thick_line_width } );

    $LLobj->add_line( '0,3,8,3', { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( '8,0,8,3', { 'stroke-width' => $thick_line_width } );

    # Downward arrows
    $LLobj->add_arrow('0.5,3.5,0.5,3');
    $LLobj->add_arrow('1.5,3.5,1.5,3');
    $LLobj->add_arrow('2.5,3.5,2.5,3');
    $LLobj->add_arrow('3.5,3.5,3.5,3');
    $LLobj->add_arrow('4.5,3.5,4.5,3');
    $LLobj->add_arrow('5.5,3.5,5.5,3');
    $LLobj->add_arrow('6.5,3.5,6.5,3');
    $LLobj->add_arrow('7.5,3.5,7.5,3');

    # NE diagonal arrows
    $LLobj->add_arrow('-0.5,0.5,0.0,1');
    $LLobj->add_arrow('-0.5,-0.5,0.0,0');
    $LLobj->add_arrow('0.5,-0.5,1.0,0');
    $LLobj->add_arrow('1.5,-0.5,2.0,0');
    $LLobj->add_arrow('2.5,-0.5,3.0,0');
    $LLobj->add_arrow('3.5,-0.5,4.0,0');

    # NW diagonal arrows
    $LLobj->add_arrow('4.5,-0.5,4.0,0');
    $LLobj->add_arrow('5.5,-0.5,5.0,0');
    $LLobj->add_arrow('6.5,-0.5,6.0,0');
    $LLobj->add_arrow('7.5,-0.5,7.0,0');
    $LLobj->add_arrow('8.5,-0.5,8.0,0');
    $LLobj->add_arrow('8.5,0.5,8.0,1');

    return $LLobj;
}

sub square6x6_puzzle {

    #    my $scale          = shift || 100;
    #  my $offset_x       = shift || 0.5;
    #  my $offset_y       = shift || 0.5;
    my $numbers_string = shift || '1,1,2,3,5,7';
    my $target_size = 28;
    my @entries = @{ randomize_numbers( $numbers_string, $target_size ) };

    my $std_line_width   = 0.02;                # * $scale / 100;
    my $thick_line_width = 0.075;               # * $scale / 100;
    my $angle            = pi / 2;
    my $LLobj            = LatticeLines->new(
        {
            'basis' => [ [ 1, 0 ], [ 1 * cos($angle), -1 * 1 * sin($angle) ] ],

            #      'offset' => [ $offset_x * $scale, $offset_y * $scale ],
            # 'margin' => [1*$scale, 1*$scale],
            #          'font-size'    => int( $scale / 3.3 ),
            'text-anchor'  => 'middle',
            'line_options' => { 'stroke-width' => $std_line_width },
            'show_arrows'  => 1
        }
    );

    # top edge clues:
    my $clue_T1 = $entries[1] * $entries[7] * $entries[12];
    my $clue_T2 = $entries[1] * $entries[6];
    my $clue_T3 = $entries[2] * $entries[8];
    my $clue_T4 = $entries[3] * $entries[9];
    my $clue_T5 = $entries[3] * $entries[8] * $entries[13];
    my $clue_T6 = $entries[4] * $entries[9];

    # right edge clues:
    my $clue_R1 = $entries[9] * $entries[13] * $entries[16];
    my $clue_R2 = $entries[8] * $entries[9];
    my $clue_R3 = $entries[17] * $entries[21];
    my $clue_R4 = $entries[22] * $entries[26];
    my $clue_R5 = $entries[20] * $entries[21] * $entries[22];
    my $clue_R6 = $entries[26] * $entries[27];

    # bottom edge clues:
    my $clue_B1 = $entries[15] * $entries[20] * $entries[26];
    my $clue_B2 = $entries[21] * $entries[26];
    my $clue_B3 = $entries[19] * $entries[25];
    my $clue_B4 = $entries[18] * $entries[24];
    my $clue_B5 = $entries[14] * $entries[19] * $entries[24];
    my $clue_B6 = $entries[18] * $entries[23];

    # left edge clues:
    my $clue_L1 = $entries[11] * $entries[14] * $entries[18];
    my $clue_L2 = $entries[18] * $entries[19];
    my $clue_L3 = $entries[6] * $entries[10];
    my $clue_L4 = $entries[1] * $entries[5];
    my $clue_L5 = $entries[5] * $entries[6] * $entries[7];
    my $clue_L6 = $entries[0] * $entries[1];

    # interior clues: (clockwise from top left)
    my $clue_I1 = $entries[2] * $entries[3] * $entries[4];
    my $clue_I2 = $entries[12] * $entries[16] * $entries[20];
    my $clue_I3 = $entries[17] * $entries[22] * $entries[27];
    my $clue_I4 = $entries[14] * $entries[15] * $entries[16];
    my $clue_I5 = $entries[23] * $entries[24] * $entries[25];
    my $clue_I6 = $entries[7] * $entries[11] * $entries[15];
    my $clue_I7 = $entries[0] * $entries[5] * $entries[10];
    my $clue_I8 = $entries[11] * $entries[12] * $entries[13];

    #    my $x_pos_in_box = 0.5;
    #    my $y_pos_in_box = 0.5;
    my $answer_dy = -0.1;
    my ( $clue_dy_top, $clue_dx_right, $clue_dy_bottom, $clue_dx_left ) =
      ( -0.05, 0.1, -0.15, -0.1 );
    my $clue_dx = 0.1;
    my $clue_dy = -0.1;
    $LLobj->add_clue_text( $clue_T1, [ 0.5, 6.5 + $clue_dy_top ] );
    $LLobj->add_clue_text( $clue_T2, [ 1.5, 6.5 + $clue_dy_top ] );
    $LLobj->add_clue_text( $clue_T3, [ 2.5, 6.5 + $clue_dy_top ] );
    $LLobj->add_clue_text( $clue_T4, [ 3.5, 6.5 + $clue_dy_top ] );
    $LLobj->add_clue_text( $clue_T5, [ 4.5, 6.5 + $clue_dy_top ] );
    $LLobj->add_clue_text( $clue_T6, [ 5.5, 6.5 + $clue_dy_top ] );

    $LLobj->add_clue_text( $clue_R1, [ 6.5 + $clue_dx_right, 5.5 + $clue_dy ] );
    $LLobj->add_clue_text( $clue_R2, [ 6.5 + $clue_dx_right, 4.5 + $clue_dy ] );
    $LLobj->add_clue_text( $clue_R3, [ 6.5 + $clue_dx_right, 3.5 + $clue_dy ] );
    $LLobj->add_clue_text( $clue_R4, [ 6.5 + $clue_dx_right, 2.5 + $clue_dy ] );
    $LLobj->add_clue_text( $clue_R5, [ 6.5 + $clue_dx_right, 1.5 + $clue_dy ] );
    $LLobj->add_clue_text( $clue_R6, [ 6.5 + $clue_dx_right, 0.5 + $clue_dy ] );

    $LLobj->add_clue_text( $clue_B1, [ 5.5, -0.5 + $clue_dy_bottom ] );
    $LLobj->add_clue_text( $clue_B2, [ 4.5, -0.5 + $clue_dy_bottom ] );
    $LLobj->add_clue_text( $clue_B3, [ 3.5, -0.5 + $clue_dy_bottom ] );
    $LLobj->add_clue_text( $clue_B4, [ 2.5, -0.5 + $clue_dy_bottom ] );
    $LLobj->add_clue_text( $clue_B5, [ 1.5, -0.5 + $clue_dy_bottom ] );
    $LLobj->add_clue_text( $clue_B6, [ 0.5, -0.5 + $clue_dy_bottom ] );

    $LLobj->add_clue_text( $clue_L1, [ -0.5 + $clue_dx_left, 0.5 + $clue_dy ] );
    $LLobj->add_clue_text( $clue_L2, [ -0.5 + $clue_dx_left, 1.5 + $clue_dy ] );
    $LLobj->add_clue_text( $clue_L3, [ -0.5 + $clue_dx_left, 2.5 + $clue_dy ] );
    $LLobj->add_clue_text( $clue_L4, [ -0.5 + $clue_dx_left, 3.5 + $clue_dy ] );
    $LLobj->add_clue_text( $clue_L5, [ -0.5 + $clue_dx_left, 4.5 + $clue_dy ] );
    $LLobj->add_clue_text( $clue_L6, [ -0.5 + $clue_dx_left, 5.5 + $clue_dy ] );

    # interior clues
    #top
    $LLobj->add_clue_text( $clue_I1, [ 2.5 + $clue_dx_left, 5.5 + $clue_dy ] );
    $LLobj->add_clue_text( $clue_I2, [ 3.5, 4.5 + $clue_dy_top ] );

    #right
    $LLobj->add_clue_text( $clue_I3, [ 5.5, 3.5 + $clue_dy_top ] );
    $LLobj->add_clue_text( $clue_I4, [ 4.5 + $clue_dx_right, 2.5 + $clue_dy ] );

    #bottom
    $LLobj->add_clue_text( $clue_I5, [ 3.5 + $clue_dx_right, 0.5 + $clue_dy ] );
    $LLobj->add_clue_text( $clue_I6, [ 2.5, 1.5 + $clue_dy_bottom ] );

    #left
    $LLobj->add_clue_text( $clue_I7, [ 0.5, 2.5 + $clue_dy_bottom ] );
    $LLobj->add_clue_text( $clue_I8, [ 1.5 + $clue_dx_left, 3.5 + $clue_dy ] );

    # top row (row 1)
    $LLobj->add_answer_text( $entries[0], [ 0.5, 5.5 + $answer_dy ] );
    $LLobj->add_answer_text( $entries[1], [ 1.5, 5.5 + $answer_dy ] );

    $LLobj->add_answer_text( $entries[2], [ 3.5, 5.5 + $answer_dy ] );
    $LLobj->add_answer_text( $entries[3], [ 4.5, 5.5 + $answer_dy ] );
    $LLobj->add_answer_text( $entries[4], [ 5.5, 5.5 + $answer_dy ] );

    # row 2
    $LLobj->add_answer_text( $entries[5], [ 0.5, 4.5 + $answer_dy ] );
    $LLobj->add_answer_text( $entries[6], [ 1.5, 4.5 + $answer_dy ] );
    $LLobj->add_answer_text( $entries[7], [ 2.5, 4.5 + $answer_dy ] );

    $LLobj->add_answer_text( $entries[8], [ 4.5, 4.5 + $answer_dy ] );
    $LLobj->add_answer_text( $entries[9], [ 5.5, 4.5 + $answer_dy ] );

    # row 3
    $LLobj->add_answer_text( $entries[10], [ 0.5, 3.5 + $answer_dy ] );

    $LLobj->add_answer_text( $entries[11], [ 2.5, 3.5 + $answer_dy ] );
    $LLobj->add_answer_text( $entries[12], [ 3.5, 3.5 + $answer_dy ] );
    $LLobj->add_answer_text( $entries[13], [ 4.5, 3.5 + $answer_dy ] );

    # row 4
    $LLobj->add_answer_text( $entries[14], [ 1.5, 2.5 + $answer_dy ] );
    $LLobj->add_answer_text( $entries[15], [ 2.5, 2.5 + $answer_dy ] );
    $LLobj->add_answer_text( $entries[16], [ 3.5, 2.5 + $answer_dy ] );

    $LLobj->add_answer_text( $entries[17], [ 5.5, 2.5 + $answer_dy ] );

    # row 5
    $LLobj->add_answer_text( $entries[18], [ 0.5, 1.5 + $answer_dy ] );
    $LLobj->add_answer_text( $entries[19], [ 1.5, 1.5 + $answer_dy ] );

    $LLobj->add_answer_text( $entries[20], [ 3.5, 1.5 + $answer_dy ] );
    $LLobj->add_answer_text( $entries[21], [ 4.5, 1.5 + $answer_dy ] );
    $LLobj->add_answer_text( $entries[22], [ 5.5, 1.5 + $answer_dy ] );

    # row 6
    $LLobj->add_answer_text( $entries[23], [ 0.5, 0.5 + $answer_dy ] );

    $LLobj->add_answer_text( $entries[24], [ 1.5, 0.5 + $answer_dy ] );
    $LLobj->add_answer_text( $entries[25], [ 2.5, 0.5 + $answer_dy ] );
    $LLobj->add_answer_text( $entries[26], [ 4.5, 0.5 + $answer_dy ] );
    $LLobj->add_answer_text( $entries[27], [ 5.5, 0.5 + $answer_dy ] );

    # add the lines for a 6x6 square puzzle
    # to the LatticeLines object:

    $LLobj->add_line( [ 0, -1, 6, -1 ] );    # horizontals

    $LLobj->add_line( [ -1, 0, 7, 0 ] );
    $LLobj->add_line( [ -1, 1, 7, 1 ] );
    $LLobj->add_line( [ -1, 2, 7, 2 ] );
    $LLobj->add_line( [ -1, 3, 7, 3 ] );
    $LLobj->add_line( [ -1, 4, 7, 4 ] );
    $LLobj->add_line( [ -1, 5, 7, 5 ] );
    $LLobj->add_line( [ -1, 6, 7, 6 ] );

    $LLobj->add_line( [ 0, 7, 6, 7 ] );

    $LLobj->add_line( [ -1, 0, -1, 6 ] );    # verticals

    $LLobj->add_line( [ 0, -1, 0, 7 ] );
    $LLobj->add_line( [ 1, -1, 1, 7 ] );
    $LLobj->add_line( [ 2, -1, 2, 7 ] );
    $LLobj->add_line( [ 3, -1, 3, 7 ] );
    $LLobj->add_line( [ 4, -1, 4, 7 ] );
    $LLobj->add_line( [ 5, -1, 5, 7 ] );
    $LLobj->add_line( [ 6, -1, 6, 7 ] );

    $LLobj->add_line( [ 7, 0, 7, 6 ] );

    # these are the heavy lines outlining the area with the 9 numbers
    $LLobj->add_line( [ 0, 6, 6, 6 ], { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( [ 6, 6, 6, 0 ], { 'stroke-width' => $thick_line_width } );

    $LLobj->add_line( [ 6, 0, 0, 0 ], { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( [ 0, 0, 0, 6 ], { 'stroke-width' => $thick_line_width } );

    # top 2 interior boxes:
    $LLobj->add_line( [ 2, 6, 2, 5 ], { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( [ 3, 6, 3, 4 ], { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( [ 4, 5, 4, 4 ], { 'stroke-width' => $thick_line_width } );

    $LLobj->add_line( [ 2, 5, 4, 5 ], { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( [ 3, 4, 4, 4 ], { 'stroke-width' => $thick_line_width } );

    # right 2 interior boxes:
    $LLobj->add_line( [ 5, 4, 6, 4 ], { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( [ 4, 3, 6, 3 ], { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( [ 4, 2, 5, 2 ], { 'stroke-width' => $thick_line_width } );

    $LLobj->add_line( [ 5, 2, 5, 4 ], { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( [ 4, 2, 4, 3 ], { 'stroke-width' => $thick_line_width } );

    # bottom 2 interior boxes:
    $LLobj->add_line( [ 4, 0, 4, 1 ], { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( [ 3, 0, 3, 2 ], { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( [ 2, 1, 2, 2 ], { 'stroke-width' => $thick_line_width } );

    $LLobj->add_line( [ 2, 1, 4, 1 ], { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( [ 2, 2, 3, 2 ], { 'stroke-width' => $thick_line_width } );

    # Left 2 interior boxes:
    $LLobj->add_line( [ 0, 2, 1, 2 ], { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( [ 0, 3, 2, 3 ], { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( [ 1, 4, 2, 4 ], { 'stroke-width' => $thick_line_width } );

    $LLobj->add_line( [ 1, 2, 1, 4 ], { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( [ 2, 3, 2, 4 ], { 'stroke-width' => $thick_line_width } );

    # top edge arrows
    $LLobj->add_arrow( [ 0.5, 6.5, 1,   6 ] );
    $LLobj->add_arrow( [ 1.5, 6.5, 1.5, 6 ] );
    $LLobj->add_arrow( [ 2.5, 6.5, 3,   6 ] );
    $LLobj->add_arrow( [ 3.5, 6.5, 4,   6 ] );
    $LLobj->add_arrow( [ 4.5, 6.5, 4.5, 6 ] );
    $LLobj->add_arrow( [ 5.5, 6.5, 5.5, 6 ] );

    # right edge arrows
    $LLobj->add_arrow( [ 6.5, 5.5, 6, 5 ] );
    $LLobj->add_arrow( [ 6.5, 4.5, 6, 4.5 ] );
    $LLobj->add_arrow( [ 6.5, 3.5, 6, 3 ] );
    $LLobj->add_arrow( [ 6.5, 2.5, 6, 2 ] );
    $LLobj->add_arrow( [ 6.5, 1.5, 6, 1.5 ] );
    $LLobj->add_arrow( [ 6.5, 0.5, 6, 0.5 ] );

    # bottom edge arrows
    $LLobj->add_arrow( [ 5.5, -0.5, 5,   0 ] );
    $LLobj->add_arrow( [ 4.5, -0.5, 4.5, 0 ] );
    $LLobj->add_arrow( [ 3.5, -0.5, 3,   0 ] );
    $LLobj->add_arrow( [ 2.5, -0.5, 2,   0 ] );
    $LLobj->add_arrow( [ 1.5, -0.5, 1.5, 0 ] );
    $LLobj->add_arrow( [ 0.5, -0.5, 0.5, 0 ] );

    # right edge arrows
    $LLobj->add_arrow( [ -0.5, 0.5, 0, 1 ] );
    $LLobj->add_arrow( [ -0.5, 1.5, 0, 1.5 ] );
    $LLobj->add_arrow( [ -0.5, 2.5, 0, 3 ] );
    $LLobj->add_arrow( [ -0.5, 3.5, 0, 4 ] );
    $LLobj->add_arrow( [ -0.5, 4.5, 0, 4.5 ] );
    $LLobj->add_arrow( [ -0.5, 5.5, 0, 5.5 ] );

    # interior box arrows
    $LLobj->add_arrow( [ 2.5, 5.5, 3,   5.5 ] );
    $LLobj->add_arrow( [ 3.5, 4.5, 3.5, 4 ] );

    $LLobj->add_arrow( [ 5.5, 3.5, 5.5, 3 ] );
    $LLobj->add_arrow( [ 4.5, 2.5, 4,   2.5 ] );

    $LLobj->add_arrow( [ 3.5, 0.5, 3,   0.5 ] );
    $LLobj->add_arrow( [ 2.5, 1.5, 2.5, 2 ] );

    $LLobj->add_arrow( [ 0.5, 2.5, 0.5, 3 ] );
    $LLobj->add_arrow( [ 1.5, 3.5, 2,   3.5 ] );

    return $LLobj;
}

sub square3x3_puzzle {

    #    my $scale          = shift || 100;
    #  my $offset_x       = shift || 0.5;
    #  my $offset_y       = shift || 0.5;
    my $numbers_string = shift || '1,1,2,3,5,7';
    my $target_size = 9;
    my @entries = @{ randomize_numbers( $numbers_string, $target_size ) };

    my $std_line_width   = 0.02;                # * $scale / 100;
    my $thick_line_width = 0.06;                # * $scale / 100;
    my $angle            = pi / 2;
    my $LLobj            = LatticeLines->new(
        {
            'basis' => [ [ 1, 0 ], [ 1 * cos($angle), -1 * 1 * sin($angle) ] ],

            #      'offset' => [ $offset_x * $scale, $offset_y * $scale ],
            # 'margin' => [1*$scale, 1*$scale],
            #          'font-size'    => int( $scale / 3.3 ),
            'text-anchor'  => 'middle',
            'line_options' => { 'stroke-width' => $std_line_width },
            'show_arrows'  => 1
        }
    );

    # diagonal clue:
    my $clue_A = $entries[0] * $entries[4] * $entries[8];

    # row clues:
    my $clue_B = $entries[0] * $entries[1] * $entries[2];
    my $clue_C = $entries[3] * $entries[4] * $entries[5];
    my $clue_D = $entries[6] * $entries[7] * $entries[8];

    # other diagonal clue:
    my $clue_E = $entries[2] * $entries[4] * $entries[6];

    # column clues:
    my $clue_F = $entries[0] * $entries[3] * $entries[6];
    my $clue_G = $entries[1] * $entries[4] * $entries[7];
    my $clue_H = $entries[2] * $entries[5] * $entries[8];

    my $dist_from_box = -0.6;
    $LLobj->add_clue_text( $clue_A, "$dist_from_box,3.5" );
    $LLobj->add_clue_text( $clue_B, "$dist_from_box,2.5" );

    $LLobj->add_clue_text( $clue_C, "$dist_from_box,1.5" );
    $LLobj->add_clue_text( $clue_D, "$dist_from_box,0.5" );

    $LLobj->add_clue_text( $clue_E, "$dist_from_box,$dist_from_box" );
    $LLobj->add_clue_text( $clue_F, "0.5,$dist_from_box" );
    $LLobj->add_clue_text( $clue_G, "1.5,$dist_from_box" );
    $LLobj->add_clue_text( $clue_H, "2.5,$dist_from_box" );

    $LLobj->add_answer_text( $entries[0], "0.5,2.5" );
    $LLobj->add_answer_text( $entries[3], "0.5,1.5" );
    $LLobj->add_answer_text( $entries[6], "0.5,0.5" );

    $LLobj->add_answer_text( $entries[1], "1.5,2.5" );
    $LLobj->add_answer_text( $entries[4], "1.5,1.5" );
    $LLobj->add_answer_text( $entries[7], "1.5,0.5" );

    $LLobj->add_answer_text( $entries[2], "2.5,2.5" );
    $LLobj->add_answer_text( $entries[5], "2.5,1.5" );
    $LLobj->add_answer_text( $entries[8], "2.5,0.5" );

    # add the lines for a 9-number square puzzle
    # to the LatticeLines object:

    $LLobj->add_line('-1,3,0,3');    # horizontals
    $LLobj->add_line('-1,2,3,2');
    $LLobj->add_line('-1,1,3,1');
    $LLobj->add_line('-1,0,0,0');

    $LLobj->add_line('0,4,0,3');     # verticals
    $LLobj->add_line('0,0,0,-1');
    $LLobj->add_line('1,3,1,-1');
    $LLobj->add_line('2,3,2,-1');
    $LLobj->add_line('3,0,3,-1');

    # these are the heavy lines outlining the area with the 9 numbers
    $LLobj->add_line( '0,3,3,3', { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( '0,0,3,0', { 'stroke-width' => $thick_line_width } );

    $LLobj->add_line( '0,3,0,0', { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( '3,3,3,0', { 'stroke-width' => $thick_line_width } );

    $LLobj->add_arrow('-0.5,-0.5,0,0');
    $LLobj->add_arrow('0.5,-0.5,0.5,0');
    $LLobj->add_arrow('1.5,-0.5,1.5,0');
    $LLobj->add_arrow('2.5,-0.5,2.5,0');
    $LLobj->add_arrow('-0.5,0.5,0,0.5');
    $LLobj->add_arrow('-0.5,1.5,0,1.5');
    $LLobj->add_arrow('-0.5,2.5,0,2.5');
    $LLobj->add_arrow('-0.5,3.5,0,3');

    return $LLobj;
}

sub triangle9_puzzle {

    #   my $scale          = shift || 100;
    #   my $offset_x       = shift || 0.5;
    #   my $offset_y       = shift || 0.5;
    my $numbers_string = shift || '1,1,1,2,2,2,3,5,7';
    my $target_size = 9;
    my @entries = @{ randomize_numbers( $numbers_string, $target_size ) };
    my $size    = scalar @entries;

    my $std_line_width   = 0.02;                # * $scale / 100;
    my $thick_line_width = 0.06;                # * $scale / 100;
    my $angle            = pi / 3;
    my $LLobj            = LatticeLines->new(
        {
            'basis' => [ [ 1, 0 ], [ 1 * cos($angle), -1 * 1 * sin($angle) ] ],

            #        'offset' => [ $offset_x * $scale, $offset_y * $scale ],
            #	 'margin' => [0.5*$scale, 0.5*$scale],
            'font-size'    => 0.3,
            'text-anchor'  => 'middle',
            'line_options' => { 'stroke-width' => $std_line_width },
            'show_arrows'  => 1
        }
    );

    my $clue_A =
      $entries[0] * $entries[2] * $entries[3] * $entries[7] * $entries[8];
    my $clue_B = $entries[1] * $entries[5] * $entries[6];

    my $clue_C =
      $entries[0] * $entries[1] * $entries[2] * $entries[4] * $entries[5];
    my $clue_D = $entries[3] * $entries[6] * $entries[7];

    my $clue_E =
      $entries[4] * $entries[5] * $entries[6] * $entries[7] * $entries[8];
    my $clue_F = $entries[1] * $entries[2] * $entries[3];

    $LLobj->add_clue_text( $clue_A, '-0.47,3.9' );
    $LLobj->add_clue_text( $clue_B, '-0.47,2.9' );

    $LLobj->add_clue_text( $clue_C, '0.53,0.4' );
    $LLobj->add_clue_text( $clue_D, '1.53,0.4' );

    $LLobj->add_clue_text( $clue_E, '3,1.4' );
    $LLobj->add_clue_text( $clue_F, '2,2.4' );

    $LLobj->add_answer_text( $entries[0], '0.4,3.2' );
    $LLobj->add_answer_text( $entries[1], '0.4,2.2' );
    $LLobj->add_answer_text( $entries[4], '0.4,1.2' );

    $LLobj->add_answer_text( $entries[3], '1.4,2.2' );
    $LLobj->add_answer_text( $entries[6], '1.4,1.2' );
    $LLobj->add_answer_text( $entries[8], '2.4,1.2' );

    $LLobj->add_answer_text( $entries[2], '0.75,2.5' );
    $LLobj->add_answer_text( $entries[5], '0.75,1.5' );
    $LLobj->add_answer_text( $entries[7], '1.75,1.5' );

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
    $LLobj->add_line( '0,1,0,4', { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( '0,1,3,1', { 'stroke-width' => $thick_line_width } );
    $LLobj->add_line( '0,4,3,1', { 'stroke-width' => $thick_line_width } );

    return $LLobj;
}

sub randomize_numbers {    # take the argument (string of numbers)

    # and get an array of numbers in randomized order
    my $numbers_string = shift || '1,2,3,5,7,11';
    my $target_size    = shift;
    my @numbers        = split( '\s*,\s*', $numbers_string ); # split on commas (optionally with whitespace before and/or after).
    my $size           = scalar @numbers;
    my @entries        = ();
    foreach ( 0 .. $target_size - 1 ) {
        $entries[$_] = @numbers[ $_ % $size ];
    }
    $size = scalar @entries;
    my $n_randomize = 4 * $size;
    foreach ( 1 .. $n_randomize ) {
        foreach my $i ( 0 .. $size - 1 ) {
            my $j = int( rand() * $size );
            if ( $j != $i ) {    # switch ith and jth elements
                my $tmp = $entries[$j];
                $entries[$j] = $entries[$i];
                $entries[$i] = $tmp;
            }
        }
    }

    return \@entries;
}
