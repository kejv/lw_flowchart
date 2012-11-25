#!/usr/bin/perl

use v5.10;
use strict;
use warnings FATAL => 'all';

use Dictionary::Kai;
use Dictionary::Magnakai;
use Dictionary::Grandmaster;
use GraphAlgs;
use Util;

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
		when ( 1  <= $_ and $_ <= 5  ) {
			$dict_obj = Dictionary::Kai        ->new( { book_no => $book_no } )
		}
		when ( 6  <= $_ and $_ <= 12 ) {
			$dict_obj = Dictionary::Magnakai   ->new( { book_no => $book_no } )
		}
		when ( 13 <= $_ and $_ <= 20 ) {
			$dict_obj = Dictionary::Grandmaster->new( { book_no => $book_no } )
		}
		default { print "FIXME: book > 20\n"; next }
	}

	my $time = time;

	my $dot_file = $base_path .$name. ".dot";
	open DOT, ">", $dot_file;

	$time = time;
	my $g_edges = {}; # explicitly define as hashref in order to use it in a closure
	XML::Twig->new(
		twig_roots => {
			'/gamebook/meta/title' => \&title,
			'section[ @class="numbered" and @id=~/sect/ ]' =>
				sub { section(@_, $dict_obj, $g_edges) },
		}
	)->parsefile($_);
	print "Parsing: ". (time - $time) ."\n";
	print DOT "}"; # close dot file

	close DOT;
	
	$time = time;
# 	run join( " ", ("dot", "-T".$format, $dot_file, "-o".$base_path.$name.".".$format) );
	system "dot", "-T".$format, $dot_file, "-o".$base_path.$name.".".$format;
# 	run \@cmd;
	print "Dot: ". (time - $time) ."\n";
	
	$time = time;
	for my $SCC ( @{ GraphAlgs::strongly_connected_components($g_edges) } ) {
		print @$SCC,"\n" if @$SCC > 1;
	}
	print "SCC: ". (time - $time) ."\n";

	{
	use List::Util qw(max);

	my %in_vertices;
	for ( values $g_edges ) {
		undef $in_vertices{$_} for keys $_;
	}
	my $max_id = max keys %in_vertices;

	print "No_in_vertices: ";
	print grep { not exists $in_vertices{$_} } (1..$max_id);
	print "\n";
	print "No_out_vertices: ";
	print grep { not exists $g_edges->{$_} } (1..$max_id);
	print "\n--------------------------------------------------------\n";
	}
}

# <STDIN>;

#-------------------------------------------------------------------------------

# init .dot file
sub title {
	print DOT qq/digraph "/ . $_->text . qq/: Paths" {\n/;
# 	print DOT qq/\tnode [ordering="out"]\n/;
	print DOT qq/\tnode [label="\\N"]\n/;
	print DOT qq/\tgraph [margin=0.5]\n/;

	$_->purge;
}

sub section {
	my ($t, $elt, $dict_obj, $g_edges) = @_;
	
	# section number
	my $id = ( $elt->get_xpath('meta/title') )[0]->text;

	my @choices = $elt->get_xpath('data/choice');
	my @puzzles = $elt->get_xpath('data/puzzle');
	my @paras = $elt->get_xpath('data/p');
	my @ul_lis = $elt->get_xpath('data/ul/li');
	my @combats = $elt->get_xpath('data/combat');

	my $is_ill = $elt->get_xpath('data/illustration/meta/description');
	my $is_death = $elt->get_xpath('data/deadend');

	my $node_attrs = {};

	my $book_no = int $dict_obj->book_no;
	if ( $id == ( $book_no == 5 ? 400 : 350 ) ) {
		$node_attrs->{fillcolor} = 'gold';
		$node_attrs->{style} = 'filled';
	}
	if ( $is_ill ) {
		$node_attrs->{peripheries} = 2;
		$node_attrs->{color} = 'purple';
	}
	if ( $is_death ) {
		$node_attrs->{color} = 'crimson';
		$node_attrs->{shape} = 'invtriangle';
	}

	# handle combat
	my $handle_combat = do {
		given ( scalar @combats ) {
		    when ( 0 ) { sub { return () } }
		    when ( 1 ) { \&Util::handle_combat  }
		    default    { \&Util::handle_combats }
		}
	};
	my @combat_rows = $handle_combat->(@combats);

	# find items in text
	my @items = ();
	if ( exists $dict_obj->default_item->{$book_no}->{$id} ) {
		@items = @{ $dict_obj->default_item->{$book_no}->{$id} };
	} else {
		for my $para_or_li ( @paras, @ul_lis ) {
			push @items, Util::find_items($para_or_li, $dict_obj);
		}
	}
	# item can be there more times so return it only once
	my @uitems = map Util::pretty_sprint($_), keys %{ { map { $_ => 1 } @items } };

	if ( @uitems or @combat_rows ) {
		$node_attrs->{shape}     = 'Mrecord';
		$node_attrs->{margin}    = Util::qq_string( '0.11,0.03' );
		$node_attrs->{label}     = Util::qq_string( '{\N|' . join( '|', @combat_rows, @uitems ) . '}' );
		$node_attrs->{fontcolor} = 'blue' if @uitems;
	}

	print_node($id, $node_attrs) if %$node_attrs;

	# find idrefs in choices or puzzles
	for my $choice_or_puzzle ( @choices, @puzzles ) {
		my $idref_str = $choice_or_puzzle->att('idref') // $choice_or_puzzle->att('idrefs');
		my @attr_idrefs = split ' ', $idref_str if defined $idref_str;
		for ( @attr_idrefs ) {
			my ($idref) = /sect(\d+)/;
			$g_edges->{$id}{$idref} = {};

			my $edge_attrs = $choice_or_puzzle->tag eq "choice" ?
				Util::find_conditions($choice_or_puzzle, $dict_obj) :
				{ color => 'orange', fontcolor => 'orange' };

			print_edge($id, $idref, $edge_attrs);
		}
	}

	$elt->purge;
}

sub print_node {
	my ($id, $node_attrs) = @_;
	
	print DOT "\t$id " . sprint_attrs($node_attrs) . "\n";
}

sub print_edge {
	my ($id, $idref, $edge_attrs) = @_;
	
	print DOT "\t" .$id. " -> " .$idref;
	if ( %$edge_attrs ) {
		print DOT " [";
		print DOT join( ", ", map $_."=".$edge_attrs->{$_}, keys $edge_attrs );
		print DOT "]";
	}
	print DOT "\n";
}


sub sprint_attrs {
	my $attrs = shift;
	return "[" . join( ", ", map $_."=".$attrs->{$_}, keys $attrs ) . "]";
}
