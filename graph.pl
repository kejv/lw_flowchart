#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use GraphAlgs;

use Data::Dumper qw/Dumper/;
use IPC::Run qw/run/;
use Time::HiRes qw/time/;
use XML::Twig;

#-------------------------------------------------------------------------------

my $format = 'svg';
my $base_path = 'graphs';

$, = ",";

my @files = @ARGV;

my $g;
my $dot;

for (@files) {
	my ($name) = m|([^/\.]+)\..+$|;
# 	print $name;
	my $dot_file = $base_path. "/" .$name. ".dot";
	open DOT, ">", $dot_file;
	
	my $time = time;
	$g = {};
	
	$time = time;
	XML::Twig->new(
		twig_roots => {
			'/gamebook/meta/title'                         => \&title  ,
			'section[ @class="numbered" and @id=~/sect/ ]' => \&section,
		}
	)->parsefile($_);
	print "Parsing: ". (time - $time) ."\n";
	close DOT;
	
	$time = time;
	run join( " ", ("dot", "-T".$format, $dot_file, "-o".$base_path."/".$name.".".$format) );
# 	run \@cmd;
	print "Dot: ". (time - $time) ."\n";
	
	$time = time;
	for my $SCC ( @{ GraphAlgs::strongly_connected_components($g) } ) {
		print @$SCC,"\n" if @$SCC > 1;
	}
	print "SCC: ". (time - $time) ."\n";
}

<STDIN>;

#-------------------------------------------------------------------------------

# init .dot file
sub title {
	print DOT qq/digraph "/ . $_->text . qq/: Paths" {\n\tnode [label="\\N"]\n/;
	
	$_->purge;
}

sub section {
	my ($t,$elt) = @_;
	# node attributes
# 	my ($n_color, $n_fillcolor, $n_fontcolor, $n_peripheries, $n_shape, $n_label);
	# edge attributes
# 	my ($e_color, $e_fontcolor, $e_label);
	
	my %node_attrs;
	
	# section number
	my $id = ( $elt->get_xpath('meta/title') )[0]->text;
	# choices elements
	my @choices = $elt->get_xpath('data/choice');
	# is big illustration present?
	my $ill = $elt->get_xpath('data/illustration/meta/description');
	# footnotes
	my @footnotes = $elt->get_xpath('footnotes/footnote');
	
	if ( $id == 350 ) {
		$node_attrs{fillcolor} = 'gold';
		$node_attrs{style} = 'filled';
	}
	if ( $ill ) {
		$node_attrs{peripheries} = 2;
		$node_attrs{color} = 'purple';
	}

	if ( @choices ) {
		for ( @choices ) {
			my $attr_idref = $_->att('idref');
			if ( defined $attr_idref ) {
				my ($idref) = $attr_idref =~ /sect(\d+)/;
				my %edge_attrs;
				push @{ $g->{$id} }, $idref;

				print_edge($id, $idref, %edge_attrs); 
			} else { # should be @choices == 1
				$node_attrs{color} = 'crimson';
				$node_attrs{shape} = 'invtriangle';
			}
		}
	} elsif ( @footnotes ) {
		$node_attrs{color} = 'orange';
		$node_attrs{shape} = 'triangle';
	} else {
		$node_attrs{color} = 'crimson';
		$node_attrs{shape} = 'invtriangle';
	}

	print_node($id, %node_attrs);

	$elt->purge;
}

sub print_node {
	my ($id, %node_attrs) = @_;
	
	return unless %node_attrs;
	
	print DOT "\t" .$id. " [";
	print DOT join( ", ", map $_."=".$node_attrs{$_}, keys %node_attrs );
	print DOT "]\n";
	print DOT "}" if $id == 350; # end of .dot file
}

sub print_edge {
	my ($id, $idref, %edge_attrs) = @_;
	
	print DOT "\t" .$id. " -> " .$idref;
	if ( %edge_attrs ) {
		print DOT " [";
		print DOT join( ", ", map $_."=".$edge_attrs{$_}, keys %edge_attrs );
		print DOT "]";
	}
	print DOT "\n";
}