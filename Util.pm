package Util;

use strict;
use warnings FATAL => 'all';

use Data::Dumper qw/Dumper/;

# Params:
#   choice element - XML::Twig::Elt object
#   dictionary object specific to particular book - Dictionary::* object
#
# Find various conditions for the choice, e.g. possesion of items, disciplines
# and reached rank
#
# Returns:
#   edge_attrs hashref
sub find_conditions {
	my ($choice, $dict_obj) = @_;

	my $text = $choice->text;
	# tag indicating to skip next choice item if preceded by negation
	my $skip_choice_item = 0;
	my @choice_items;
	my %conj_pos;
	my $disc = $dict_obj->disc;
	my $rank = $dict_obj->rank;
	my $re_choice = $dict_obj->re_choice;

	# find choice items (disc, ranks) in choice and put corresponding
	# conjunction as a value in a hash (indexed by ordering of choice items)
	while ( $text =~ /$re_choice/og ) { # regexp is of the form (x|y|...)
		if ( exists $disc->{$1} or exists $rank->{$1} ) {
			if ( $skip_choice_item ) {
				$skip_choice_item = 0;
			} else {
				push @choice_items, $1;
			}
		} elsif ( exists $dict_obj->neg_conj->{$1} ) { # negative means to skip next disc_rank
			$skip_choice_item = 1;
		} elsif ( @choice_items ) { # ignore conjunctions before first disc_rank
			# possibly rewrite existing value so that only last one is valid
			$conj_pos{ scalar @choice_items } = $1;
		}
	}

	return '' unless @choice_items;

	for ( keys %conj_pos ) { # ignore conjunctions after last disc_rank
		delete $conj_pos{$_} unless $_ < @choice_items;
	}
	# defalut conj will be printed instead of commas in the choice text
	my $default_conj = ( grep { $_ eq ' or ' } values %conj_pos ) ? ' or ' : ' and ';
	print $text . $default_conj . "\n";

	# get the abbrevs for the choice items
	my @choice_items_values;
	push @choice_items_values, $disc->{$_} // $rank->{$_} for @choice_items;
	my $label = $choice_items_values[0];
	# join choice items together using conjs
	for ( 1 .. $#choice_items_values ) {
		$label .= $conj_pos{$_} // $default_conj;
		$label .= $choice_items_values[$_];
	}

	print $text . "\n" if @choice_items_values > 2;
	return {
		label     => '"' .$label. '"',
		color     => 'green',
		fontcolor => 'green',
	}
}

1;