package Util;

use strict;
use warnings FATAL => 'all';

use List::MoreUtils;
use Data::Dumper qw/Dumper/;

#-------------------------------------------------------------------------------

# Params:
#   combat element - XML::Twig::Elt object
#
# Extract enemy name and its CS and EP from a combat element.
# The next function can be easily modified to cover the functionality of this
# function. So this one is kept here only for its simplicity.
#
# Returns:
#   string representing one row in a future graphviz record
sub handle_combat {
    my ($enemy_str, $CS, $EP) = shift()->children_text();
    return sprint_enemy( pretty_sprint($enemy_str), { CS => $CS, EP => $EP } );
}

# Params:
#   array of combat elements - XML::Twig::Elt objects
#
# Magical version of previous function. It partitions combat elements to chunks
# of two which it sprints side by side. It preserves the order of elements except
# it prints element with the longest name last and on a separate row when there
# is odd number of elements.
#
# Returns:
#   array of strings each representing one row in a future graphviz record
sub handle_combats {
	my %combat; # storage for combat data
	my @enemies; # determines the order of elements - should be same as on input
	my $longest_enemy_str = "";

	for my $combat ( @_ ) { # feed %combat and @enemies
		my ($enemy_str, $CS, $EP) = $combat->children_text();
		$longest_enemy_str = $enemy_str
			if length $enemy_str >= length $longest_enemy_str;
		push @enemies, $enemy_str;
		$combat{$enemy_str} = { CS => $CS, EP => $EP };
	}
	@enemies = # move $longest_enemy_str to the end of @enemies
		map { @$_ } List::MoreUtils::part { $_ eq $longest_enemy_str } @enemies
		if @enemies % 2;

	my @rows; # array of rows of future record
	if ( @enemies == 2 ) { # don't pretty_sprint in case of 2 combats
		push @rows, sprint_enemy( $_, $combat{$_} ) for @enemies;
	} else {
		my $it = List::MoreUtils::natatime 2, @enemies;
		while ( my @enemy_pair = $it->() ) {
			push @rows,
				"{{" . join( "}|{",
					map( sprint_enemy( pretty_sprint($_), $combat{$_} ), @enemy_pair )
				) . "}}";
		}
	}
	return @rows;
}

# Params:
#   string, hashref with keys CS and EP
sub sprint_enemy {
	my ( $enemy_str, $enemy ) = @_;
	return $enemy_str. "|{" .$enemy->{CS}. "|" .$enemy->{EP}. "}";
}

#-------------------------------------------------------------------------------

# Params:
#   para element - XML::Twig::Elt object
#   dictionary object specific to particular book - Dictionary::* object
#
# Find gained items in the text. Apply heuristic that when an item is mentioned
# it is gained in this element iff there is also 'Action Chart' and 'Special Item'
# or the element is <li>.
# There are few exceptions to this rule, though, which must be handled individually.
#
# Returns:
#   array of found items
sub find_items {
	my ($para_or_li, $dict_obj) = @_;
	my $is_li = $para_or_li->tag eq "li";
	my $text = $para_or_li->xml_string;
	my $re_item = $dict_obj->re_item;

	my @items = $text =~ /($re_item)/g; # regexp is of the form (x|y|...)
	if ( @items and
		( $is_li or $text =~ /Action Chart/ and $text =~ /Special Item/ )
	) {
		return @items;
	} else {
		return ();
	}
}

#-------------------------------------------------------------------------------

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

	my $text = $choice->xml_string;

	# tag indicating to skip next choice item if preceded by negation
	my $skip_choice_item = 0;
	my @choice_string;
	my $curr_conj = 0; # really means undef, but the checks are easier this way
	# default conj will be printed instead of commas in the choice text
	my $default_conj = ' and ';

	# dirait = DIsc RAnk ITem
	my $dirait = $dict_obj->dirait;
	my $rank = $dict_obj->rank;
	my $re_choice = $dict_obj->re_choice;

	# find choice items (disc, ranks) in choice and put corresponding
	# conjunction as a value in a hash (indexed by ordering of choice items)
	while ( $text =~ /($re_choice)/g ) { # regexp is of the form (x|y|...)
		if ( exists $dirait->{$1} ) {
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
			if ( @choice_string and exists $rank->{ $choice_string[-1] } and
				# \G matches the position of last successful match
				$text =~ /\G((lower|less|below)|higher|more|above)/gc ) {
				push @choice_string, defined $2 ? '-' : '+';
			}
		}
	}

	return '' unless @choice_string;

	if ( ( grep { exists $rank->{$_} } @choice_string ) > 1 ) {
		die "Unexpected condition when more ranks present" if @choice_string != 3;
		$choice_string[1] = '-';
	}

# 	print $text . $default_conj . "\n";

	my @choice_string_values;
	# array elements are either choice items (abbrev them),
	# conjs (print them as is) or undef (print default conj)
	for my $token ( @choice_string ) {
		$token ||= $default_conj;
		push @choice_string_values, $dirait->{$token} // $token;
	}

# 	print $text . "\n" if @choice_string_values > 3;
	return {
		label     => '"' . join( '', @choice_string_values ) . '"',
		color     => 'green',
		fontcolor => 'green',
	}
}

#-------------------------------------------------------------------------------

# Params:
#   string
#
# In a longer string replace a space closest to the middle with a newline.
#
# Returns:
#   string
sub pretty_sprint {
	my $text = shift;
	my $length = length $text;
	return $text if $length < 13;

	my $middle = (1 + $length)/2;
	my $best_pos = 0;
	while ( $text =~ / /g ) {
		my $pos = pos $text;
		$best_pos = $pos if abs($middle - $pos) <= abs($middle - $best_pos);
	}
	substr $text, $best_pos, 0, "\\n" if $best_pos;
	return $text;
}

1;