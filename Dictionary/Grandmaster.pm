package Dictionary::Grandmaster;

use Moose;

extends 'Dictionary::Magnakai';

sub _build_disc {
	{
		'Grand Weaponmastery' => 'GWm',
		'Animal Mastery'      => 'AnM',
		'Deliverance'         => 'Del',
		'Assimilance'         => 'Asm',
		'Grand Huntmastery'   => 'GHm',
		'Grand Pathsmanship'  => 'GPm',
		'Kai-surge'           => 'Ksu',
		'Kai-screen'          => 'Ksc',
		'Grand Nexus'         => 'GNe',
		'Telegnosis'          => 'Tel',
		'Magi-magic'          => 'Mag',
		'Kai-alchemy'         => 'Kal',
	}
}

sub _build_rank {
	{
		'Kai Grand Guardian' => 14,
		'Sun Knight'         => 15,
		'Sun Lord'           => 16,
		'Sun Thane'          => 17,
		'Grand Thane'        => 18,
		'Grand Crown'        => 19,
		'Sun Prince'         => 20,
	}
}

sub _build_item {
	my $self = shift;
	{
		'Skarn-Ska'            => 'Ska',#/A
		'Blue Diamond'         => 'BlD',#+ 20/269
		'Black Amulet'         => 'BlA',#/A
		'Runic Disc'           => 'RuD',#/A
		'Black Token'          => 'BlT',#/A
		'Green Gem'            => 'GrG',#/A
		'Power Spike'          => 'PoS',#/A
		'Iron Disc'            => 'IrD',#/A
		'Onyx Key'             => 'OnK',#A +17/58, -17/192
		'Silver Seal'          => 'SiS',#/A ul
		'Bronze Disc'          => 'BrD',#/A
		'Map of Mogaruith'     => 'MoM',# +13/146
		'Statuette of Zagarna' => 'SoZ',#/A
		'Shamath<ch.apos/>s Potion'     => 'SaP',#A -20/256
		'Statuette of Sl<ch.ucirc/>tar' => 'SoS',#/A
		%{ $self->SUPER::_build_item },
	}
}

sub _build_default_item {
	{
		20 => { 256 => [], 269 => [ 'Blue Diamond' ] },
		17 => { 58 => [ 'Onyx Key' ], 192 => [] },
		13 => { 146 => [ 'Map of Mogaruith' ] },
	}
}

no Moose;

1;