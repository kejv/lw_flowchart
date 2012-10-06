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
	my @choice_string;
	my $curr_conj = 0; # really means undef, but the checks are easier this way
	# defalut conj will be printed instead of commas in the choice text
	my $default_conj = ' and ';

	my $disc = $dict_obj->disc;
	my $rank = $dict_obj->rank;
	my $re_choice = $dict_obj->re_choice;

	# find choice items (disc, ranks) in choice and put corresponding
	# conjunction as a value in a hash (indexed by ordering of choice items)
	while ( $text =~ /$re_choice/g ) { # regexp is of the form (x|y|...)
		if ( exists $disc->{$1} or exists $rank->{$1} ) {
			if ( $skip_choice_item ) {
				$skip_choice_item = 0;
			} else {
			    # ignore any conj before first choice item
			    if ( @choice_string ) {
					push @choice_string, $curr_conj;
					$default_conj = $curr_conj if $curr_conj eq ' or ';
				}
				push @choice_string, $1;

				$curr_conj = 0;
			}
		} elsif ( exists $dict_obj->neg_conj->{$1} ) { # negative means to skip next choice item
			$skip_choice_item = 1;
		} else { # we have a non-negative conjunction
			$curr_conj = $1;
		}
	}

	return '' unless @choice_string;

	print $text . $default_conj . "\n";

	my @choice_string_values;
	# array elements are either choice items (abbrev them),
	# conjs (print them as is) or undef (print default conj)
	for my $token ( @choice_string ) {
		$token ||= $default_conj;
		push @choice_string_values, $disc->{$token} // $rank->{$token} // $token;
	}

	print $text . "\n" if @choice_string_values > 3;
	return {
		label     => '"' . join( '', @choice_string_values ) . '"',
		color     => 'green',
		fontcolor => 'green',
	}
}

1;