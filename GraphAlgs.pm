package GraphAlgs;

use strict;
use warnings FATAL => 'all';

# Tarjan's algorithm
sub strongly_connected_components {
	my $g = shift;
	my $index = 0;
	my @stack = ();
	# vertices of g
	my $vertices = {};
	my $SCC = [];
	
	my $strong_connect;
	$strong_connect = sub {
		my $v = shift;
		
		$vertices->{$v}{index} = $index;
		$vertices->{$v}{lowlink} = $index++;
		$vertices->{$v}{stack} = 1;
		push @stack, $v;
		
		if ( exists $g->{$v} ) { # avoid autovivification
		for my $w ( keys $g->{$v} ) {
			if ( not defined $vertices->{$w}{index} ) {
				$strong_connect->($w);
				if ( $vertices->{$v}{lowlink} > $vertices->{$w}{lowlink} ) {
					$vertices->{$v}{lowlink} = $vertices->{$w}{lowlink}
				}
			} elsif ( $vertices->{$w}{stack} ) {
				if ( $vertices->{$v}{lowlink} > $vertices->{$w}{index} ) {
					$vertices->{$v}{lowlink} = $vertices->{$w}{index}
				}
			}
		}
		}
		
		if ( $vertices->{$v}{lowlink} == $vertices->{$v}{index} ) {
			my $count = @$SCC;
			my $w;
			do {
				$w = pop @stack;
				$vertices->{$w}{stack} = 0;
				push @{ $SCC->[$count] }, $w;
			} until $w == $v;
		}
	};
	
	for ( keys $g ) {
		$strong_connect->($_) unless defined $vertices->{$_}{index};
	}
	
	return $SCC;
}

1;