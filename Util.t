#!/usr/bin/perl

use Test::More;

use Dictionary::Kai;
use Dictionary::Magnakai;
use Dictionary::Grandmaster;

use Data::Dumper qw/Dumper/;
use XML::Twig;

BEGIN { use_ok('Util') }

my $choices = {
	Kai => {
		qq[<choice idref="sect239">If you have the Kai Discipline of Healing, a healing potion or some Laumspur, and you want to try to save the man<ch.apos/>s life, <link-text>turn to 239</link-text>.</choice>]
		    => qq["Hea"],
		qq[<choice idref="sect159">If you do not have this Special Item or this Discipline and Kai Rank, dive into the tall crops and hide by <link-text>turning to 159</link-text>.</choice>]
		    => undef,
		qq[<choice idref="sect332">If you wish to give chase and have either the Kai Discipline of Tracking or Hunting, <link-text>turn to 332</link-text>.</choice>]
		    => qq["Tra or Hun"],
		qq[<choice idref="sect124">If you have the Kai Discipline of Sixth Sense, but have not yet reached the Kai rank of Guardian, <link-text>turn to 124</link-text>.</choice>]
		    => qq["SiS"],
		qq[<choice idref="sect164">If you do not possess an Effigy but do possess the Sommerswerd, <link-text>turn to 164</link-text>.</choice>]
		    => undef,
	},
	Magnakai => {
		qq[<choice idref="sect80">If you possess a Kalte Firesphere or a Torch and a Tinderbox, <link-text>turn to 80</link-text>.</choice>]
		    => undef,
		qq[<choice idref="sect258">If you have the Magnakai Discipline of Huntmastery and have reached the rank of Principalin or more <link-text>turn to 258</link-text>.</choice>]
		    => qq["Hma and 9"],
		qq[<choice idref="sect309">If you possess the Magnakai Discipline of Pathsmanship and have reached the rank of Scion-kai, or if you possess the Magnakai Discipline of Animal Control, <link-text>turn to 309</link-text>.</choice>]
		    => qq["Pma and 11 or AnC"],
		qq[<choice idref="sect5">If you have neither a Meal nor the Magnakai Discipline of Psi-surge, you must stand and fight the creature; <link-text>turn to 5</link-text>.</choice>]
		    => undef,
		qq[<choice idref="sect4">If you possess the Magnakai Discipline of Huntmastery, Pathsmanship, or Divination, <link-text>turn to 4</link-text>.</choice>]
		    => qq["Hma or Pma or Div"]
	},
	Grandmaster => {
	    qq[<choice idref="sect174">If you possess Assimilance or Grand Huntmastery, <link-text>turn to 174</link-text>.</choice>]
	        => qq["Asm or GHm"],
		qq[<choice idref="sect72">If you possess Assimilance, and have attained the rank of Kai Grand Guardian or higher, <link-text>turn to 72</link-text>.</choice>]
		    => qq["Asm and 14"],
		qq[<choice idref="sect86">If you possess Kai-alchemy or Grand Nexus, and wish to use one of these Disciplines, <link-text>turn to 86</link-text>.</choice>]
		    => qq["Kal or GNe"],
		qq[<choice idref="sect234">If you possess Kai-surge, have reached the rank of Kai Grand Guardian or higher, and wish to make use of this Discipline, <link-text>turn to 234</link-text>.</choice>]
		    => qq["Ksu and 14"],
		qq[<choice idref="sect15">If you possess Telegnosis, and have reached the rank of <!--ERRTAG-RE-133768-->Sun Lord or higher<!--/ERRTAG-RE-133768-->, <link-text>turn to 15</link-text>.</choice>]
		    => qq["Tel and 16"],
		qq[<choice idref="sect49">If you possess Telegnosis, and have reached the rank of Sun Lord or higher, or if you possess the Discipline of Grand Pathsmanship, <link-text>turn to 49</link-text>.</choice>]
		    => qq["Tel and 16 or GPm"],
		qq[<choice idref="sect86">If you possess Kai-alchemy but have yet to reach this level of Kai Mastery, <link-text>turn to 86</link-text>.</choice>]
		    => qq["Kal"],
		qq[<choice idref="sect131">If you possess Kai-screen but have yet to attain the Kai rank of Sun Thane, <link-text>turn to 131</link-text>.</choice>]
		    => qq["Ksc"],
		qq[<choice idref="sect146">If you possess Kai-alchemy (and wish to use it), but have yet to attain the rank of Kai Grand Crown, <link-text>turn to 146</link-text>.</choice>]
		    => qq["Kal"],
	},
};

my $tests_run = 1;
my $dict_obj;
my $t = new XML::Twig;

for my $level ( keys $choices ) {
    $tests_run += keys $choices->{$level};
    
	$dict_obj = eval "new Dictionary::$level";
	for ( keys $choices->{$level} ) {
	    my $choice = $t->parse($_)->root;
	    is( Util::find_conditions($choice, $dict_obj)->{label},
			$choices->{$level}{$_}, "$level: choice conditions" );
	}
}

done_testing($tests_run);