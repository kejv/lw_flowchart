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
my $re_conj = qr/\ (and|or|but)\ /;

for (@files) {
	my ($name, $book_no) = m|((\d+)\w+)\..+$|;
# 	print $name;
	
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
	
	my $re_disc_rank_str .= "(";
	$re_disc_rank_str .= join "|", keys %$disc, keys %$rank;
	$re_disc_rank_str .= ")";
	$re_disc_rank = qr/$re_disc_rank_str/;
	
	my $time = time;
	$g = {};
	
	my $dot_file = $base_path .$name. ".dot";
	open DOT, ">", $dot_file;
	
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
	print DOT qq/digraph "/ . $_->text . qq/: Paths" {\n\tnode [label="\\N", ordering="out"]\ngraph []\n/;
	
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
	my @discs_ranks = $text =~ /$re_disc_rank/g;
	return '' unless @discs_ranks;
	
	my @conj = $text =~ /$re_conj/g;
	my $conj = $conj[0];
	$conj //= ''; # empty string should be iff @discs == 1
	print "1 dics: " .$choice->text,"\n" if $conj and @discs_ranks == 1;
	print "More conj: " .$choice->text,"\n" if @conj > 1;
	my @disc_rank_values;
	push @disc_rank_values, $disc->{$_} // $rank->{$_} for @discs_ranks;
	$edge_attrs->{label}     = '"'. join( " $conj ", @disc_rank_values ) .'"';
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