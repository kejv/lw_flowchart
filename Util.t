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
		q[<choice idref="sect239">If you have the Kai Discipline of Healing, a healing potion or some Laumspur, and you want to try to save the man<ch.apos/>s life, <link-text>turn to 239</link-text>.</choice>]
		    => q["Hea"],
		q[<choice idref="sect159">If you do not have this Special Item or this Discipline and Kai Rank, dive into the tall crops and hide by <link-text>turning to 159</link-text>.</choice>]
		    => undef,
		q[<choice idref="sect332">If you wish to give chase and have either the Kai Discipline of Tracking or Hunting, <link-text>turn to 332</link-text>.</choice>]
		    => q["Tra or Hun"],
		q[<choice idref="sect124">If you have the Kai Discipline of Sixth Sense, but have not yet reached the Kai rank of Guardian, <link-text>turn to 124</link-text>.</choice>]
		    => q["SiS"],
		q[<choice idref="sect164">If you do not possess an Effigy but do possess the Sommerswerd, <link-text>turn to 164</link-text>.</choice>]
		    => q["Som"],
		q[<choice idref="sect156">If you have the Kai Discipline of Animal Kinship or if you have reached the Kai rank of Aspirant (you are skilled in six Kai Disciplines) or above, <link-text>turn to 156</link-text>.</choice>]
		    => q["AnK or 2+"],
	},
	Magnakai => {
		q[<choice idref="sect80">If you possess a Kalte Firesphere or a Torch and a Tinderbox, <link-text>turn to 80</link-text>.</choice>]
		    => q["Fsp"],
		q[<choice idref="sect258">If you have the Magnakai Discipline of Huntmastery and have reached the rank of Principalin or more <link-text>turn to 258</link-text>.</choice>]
		    => q["Hma and 9+"],
		q[<choice idref="sect309">If you possess the Magnakai Discipline of Pathsmanship and have reached the rank of Scion-kai, or if you possess the Magnakai Discipline of Animal Control, <link-text>turn to 309</link-text>.</choice>]
		    => q["Pma and 11 or AnC"],
		q[<choice idref="sect5">If you have neither a Meal nor the Magnakai Discipline of Psi-surge, you must stand and fight the creature; <link-text>turn to 5</link-text>.</choice>]
		    => undef,
		q[<choice idref="sect4">If you possess the Magnakai Discipline of Huntmastery, Pathsmanship, or Divination, <link-text>turn to 4</link-text>.</choice>]
		    => q["Hma or Pma or Div"],
		q[<choice idref="sect297">If you do not have the power of Psi-surge, or if you have not yet reached the rank of Primate, <link-text>turn to 297</link-text>.</choice>]
		    => undef,
		q[<choice idref="sect257">If you have yet to reach the rank of Primate, or you do not possess the skill of Psi-surge, <link-text>turn to 257</link-text>.</choice>]
		    => undef,
		q[<choice idref="sect325">If you do not possess this skill, or have yet to reach the Magnakai rank of Tutelary, <link-text>turn to 325</link-text>.</choice>]
		    => undef,
	},
	Grandmaster => {
		q[<choice idref="sect174">If you possess Assimilance or Grand Huntmastery, <link-text>turn to 174</link-text>.</choice>]
		    => q["Asm or GHm"],
		q[<choice idref="sect72">If you possess Assimilance, and have attained the rank of Kai Grand Guardian or higher, <link-text>turn to 72</link-text>.</choice>]
		    => q["Asm and 14+"],
		q[<choice idref="sect86">If you possess Kai-alchemy or Grand Nexus, and wish to use one of these Disciplines, <link-text>turn to 86</link-text>.</choice>]
		    => q["Kal or GNe"],
		q[<choice idref="sect234">If you possess Kai-surge, have reached the rank of Kai Grand Guardian or higher, and wish to make use of this Discipline, <link-text>turn to 234</link-text>.</choice>]
		    => q["Ksu and 14+"],
		q[<choice idref="sect15">If you possess Telegnosis, and have reached the rank of <!--ERRTAG-RE-133768-->Sun Lord or higher<!--/ERRTAG-RE-133768-->, <link-text>turn to 15</link-text>.</choice>]
		    => q["Tel and 16+"],
		q[<choice idref="sect49">If you possess Telegnosis, and have reached the rank of Sun Lord or higher, or if you possess the Discipline of Grand Pathsmanship, <link-text>turn to 49</link-text>.</choice>]
		    => q["Tel and 16+ or GPm"],
		q[<choice idref="sect86">If you possess Kai-alchemy but have yet to reach this level of Kai Mastery, <link-text>turn to 86</link-text>.</choice>]
		    => q["Kal"],
		q[<choice idref="sect131">If you possess Kai-screen but have yet to attain the Kai rank of Sun Thane, <link-text>turn to 131</link-text>.</choice>]
		    => q["Ksc"],
		q[<choice idref="sect146">If you possess Kai-alchemy (and wish to use it), but have yet to attain the rank of Kai Grand Crown, <link-text>turn to 146</link-text>.</choice>]
		    => q["Kal"],
		q[<choice idref="sect156">If you do not possess a Bow, or this skill, or if you have yet to attain the rank of Sun Lord, <link-text>turn to 156</link-text>.</choice>]
		    => undef,
		q[<choice idref="sect187">If your current level of Kai rank is Sun Knight or lower, <link-text>turn to 187</link-text>.</choice>]
		    => q["15-"],
		q[<choice idref="sect82">If your current level of Kai rank is Grand Crown or higher, <link-text>turn to 82</link-text>.</choice>]
		    => q["19+"],
		q[<choice idref="sect219">If your current level of Kai rank is between Grand Thane and Sun Lord, <link-text>turn to 219</link-text>.</choice>]
		    => q["18-16"],
		q[<choice idref="sect338">If you do not have a Bow, do not possess Kai-alchemy, or have yet to reach the required Kai rank, <link-text>turn instead to 338</link-text>.</choice>]
		    => undef,
		q[<choice idref="sect114">If you do not have a Bow, the Discipline of Grand Nexus, or if you have yet to attain this higher level of Kai Mastery, <link-text>turn to 114</link-text>.</choice>]
		    => undef,
		q[ <choice idref="sect306">If you do not possess Assimilance, have yet to attain the required level of Kai rank, or do not possess either Special Item (or have chosen not to use it), <link-text>turn instead to 306</link-text>.</choice>]
		    => undef,
		q[<choice idref="sect111">If you have not yet attained this level of Kai rank but you do possess a Rope, <link-text>turn to 111</link-text>.</choice>]
		    => undef,
		q[<choice idref="sect30">If you have yet to attain this level of Kai rank and you do not possess a Rope, <link-text>turn instead to 30</link-text>.</choice>]
		    => undef,
	},
};

my $tests_run = 1;
for my $level ( keys $choices ) {
	$tests_run += keys $choices->{$level};
}
plan tests => $tests_run;

my $dict_obj;
my $t = new XML::Twig;
for my $level ( keys $choices ) {
	$dict_obj = eval "new Dictionary::$level";
	for ( keys $choices->{$level} ) {
		my $choice = $t->parse($_)->root;
		is( Util::find_conditions($choice, $dict_obj)->{label},
			$choices->{$level}{$_}, "$level: choice conditions" );
	}
}
