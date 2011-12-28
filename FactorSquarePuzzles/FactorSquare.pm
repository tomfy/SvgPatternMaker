package FactorSquare;

# object representing a grid with numbers in it. 
# i.e. an n x n grid with each square
# containing either 1 or a (small) prime

sub new{
	my $class = shift;
	my $self = bless {}, $class;

	my $size = shift || 3;
	my $n_squares = $size*$size;
	my $primes_aref = shift || [1,1,1,1,1,1,1,1];  # [1,2,3,5,2,1,3,7,2];
	my @primes = @{$primes_aref};
	my $n_primes = scalar @primes;
#	my @primes = (1,2,3,5,7,11,13,17,19,23,29);
	my @rows = ();
	my $index = 0;
	while(scalar @entries < $n_squares){
		push @entries, $primes[$index];
		$index++;
		$index = $index % $n_primes;
	}
	$self->{entries} = \@entries;
	$self->{nrows} = $size;
	$self->{ncols} = $size;
	return $self;
}


sub randomize{
	my $self = shift;
	my $entries = $self->{entries};
#	print "entries: ", join(" ", @$entries), "\n";
	my $n_squares = $self->{nrows} * $self->{ncols};
# randomize the order of the entries:
	my $n_randomize = 10 * (1 + $n_squares**1.5);
	foreach my $i (1..$n_randomize){
		my $j = int (rand() * $n_squares);
		my $k = int(rand() * $n_squares);
		if($j != $k){
			my $tmp = $entries->[$j];
			$entries->[$j] = $entries->[$k];
			$entries->[$k] = $tmp;
		}
	}
# store in array or arrays.
	my @col_products = ((1) x $self->{ncols});
	my @row_products = ();
	my ($diag_product1, $diag_product2) = (1, 1);
	for(my $j=0; $j<$self->{nrows}; $j++){
		my @elems = (); # elements in a row
			my $row_product = 1;
		for(my $i=0; $i<$self->{ncols}; $i++){
			my $next_entry = shift @$entries; push @$entries, $next_entry;
			$diag_product1 *= $next_entry if($i == $j);
			$diag_product2 *= $next_entry if($i + $j == 2);
			$row_product *= $next_entry;
			$col_products[$i] *= $next_entry;
			push @elems, $next_entry;
		}
		push @row_products, $row_product;
		push @rows, \@elems;
	}

	$self->{diag_product1} = $diag_product1;
$self->{diag_product2} = $diag_product2;
	$self->{rows} = \@rows;
	$self->{row_products} = \@row_products;
	$self->{col_products} = \@col_products;
	return $self;
} # end of randomize

sub print{  # prints the grid of numbers, including row, col and diagonal products.
	my $self = shift;
	my @rows = @{$self->{rows}};
	
	print "\n";
	print substr('     ' . $self->{diag_product1}, -4), "\n";
	foreach (@rows){
		my $row_product = 1;
		foreach my $number (@$_){
			$row_product *= $number;
			$number = substr('     ' . $number, -3);
#			if(length $number eq 1){
#				$number = ' ' . $number;
#			}
		}
		$row_product = '     ' . $row_product;
		$row_product = substr($row_product, -4);
		print join(" ", ($row_product, @$_)), "\n";
	}
	my @col_products = @{$self->{col_products}};
	print substr('    '. $self->{diag_product2}, -4) . " ";
	foreach(@col_products){ 
		my $s = substr('    ' . $_, -3);
		print "$s ";
#printf("%3i ", $_); 
} print "\n";
}

sub _exchange_rows{
	my $self = shift;
	my $r1 = shift;
	my $r2 = shift;
	my $rows = $self->{rows};
	my $tmp = $rows->[$r1];
	$rows->[$r1] = $rows->[$r2];
	$rows->[$r2] = $tmp;
}

sub _exchange_columns{
	my $self = shift;
	my $c1 = shift;
	my $c2 = shift;
	foreach my $row (@{$self->{rows}}){
		my $tmp = $row->[$c1];
		$row->[$c1] = $row->[$c2];
		$row->[$c2] = $tmp;
	}
}

sub print_puzzle_old{
	my $self = shift;
	my $s8 = "        ";
	my $s3p = "   |";
	my $s4p = "    |";
	my $s5p = "     |";
	my $u3p = "___|";
	my $u4p = "____|";
	my $u5p = "_____|";
	my $u3 = "___";
	my $u4 = "____";
	my $u5 = "_____";
	my $u6 = "______";

	foreach(1..1){ print "$s8$s5p\n"; }
print "$s8  18 |\n";
	print "$s8$u5p$u6$u6$u5\n";
	foreach(1..3){
		for(1..2){ print "$s8$s5p$s5p$s5p$s5p \n"; };
		print "$s8$u5p$u5p$u5p$u5p \n";
	}
	for(1..3){ print "$s8$s5p$s5p$s5p$s5p \n"; }
	print "\n\n";
}

sub puzzle_string{ 
# return a string which when printed gives a puzzle 
# with boxes delineated by _ and | characters.
	my $self = shift;
	my $box_width = shift || 5;
	my $box_height = shift || 3;

	my ($nrows, $ncols) = ($self->{nrows}, $self->{ncols});
	my ($rowprods, $colprods) = ($self->{row_products}, $self->{col_products});	
	my $puzzle_string = '';	

	my $u_w = substr('_____________________', 0, $box_width);
	my $u_wp = $u_w . '_';
	my $s_w = substr('                     ', 0, $box_width);
	my $s_wp = $s_w . ' ';

     	$puzzle_string .= $s_w . '|' . "\n";

	$puzzle_string .= _center_in_box($self->{diag_product1}, $box_width) . '|' . "\n";;
	$puzzle_string .= $u_w . '|';
	foreach(2..$ncols){ $puzzle_string .= $u_wp; } $puzzle_string .= $u_w . "\n";

	foreach my $row (0..$nrows-1){

		foreach (0..$ncols){ $puzzle_string .= $s_w . '|'; } $puzzle_string .= "\n";

		my $rp = _center_in_box($rowprods->[$row], $box_width);
	$puzzle_string .= $rp . '|';
		foreach(1..$ncols){ $puzzle_string .= $s_w . '|'; } $puzzle_string .= "\n";

		foreach(0..$ncols){ $puzzle_string .= $u_w . '|'; } $puzzle_string .= "\n";

	}
	foreach (0..$ncols){ $puzzle_string .= $s_w . '|'; } $puzzle_string .= "\n";

	$puzzle_string .= _center_in_box($self->{diag_product2}, $box_width) . '|';
 
foreach(0..$ncols-1){ $puzzle_string .= _center_in_box($self->{col_products}->[$_], $box_width) . '|'; } $puzzle_string .= "\n";
    foreach (0..$ncols){ $puzzle_string .= $s_w . '|'; } $puzzle_string .= "\n";


	return $puzzle_string;
}


sub _center_in_box{
	my $str = shift;
	my $width = shift;
	my $l = length $str;
	my $l_space = substr('          ', 0, $width - $l - int(($width - $l)/2));	
	return substr($l_space . $str . '          ', 0, $width);  
}
1;	
