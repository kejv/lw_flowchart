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
		'Skarn-Ska'         => 'Ska',#/A
		'Blue Diamond'      => 'BlD',#+ 20/269
		'Black Amulet'      => 'BlA',#/A
		'Runic Disc'        => 'RuD',#/A
		'Black Token'       => 'BlT',#/A
		'Green Gem'         => 'GrG',#/A
		'Power Spike'       => 'PoS',#/A
		'Talisman of Ishir' => 'ToI',#/B
		'Iron Disc'         => 'IrD',#/A
		'Bronze Disc'       => 'BrD',#/A
	    %{ $self->SUPER::_build_item },
	}
}

sub _build_default_item {
	{
	    20 => { 269 => [ 'Blue Diamond' ] },
	}
}

no Moose;

1;