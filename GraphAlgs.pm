package GraphAlgs;

use v5.10;
use strict;
use warnings FATAL => 'all';

use List::MoreUtils;
use Storable;

#-------------------------------------------------------------------------------

# Tarjan's algorithm
# important consequence of this algorithm is that it outputs the SCCs in reverse
# topological order
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

#-------------------------------------------------------------------------------

# Make condensed copy of given graph, i.e. replace all strongly connected
# components with single node, altough preserving enough information such that
# original graph can be reconstructed if needed. In addition to condensation
# return also mapping of SCC replacements' names to original SCC clusters.
sub condense {
	my $g = shift;
	my $g_edges_reversed = reverse_edges($g);
	# SCCs are in reverse topological order - that is important because one SCC
	# can directly point to another and in this case we must process the latter
	# before the former.
	my @SCCs = grep { @$_ > 1 } @{ strongly_connected_components($g) };
	# make deep copy of original graph
	my $g_dclone = Storable::dclone($g);

	my $counter;
	my $clusters;
	for my $SCC ( @SCCs ) {
		my $SCC_name = "cluster" . $counter++;
		my $SCC_cluster; # copy of original SCC
		my $SCC_replacement;
		for my $v ( @$SCC ) {
			my ($outside_cluster, $inside_cluster) =
				List::MoreUtils::part { $_ ~~ @$SCC } keys $g_dclone->{$v};
			for ( @$outside_cluster ) {
				$SCC_replacement->{$_}{from_nodes}{$v} = $g_dclone->{$v}{$_};
				# this is here just to make later processing more convenient
				# excluded situation is already covered by previous cluster
				$SCC_cluster->{$v}{$_} = {} unless /cluster/;
			}
			$SCC_cluster->{self}{$v}{$_} = $g_dclone->{$v}{$_} for @$inside_cluster;
			delete $g_dclone->{$v};

			for ( grep { not $_ ~~ @$SCC } keys $g_edges_reversed->{$v} ) {
				$g_dclone->{$_}{$SCC_name}{to_nodes}{$v} = $g_dclone->{$_}{$v};
				# this is here just to make later processing more convenient
				$SCC_cluster->{$_}{$v} = {};
				delete $g_dclone->{$_}{$v};
			}
		}
		$g_dclone->{$SCC_name} = $SCC_replacement;
		$clusters->{$SCC_name} = $SCC_cluster;
	}

	return ($g_dclone, $clusters);
}

#-------------------------------------------------------------------------------

sub reverse_edges {
	my $g = shift;
	my $g_edges_reversed;

	for my $v ( keys $g ) {
		$g_edges_reversed->{$_}{$v} = $g->{$v}{$_} for keys $g->{$v};
	}

	return $g_edges_reversed;
}

#-------------------------------------------------------------------------------

sub graphviz_simple {
	my $g = shift;
	open DOT, ">", "graphviz_simple.dot";
	print DOT "digraph {\n";
	for my $v ( keys $g ) {
		print DOT "\t" .$v. " -> " .$_. "\n" for keys $g->{$v};
	}
	print DOT "}";
	close DOT;
	system "dot", "-Tsvg", "graphviz_simple.dot", "-ographviz_simple.svg";
}

#-------------------------------------------------------------------------------

sub graphviz {
	my ($g, $clusters) = @_;
	open DOT, ">", "graphviz.dot";
	print DOT "digraph {\n";

	while ( my ($u, $vs) = each $g ) {
		next if $u =~ /cluster/;
		for my $v ( keys $vs ) {
			next if $v =~ /cluster/;
			print DOT "\t" .$u. " -> " .$v. "\n";
		}
	}

	while ( my ($name, $cluster) = each $clusters ) {
		while ( my ($key, $val) = each $cluster ) {
			if ( $key eq "self" ) {
				print DOT "\tsubgraph " .$name. " {\n";
				print DOT "\t\tcolor=darkturquoise\n";
				while ( my ($u, $vs) = each $val ) {
					print DOT "\t\t" .$u. " -> " .$_. "\n" for keys $vs;
				}
				print DOT "\t}\n";
			} else {
				print DOT "\t" .$key. " -> " .$_. "\n" for keys $val;
			}
		}
	}

	print DOT "}";
	close DOT;
	system "dot", "-Tsvg", "graphviz.dot", "-ographviz.svg";
}

1;