#!/usr/bin/perl

use v5.10;
use strict;
use warnings FATAL => 'all';

use Dictionary;
use GraphAlgs;

use Data::Dumper qw/Dumper/;
use IPC::Run qw/run/;
use Time::HiRes qw/time/;
use XML::Twig;

#-------------------------------------------------------------------------------

my $format = 'svg';
my $base_path = 'graphs/';

$, = ",";

my @files = @ARGV;

my $g;
my $dot;
my $disc;
my $rank;
my $re_disc_rank;
my $re_disc_rank_conj;
my $re_conj_str = "(\ (and|or|but|not)\ |,\ )";
my @conj = (" and ", " or ", " but ", " not ", ", "); 

for (@files) {
	my ($name, $book_no) = m|((\d+)\w+)\..+$|;
# 	print $book_no, $name;
	
	given ( $book_no ) {
		when ( 1  <= $_ and $_ <= 5  ) {
			$disc = $Dictionary::kai_disc;
			$rank = $Dictionary::kai_rank;
		}
		when ( 6  <= $_ and $_ <= 12 ) {
			$disc = $Dictionary::magnakai_disc;
			$rank = $Dictionary::magnakai_rank;
		}
		when ( 13 <= $_ and $_ <= 20 ) {
			$disc = $Dictionary::grand_master_disc;
			$rank = $Dictionary::grand_master_rank;
		}
		default { print "FIXME: book > 20\n"; next }
	}
	
	my $re_disc_rank_str = "(" . join "|", keys %$disc, keys %$rank;
	my $re_disc_rank_conj_str =
		join( "|", $re_disc_rank_str, keys %$Dictionary::conj ) . ")";
	$re_disc_rank_str .= ")";
	$re_disc_rank = qr/$re_disc_rank_str/;
	$re_disc_rank_conj = qr/$re_disc_rank_conj_str/;
	
	my $time = time;
	
	my $dot_file = $base_path .$name. ".dot";
	open DOT, ">", $dot_file;
	
	$time = time;
	XML::Twig->new(
		twig_roots => {
			'/gamebook/meta/title'                         => \&title,
			'section[ @class="numbered" and @id=~/sect/ ]' => \&section,
		}
	)->parsefile($_);
	print "Parsing: ". (time - $time) ."\n";
	
	close DOT;
	
	$time = time;
# 	run join( " ", ("dot", "-T".$format, $dot_file, "-o".$base_path.$name.".".$format) );
	system "dot", "-T".$format, $dot_file, "-o".$base_path.$name.".".$format;
# 	run \@cmd;
	print "Dot: ". (time - $time) ."\n";
	
	$time = time;
	for my $SCC ( @{ GraphAlgs::strongly_connected_components($g) } ) {
		print @$SCC,"\n" if @$SCC > 1;
	}
	print "SCC: ". (time - $time) ."\n";
}

# <STDIN>;

#-------------------------------------------------------------------------------

# init .dot file
sub title {
	print DOT qq/digraph "/ . $_->text . qq/: Paths" {\n\tnode [label="\\N"]\ngraph []\n/;
	
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
		my @found_disc_rank;
		for ( @choices ) {
			my $attr_idref = $_->att('idref');
			if ( defined $attr_idref ) {
				my ($idref) = $attr_idref =~ /sect(\d+)/;
				my %edge_attrs;
				push @{ $g->{$id} }, $idref;

				find_disc_rank($_, \%edge_attrs, \@found_disc_rank);

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

sub find_disc_rank {
	my ($choice, $edge_attrs, $found_disc_rank) = @_;

	my $text = $choice->text;
	my $skip_disc_rank = 0;
	my @discs_ranks;
	my %conj_dict;
	while ( $text =~ /$re_disc_rank_conj/og ) { # regexp is of the form (x|y|...)
		if ( $1 =~ /$re_disc_rank/ ) {
			if ( $skip_disc_rank ) {
# 				print $text . "\n";
				$skip_disc_rank = 0;
			} else {
				push @discs_ranks, $1;
			}
		} elsif ( $1 =~ /(not|neither|nor|but|yet)/ ) { # negative means to skip next disc_rank
			$skip_disc_rank = 1;
		} elsif ( @discs_ranks ) { # ignore conjunctions before first disc_rank
			# possibly rewrite existing value so that only last one is valid
			$conj_dict{ scalar @discs_ranks } = $1;
		}
	}

	return '' unless @discs_ranks;

	for ( keys %conj_dict ) { # ignore conjunctions after last disc_rank
		delete $conj_dict{$_} unless $_ < @discs_ranks;
	}
	my $def_conj = ( grep { $_ eq ' or ' } values %conj_dict ) ? ' or ' : ' and ';
	print $text . $def_conj . "\n";

	my @disc_rank_values;
	push @disc_rank_values, $disc->{$_} // $rank->{$_} for @discs_ranks;
	my $label = $disc_rank_values[0];
	for ( 1 .. $#disc_rank_values ) {
		$label .= $conj_dict{$_} // $def_conj;
		$label .= $disc_rank_values[$_];
	}
	print $text . "\n" if @disc_rank_values > 2;
	$edge_attrs->{label}     = '"' .$label. '"';
	$edge_attrs->{color}     = 'green';
	$edge_attrs->{fontcolor} = 'green';
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