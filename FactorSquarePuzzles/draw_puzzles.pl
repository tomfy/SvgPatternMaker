#!/usr/bin/perl -w
use strict;
use Math::Trig;
use LatticeLines;
use Getopt::Std;

use vars qw($opt_p $opt_s $opt_w $opt_a);

# -p <puzzle pattern. Options are  2x3 (default), 3x3, 2x4, triangle,
# -s <scale. e.g. 50>
# -w <what to show? clues, answers, both. (default is clues)>
# -a <show arrows? 0/1, default: 0>
# typical usage: perl bootstrap_ortholog.pl -i $align_filename -T ML -k -n 1 -N 100 -S 12345 -r mindl -m 0.015 -q castorbean > outfile

# get options
getopts("p:s:w:a:");

# defaults:
my $type  = $opt_p || '2x3';
my $scale = $opt_s || 54;

my $what_to_show = $opt_w
  || 'clues';    # by default show the clues but not the answers. 'answers' 'both' are other possibilities.
my $show_clues   = 1;
my $show_answers = 0;
my $show_arrows  = ( uc $opt_a eq 'N' ) ? 0 : 1;
if ( $what_to_show eq 'answers' ) {
    $show_clues   = 0;
    $show_answers = 1;
} elsif ( $what_to_show eq 'both' ) {
    $show_clues   = 1;
    $show_answers = 1;
} elsif ( $what_to_show eq 'clues' ) {

} else {
    warn '$what_to_show has invalid value: ', $what_to_show,
      "; using default value 'clues'. Valid values are 'clues', 'answers', 'both' \n";
}

# now put together the svg string:
my ( $width, $height ) = ( 765, 990 );    # letter size
my $svg_string =
'<?xml version="1.0" standalone="no"?> <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">'
  . "\n";
$svg_string .=
  '<svg width="' . $width . '" height="' . $height . '" version="1.1" xmlns="http://www.w3.org/2000/svg">' . "\n";

my $n_rows = 1;
my $n_cols = 1;
for my $row ( 0 .. $n_rows - 1 ) {
    for my $col ( 0 .. $n_cols - 1 ) {
        my $x_off = 1.0 + $col * 6.64;
        my $y_off = 0.895 + $row * 5.84;
        my $puzzle_obj;
        if ( $type eq '2x3' ) {
            $puzzle_obj = rectangle2x3_puzzle('1,2,3,5,7,11');
        } elsif ( $type eq '2x4' ) {
            $puzzle_obj = rectangle2x4_puzzle('1,2,3,5,7,11,2,3');
        } elsif ( $type eq '3x4' ) {
            $puzzle_obj = rectangle3x4_puzzle();
        } elsif ( $type eq '3x3' ) {
            $puzzle_obj = square3x3_puzzle('2,3,5,1,2,3,5');
        } elsif ( $type eq '6x6' ) {
            $puzzle_obj = square6x6_puzzle('1,2,3,5,7,11,1,2,3,5,1,2,3,5,7,11,13');
        } else {
            $puzzle_obj = triangle9_puzzle();
        }

        # svg body:
        $svg_string .= $puzzle_obj->svg_string(
                                                [ $scale * $x_off, $scale * ( $y_off + 5 ) ],
                                                $scale,
                                                {
                                                   show_clues   => $show_clues,
                                                   show_answers => $show_answers,
                                                   show_arrows  => $show_arrows
                                                }
                                              );

    }
}

# end of svg:
$svg_string .= '</svg>' . "\n";

print $svg_string, "\n";

# end of main.

sub rectangle2x3_puzzle {

    #   my $scale          = shift || 100;
    my $numbers_string = shift || '1,2,3,5,7,11';

    my $target_size = 6;
    my @entries = @{ randomize_numbers( $numbers_string, $target_size ) };

    my $std_line_width   = 0.02;     # 2 * $scale / 100;
    my $thick_line_width = 0.06;     # 6 * $scale / 100;
    my $angle            = pi / 2;
    my $LLobj = LatticeLines->new(
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

    my $std_line_width   = 0.02;     # 2 * $scale / 100;
    my $thick_line_width = 0.06;     #  * $scale / 100;
    my $angle            = pi / 2;
    my $LLobj = LatticeLines->new(
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

    my $std_line_width   = 0.02;     # * $scale / 100;
    my $thick_line_width = 0.06;     # * $scale / 100;
    my $angle            = pi / 2;
    my $LLobj = LatticeLines->new(
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
}

sub square6x6_puzzle {

    #    my $scale          = shift || 100;
    #  my $offset_x       = shift || 0.5;
    #  my $offset_y       = shift || 0.5;
    my $numbers_string = shift || '1,1,2,3,5,7';
    my $target_size    = 28;
    my @entries        = @{ randomize_numbers( $numbers_string, $target_size ) };

    my $std_line_width   = 0.02;     # * $scale / 100;
    my $thick_line_width = 0.075;    # * $scale / 100;
    my $angle            = pi / 2;
    my $LLobj = LatticeLines->new(
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
    my ( $clue_dy_top, $clue_dx_right, $clue_dy_bottom, $clue_dx_left ) = ( -0.05, 0.1, -0.15, -0.1 );
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
    my $target_size    = 9;
    my @entries        = @{ randomize_numbers( $numbers_string, $target_size ) };

    my $std_line_width   = 0.02;     # * $scale / 100;
    my $thick_line_width = 0.06;     # * $scale / 100;
    my $angle            = pi / 2;
    my $LLobj = LatticeLines->new(
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
    my $target_size    = 9;
    my @entries        = @{ randomize_numbers( $numbers_string, $target_size ) };
    my $size           = scalar @entries;

    my $std_line_width   = 0.02;     # * $scale / 100;
    my $thick_line_width = 0.06;     # * $scale / 100;
    my $angle            = pi / 3;
    my $LLobj = LatticeLines->new(
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

    my $clue_A = $entries[0] * $entries[2] * $entries[3] * $entries[7] * $entries[8];
    my $clue_B = $entries[1] * $entries[5] * $entries[6];

    my $clue_C = $entries[0] * $entries[1] * $entries[2] * $entries[4] * $entries[5];
    my $clue_D = $entries[3] * $entries[6] * $entries[7];

    my $clue_E = $entries[4] * $entries[5] * $entries[6] * $entries[7] * $entries[8];
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
    my @numbers        = split( ',', $numbers_string );
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
