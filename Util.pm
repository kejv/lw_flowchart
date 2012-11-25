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
    my ($enemy_str, $CS, $EP) = map $_->xml_string(), shift()->children();
    return sprint_enemy( { name => pretty_sprint($enemy_str), CS => $CS, EP => $EP } );
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
		push @rows, sprint_enemy( { name => elts2chars($_), %{ $combat{$_} } } )
			for @enemies;
	} else {
		my $it = List::MoreUtils::natatime 2, @enemies;
		while ( my @enemy_pair = $it->() ) {
			push @rows,
				"{{" . join( "}|{",
					map( sprint_enemy( { name => pretty_sprint($_), %{ $combat{$_} } } ),
						@enemy_pair )
				) . "}}";
		}
	}
	return @rows;
}

# Params:
#   hashref with keys name, CS and EP
sub sprint_enemy {
	my $enemy = shift;
	return $enemy->{name}. "|{" .$enemy->{CS}. "|" .$enemy->{EP}. "}";
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
	my $item = $dict_obj->item;
	my $neg_conj = $dict_obj->neg_conj;
	my $re_choice = $dict_obj->re_choice;

	# find choice conditions in choice element and put them in a array, separated
	# by conjunctions
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
		} elsif ( exists $neg_conj->{$1} ) { # negative means to skip next choice item
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

	return {} unless @choice_string;

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

	my $disc = $dict_obj->disc;
	my $color =
		( List::MoreUtils::any { exists $item->{$_} } @choice_string ) ? "blue" :
		( List::MoreUtils::any { exists $disc->{$_} } @choice_string ) ? "green" :
		"brown"; # default color for rank
	return {
		label     => qq_string( join( '', @choice_string_values ) ),
		color     => $color,
		fontcolor => $color,
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
	my $text = elts2chars( shift );
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

sub qq_string {
	return '"' .shift(). '"';
}

sub elts2chars {
	my $_ = shift;

	s|<ch.apos/>|&#39;|g; # apostrophe = single quotation mark
	s|<ch.nbsp/>|&#160;|g; # no-break space = non-breaking space, U+00A0 ISOnum
	s|<ch.iexcl/>|&#161;|g; # inverted exclamation mark, U+00A1 ISOnum
	s|<ch.cent/>|&#162;|g; # cent sign, U+00A2 ISOnum
	s|<ch.pound/>|&#163;|g; # pound sign, U+00A3 ISOnum
	s|<ch.curren/>|&#164;|g; # currency sign, U+00A4 ISOnum
	s|<ch.yen/>|&#165;|g; # yen sign = yuan sign, U+00A5 ISOnum
	s|<ch.brvbar/>|&#166;|g; # broken bar = broken vertical bar, U+00A6 ISOnum
	s|<ch.sect/>|&#167;|g; # section sign, U+00A7 ISOnum
	s|<ch.uml/>|&#168;|g; # diaeresis = spacing diaeresis, U+00A8 ISOdia
	s|<ch.copy/>|&#169;|g; # copyright sign, U+00A9 ISOnum
	s|<ch.ordf/>|&#170;|g; # feminine ordinal indicator, U+00AA ISOnum
	s|<ch.laquo/>|&#171;|g; # left-pointing double angle quotation mark = left pointing guillemet, U+00AB ISOnum
	s|<ch.not/>|&#172;|g; # not sign, U+00AC ISOnum
	s|<ch.shy/>|&#173;|g; # soft hyphen = discretionary hyphen, U+00AD ISOnum
	s|<ch.reg/>|&#174;|g; # registered sign = registered trade mark sign, U+00AE ISOnum
	s|<ch.macr/>|&#175;|g; # macron = spacing macron = overline = APL overbar, U+00AF ISOdia
	s|<ch.deg/>|&#176;|g; # degree sign, U+00B0 ISOnum
	s|<ch.plusmn/>|&#177;|g; # plus-minus sign = plus-or-minus sign, U+00B1 ISOnum
	s|<ch.sup2/>|&#178;|g; # superscript two = superscript digit two = squared, U+00B2 ISOnum
	s|<ch.sup3/>|&#179;|g; # superscript three = superscript digit three = cubed, U+00B3 ISOnum
	s|<ch.acute/>|&#180;|g; # acute accent = spacing acute, U+00B4 ISOdia
	s|<ch.micro/>|&#181;|g; # micro sign, U+00B5 ISOnum
	s|<ch.para/>|&#182;|g; # pilcrow sign  = paragraph sign, U+00B6 ISOnum
	s|<ch.middot/>|&#183;|g; # middle dot = Georgian comma = Greek middle dot, U+00B7 ISOnum
	s|<ch.cedil/>|&#184;|g; # cedilla = spacing cedilla, U+00B8 ISOdia
	s|<ch.sup1/>|&#185;|g; # superscript one = superscript digit one, U+00B9 ISOnum
	s|<ch.ordm/>|&#186;|g; # masculine ordinal indicator, U+00BA ISOnum
	s|<ch.raquo/>|&#187;|g; # right-pointing double angle quotation mark = right pointing guillemet, U+00BB ISOnum
	s|<ch.frac14/>|&#188;|g; # vulgar fraction one quarter = fraction one quarter, U+00BC ISOnum
	s|<ch.frac12/>|&#189;|g; # vulgar fraction one half = fraction one half, U+00BD ISOnum
	s|<ch.frac34/>|&#190;|g; # vulgar fraction three quarters = fraction three quarters, U+00BE ISOnum
	s|<ch.iquest/>|&#191;|g; # inverted question mark = turned question mark, U+00BF ISOnum
	s|<ch.Agrave/>|&#192;|g; # latin capital letter A with grave = latin capital letter A grave, U+00C0 ISOlat1
	s|<ch.Aacute/>|&#193;|g; # latin capital letter A with acute, U+00C1 ISOlat1
	s|<ch.Acirc/>|&#194;|g; # latin capital letter A with circumflex, U+00C2 ISOlat1
	s|<ch.Atilde/>|&#195;|g; # latin capital letter A with tilde, U+00C3 ISOlat1
	s|<ch.Auml/>|&#196;|g; # latin capital letter A with diaeresis, U+00C4 ISOlat1
	s|<ch.Aring/>|&#197;|g; # latin capital letter A with ring above = latin capital letter A ring, U+00C5 ISOlat1
	s|<ch.AElig/>|&#198;|g; # latin capital letter AE = latin capital ligature AE, U+00C6 ISOlat1
	s|<ch.Ccedil/>|&#199;|g; # latin capital letter C with cedilla, U+00C7 ISOlat1
	s|<ch.Egrave/>|&#200;|g; # latin capital letter E with grave, U+00C8 ISOlat1
	s|<ch.Eacute/>|&#201;|g; # latin capital letter E with acute, U+00C9 ISOlat1
	s|<ch.Ecirc/>|&#202;|g; # latin capital letter E with circumflex, U+00CA ISOlat1
	s|<ch.Euml/>|&#203;|g; # latin capital letter E with diaeresis, U+00CB ISOlat1
	s|<ch.Igrave/>|&#204;|g; # latin capital letter I with grave, U+00CC ISOlat1
	s|<ch.Iacute/>|&#205;|g; # latin capital letter I with acute, U+00CD ISOlat1
	s|<ch.Icirc/>|&#206;|g; # latin capital letter I with circumflex, U+00CE ISOlat1
	s|<ch.Iuml/>|&#207;|g; # latin capital letter I with diaeresis, U+00CF ISOlat1
	s|<ch.ETH/>|&#208;|g; # latin capital letter ETH, U+00D0 ISOlat1
	s|<ch.Ntilde/>|&#209;|g; # latin capital letter N with tilde, U+00D1 ISOlat1
	s|<ch.Ograve/>|&#210;|g; # latin capital letter O with grave, U+00D2 ISOlat1
	s|<ch.Oacute/>|&#211;|g; # latin capital letter O with acute, U+00D3 ISOlat1
	s|<ch.Ocirc/>|&#212;|g; # latin capital letter O with circumflex, U+00D4 ISOlat1
	s|<ch.Otilde/>|&#213;|g; # latin capital letter O with tilde, U+00D5 ISOlat1
	s|<ch.Ouml/>|&#214;|g; # latin capital letter O with diaeresis, U+00D6 ISOlat1
	s|<ch.times/>|&#215;|g; # multiplication sign, U+00D7 ISOnum
	s|<ch.Oslash/>|&#216;|g; # latin capital letter O with stroke = latin capital letter O slash, U+00D8 ISOlat1
	s|<ch.Ugrave/>|&#217;|g; # latin capital letter U with grave, U+00D9 ISOlat1
	s|<ch.Uacute/>|&#218;|g; # latin capital letter U with acute, U+00DA ISOlat1
	s|<ch.Ucirc/>|&#219;|g; # latin capital letter U with circumflex, U+00DB ISOlat1
	s|<ch.Uuml/>|&#220;|g; # latin capital letter U with diaeresis, U+00DC ISOlat1
	s|<ch.Yacute/>|&#221;|g; # latin capital letter Y with acute, U+00DD ISOlat1
	s|<ch.THORN/>|&#222;|g; # latin capital letter THORN, U+00DE ISOlat1
	s|<ch.szlig/>|&#223;|g; # latin small letter sharp s = ess-zed, U+00DF ISOlat1
	s|<ch.agrave/>|&#224;|g; # latin small letter a with grave = latin small letter a grave, U+00E0 ISOlat1
	s|<ch.aacute/>|&#225;|g; # latin small letter a with acute, U+00E1 ISOlat1
	s|<ch.acirc/>|&#226;|g; # latin small letter a with circumflex, U+00E2 ISOlat1
	s|<ch.atilde/>|&#227;|g; # latin small letter a with tilde, U+00E3 ISOlat1
	s|<ch.auml/>|&#228;|g; # latin small letter a with diaeresis, U+00E4 ISOlat1
	s|<ch.aring/>|&#229;|g; # latin small letter a with ring above = latin small letter a ring, U+00E5 ISOlat1
	s|<ch.aelig/>|&#230;|g; # latin small letter ae = latin small ligature ae, U+00E6 ISOlat1
	s|<ch.ccedil/>|&#231;|g; # latin small letter c with cedilla, U+00E7 ISOlat1
	s|<ch.egrave/>|&#232;|g; # latin small letter e with grave, U+00E8 ISOlat1
	s|<ch.eacute/>|&#233;|g; # latin small letter e with acute, U+00E9 ISOlat1
	s|<ch.ecirc/>|&#234;|g; # latin small letter e with circumflex, U+00EA ISOlat1
	s|<ch.euml/>|&#235;|g; # latin small letter e with diaeresis, U+00EB ISOlat1
	s|<ch.igrave/>|&#236;|g; # latin small letter i with grave, U+00EC ISOlat1
	s|<ch.iacute/>|&#237;|g; # latin small letter i with acute, U+00ED ISOlat1
	s|<ch.icirc/>|&#238;|g; # latin small letter i with circumflex, U+00EE ISOlat1
	s|<ch.iuml/>|&#239;|g; # latin small letter i with diaeresis, U+00EF ISOlat1
	s|<ch.eth/>|&#240;|g; # latin small letter eth, U+00F0 ISOlat1
	s|<ch.ntilde/>|&#241;|g; # latin small letter n with tilde, U+00F1 ISOlat1
	s|<ch.ograve/>|&#242;|g; # latin small letter o with grave, U+00F2 ISOlat1
	s|<ch.oacute/>|&#243;|g; # latin small letter o with acute, U+00F3 ISOlat1
	s|<ch.ocirc/>|&#244;|g; # latin small letter o with circumflex, U+00F4 ISOlat1
	s|<ch.otilde/>|&#245;|g; # latin small letter o with tilde, U+00F5 ISOlat1
	s|<ch.ouml/>|&#246;|g; # latin small letter o with diaeresis, U+00F6 ISOlat1
	s|<ch.divide/>|&#247;|g; # division sign, U+00F7 ISOnum
	s|<ch.oslash/>|&#248;|g; # latin small letter o with stroke, = latin small letter o slash, U+00F8 ISOlat1
	s|<ch.ugrave/>|&#249;|g; # latin small letter u with grave, U+00F9 ISOlat1
	s|<ch.uacute/>|&#250;|g; # latin small letter u with acute, U+00FA ISOlat1
	s|<ch.ucirc/>|&#251;|g; # latin small letter u with circumflex, U+00FB ISOlat1
	s|<ch.uuml/>|&#252;|g; # latin small letter u with diaeresis, U+00FC ISOlat1
	s|<ch.yacute/>|&#253;|g; # latin small letter y with acute, U+00FD ISOlat1
	s|<ch.thorn/>|&#254;|g; # latin small letter thorn, U+00FE ISOlat1
	s|<ch.yuml/>|&#255;|g; # latin small letter y with diaeresis, U+00FF ISOlat1
	s|<ch.ampersand/>|&amp;|g; # ampersand
	s|<ch.lsquot/>|&#8216;|g; # opening left quotation mark
	s|<ch.rsquot/>|&#8217;|g; # closing right quotation mark
	s|<ch.ldquot/>|&#8220;|g; # opening left double quotation mark
	s|<ch.rdquot/>|&#8221;|g; # closing right double quotation mark
	s|<ch.minus/>|&#8722;|g; # mathematical minus
	s|<ch.endash/>|&#8211;|g; # endash
	s|<ch.emdash/>|&#8212;|g; # emdash
	s|<ch.ellips/>|&#8230;|g; # ellipsis
	s|<ch.lellips/>|&#8230;|g; # left ellipsis, used at the beginning of edited material
	s|<ch.blankline/>|_______|g; # blank line to be filled in
	s|<ch.percent/>|&#37;|g; # percent sign
	s|<ch.thinspace/>|&#8201;|g; # small horizontal space for use between adjacent quotation marks - added mainly for LaTeX's sake
	s|<ch.frac116/>|1/16|g; # vulgar fraction one sixteenth = fraction on sixteenth
	s|<ch.plus/>|+|g; # mathematical plus

	s|<[^>]*>||g; # delete all remaining xml tags

	return $_;
}

1;