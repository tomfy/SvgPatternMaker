#!/usr/bin/perl -w
use strict;
#use Math;
use FactorSquare;

my $size = shift || 10;
my $box_width = shift || 5;
my $primestr = shift || '1,2,3,2,5,3,1,2,7';
$primestr =~ s/'//g;
my @primes = split(",", $primestr);
my $fs_obj = FactorSquare->new($size, \@primes);

my ($nrows_of_puzzles, $ncols_of_puzzles) = (3,2);

my @rows_of_puzzles = ();
foreach (1..$nrows_of_puzzles){
	my @row_of_puzzles = (); # array of refs to arrays of lines
	foreach (1..$ncols_of_puzzles){

		$fs_obj->randomize();
#	my $block_lines_aref = lines_to_block_array($fs_obj->puzzle_string($box_width));

		push @row_of_puzzles, lines_to_block_array($fs_obj->puzzle_string($box_width));
#	foreach(@$block_lines_aref){ print $_, "\n"; }

	}
	push @rows_of_puzzles, \@row_of_puzzles;
}

my $indent = '   ';
my $spacer = '      ';
my $vspace = 4;
my $nlines_in_block = 0;

my $puzzles_string = '';
foreach(1..$vspace){ $puzzles_string .= "\n"; }
foreach my $irow (0..$nrows_of_puzzles-1){
	my @row_of_puzzles = @{$rows_of_puzzles[$irow]};
	$nlines_in_block = scalar @{$row_of_puzzles[0]};

	foreach my $iline (0..$nlines_in_block-1){
		$puzzles_string .= $indent;
		foreach my $icol (0..$ncols_of_puzzles-1){
			my $puzzle = $row_of_puzzles[$icol];
			my $line = $puzzle->[$iline];
			$puzzles_string .= "$spacer$line";

		} $puzzles_string .= "\n";
	}	
	foreach (1..$vspace){ $puzzles_string .= "\n"; }
}		

print $puzzles_string, "\n";





sub lines_to_block_array{
	my $puzzle_string = shift; 
	my $block_width = shift || 30;
	my $block_height = shift || 45;

	my $padding = '                              ';
	while(length $padding < $block_width){ $padding .= $padding; }

	my @block_array = split("\n", $puzzle_string);
	foreach (@block_array){
		$_ = substr($_ . $padding, 0, $block_width);
	}
	return \@block_array;
}



