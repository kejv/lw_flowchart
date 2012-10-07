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
		'Skarn-Ska'         => 'Ska',
		'Blue Diamond'      => 'BlD',
		'Black Amulet'      => 'BlA',
		'Runic Disc'        => 'RuD',
		'Black Token'       => 'BlT',
		'Green Gem'         => 'GrG',
		'Power Spike'       => 'PoS',
		'Talisman of Ishir' => 'ToI',
		'Iron Disc'         => 'IrD',
		'Bronze Disc'       => 'BrD',
	    %{ $self->SUPER::_build_item },
	}
}

no Moose;

1;