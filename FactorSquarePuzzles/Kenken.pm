package Kenken;

# object representing a kenken grid with numbers in it (but
# not cages or operations). i.e. an n x n grid with 1 through n 
# each occurring exactly 1 time in each row and each column.

sub new{
  my $class = shift;
    my $self = bless {}, $class;

my $size = shift || 5;

my @rows = ();

my @elems = ();
for(my $i=0; $i<$size; $i++){
push @elems, $i+1;
}
push @rows, \@elems;

for(my $i=1; $i<$size; $i++){

        my @arow = @{$rows[$i-1]};

        my $el = shift @arow;
        push @arow, $el;

#       print join(" ", @arow), "\n";
        push @rows, \@arow;

}
$self->{rows} = \@rows;

return $self;
} # end of constructor

sub print{
my $self = shift;
my @rows = @{$self->{rows}};
foreach (@rows){
print join(" ", @$_), "\n";
}
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
1;
