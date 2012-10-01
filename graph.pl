#!/usr/bin/perl

use v5.10;
use strict;
use warnings FATAL => 'all';

use Dictionary::Kai;
use Dictionary::Magnakai;
use Dictionary::Grandmaster;
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

for (@files) {
	my ($name, $book_no) = m|((\d+)\w+)\..+$|;
# 	print $book_no, $name;

	my $dict_obj; # book specific (rank-, discpline-dictionoaries, regexs etc.)
	given ( $book_no ) {
		when ( 1  <= $_ and $_ <= 5  ) { $dict_obj = new Dictionary::Kai }
		when ( 6  <= $_ and $_ <= 12 ) { $dict_obj = new Dictionary::Magnakai }
		when ( 13 <= $_ and $_ <= 20 ) { $dict_obj = new Dictionary::Grandmaster }
		default { print "FIXME: book > 20\n"; next }
	}

	my $time = time;

	my $dot_file = $base_path .$name. ".dot";
	open DOT, ">", $dot_file;

	$time = time;
	my $g = {}; # explicitly define as hashref in order to use it in a closure
	XML::Twig->new(
		twig_roots => {
			'/gamebook/meta/title' => \&title,
			'section[ @class="numbered" and @id=~/sect/ ]' =>
				sub { section(@_, $dict_obj, $g) },
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
	
	my %in_vertices;
	for ( values $g ) {
		undef $in_vertices{$_} for @$_;
	}
	print "No_in_vertices: ";
	print grep { not exists $in_vertices{$_} } (1..350);
	print "\n";
	print "No_out_vertices: ";
	print grep { not exists $g->{$_} } (1..350);
	print "\n--------------------------------------------------------\n";
}

# <STDIN>;

#-------------------------------------------------------------------------------

# init .dot file
sub title {
	print DOT qq/digraph "/ . $_->text . qq/: Paths" {\n\tnode [label="\\N"]\n/;
# 	print DOT qq/\tnode [ordering="out"]\n/;

	$_->purge;
}

sub section {
	my ($t, $elt, $dict_obj, $g) = @_;
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
		for my $choice ( @choices ) {
			my $attr_idref = $choice->att('idref');
			if ( defined $attr_idref ) {
				my ($idref) = $attr_idref =~ /sect(\d+)/;
				my %edge_attrs;
				push @{ $g->{$id} }, $idref;

				find_disc_rank($choice, \%edge_attrs, $dict_obj);

				print_edge($id, $idref, %edge_attrs); 
			} elsif ( @choices == 1 ) {
				print "Death? $id\n";
				$node_attrs{color} = 'crimson';
				$node_attrs{shape} = 'invtriangle';
			} else {
				if ( @footnotes ) {
					print "Riddle with more choices? $id\n"; # correct, 9/314?, answer
				} else {
					print "Death with more choices? $id\n";
				}
			}
		}
	} elsif ( @footnotes ) {
		print "Riddle? $id\n";
		$node_attrs{color} = 'orange';
		$node_attrs{shape} = 'triangle';
	} else {
		print "Death? No choice or footnote: $id\n";
		$node_attrs{color} = 'crimson';
		$node_attrs{shape} = 'invtriangle';
	}

	print_node($id, %node_attrs);

	$elt->purge;
}

sub find_disc_rank {
	my ($choice, $edge_attrs, $dict_obj) = @_;

	my $text = $choice->text;
	my $skip_disc_rank = 0;
	my @discs_ranks;
	my %conj_pos;
	my $disc = $dict_obj->disc;
	my $rank = $dict_obj->rank;
	my $re_choice = $dict_obj->re_choice;

	# find choice items (disc, ranks) in choice and put corresponding
	# conjunction as a value in a hash (indexed by ordering of choice items)
	while ( $text =~ /$re_choice/og ) { # regexp is of the form (x|y|...)
		if ( exists $disc->{$1} or exists $rank->{$1} ) {
			if ( $skip_disc_rank ) {
				print $text . "\n";
				$skip_disc_rank = 0;
			} else {
				push @discs_ranks, $1;
			}
		} elsif ( exists $dict_obj->neg_conj->{$1} ) { # negative means to skip next disc_rank
			$skip_disc_rank = 1;
		} elsif ( @discs_ranks ) { # ignore conjunctions before first disc_rank
			# possibly rewrite existing value so that only last one is valid
			$conj_pos{ scalar @discs_ranks } = $1;
		}
	}

	return '' unless @discs_ranks;

	for ( keys %conj_pos ) { # ignore conjunctions after last disc_rank
		delete $conj_pos{$_} unless $_ < @discs_ranks;
	}
	# defalut conj will be printed instead of commas in the choice text
	my $default_conj = ( grep { $_ eq ' or ' } values %conj_pos ) ? ' or ' : ' and ';
	print $text . $default_conj . "\n";

	# get the abbrevs for the choice items
	my @disc_rank_values;
	push @disc_rank_values, $disc->{$_} // $rank->{$_} for @discs_ranks;
	my $label = $disc_rank_values[0];
	# join choice items together using conjs
	for ( 1 .. $#disc_rank_values ) {
		$label .= $conj_pos{$_} // $default_conj;
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