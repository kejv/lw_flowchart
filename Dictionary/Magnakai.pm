package Dictionary::Magnakai;

use Moose;

extends 'Dictionary::Kai';

sub _build_disc {
	{
		'Weaponmastery'  => 'Wma',
		'Animal Control' => 'AnC',
		'Curing'         => 'Cur',
		'Invisibility'   => 'Inv',
		'Huntmastery'    => 'Hma',
		'Pathsmanship'   => 'Pma',
		'Psi-surge'      => 'Psu',
		'Psi-screen'     => 'Psc',
		'Nexus'          => 'Nex',
		'Divination'     => 'Div',
	}
}

sub _build_rank {
	{
		'Primate'     => 7,
		'Tutelary'    => 8,
		'Principalin' => 9,
		'Mentora'     => 10,
		'Scion-kai'   => 11,
		'Archmaster'  => 12,
	}
}

sub _build_item {
	my $self = shift;
	{
		'Silver Bow of Duadon' => 'SBD',
		'Helshezag'            => 'Hel',
		'Kagonite Chainmail'   => 'KCh',
		'Korlinium Scabbard'   => 'KSc',
		'Silver Bracers'       => 'SBr',
		'Psychic Ring'         => 'PsR',
		'Ironheart Broadsword' => 'IrB',
		'Bronin Vest'          => 'BrV',
		'Lodestone'            => 'Lst',
		'Grey Crystal Ring'    => 'GCR',
		'Zejar-dulaga'         => 'Z-d',
		'Invitation'           => 'Inv',
		'Silver Rod'           => 'SiR',
		'Platinum Amulet'      => 'PlA',
		'Silver Whistle'       => 'SiW',
	    %{ $self->SUPER::_build_item },
	}
}

no Moose;

1;