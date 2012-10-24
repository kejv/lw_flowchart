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
		'Silver Bow of Duadon' => 'SBD',#+ 6/252
		'Helshezag'            => 'Hel',#/A
		'Kagonite Chainmail'   => 'KCh',#+ 12/63
		'Korlinium Scabbard'   => 'KSc',#/A
		'Silver Bracers'       => 'SBr',#/A
		'Psychic Ring'         => 'PsR',#/A
		'Ironheart Broadsword' => 'IrB',#/A -11/144
		'Bronin Vest'          => 'BrV',#/A
		'Lodestone'            => 'Lst',#/A
		'Grey Crystal Ring'    => 'GCR',#/A
		'Zejar-dulaga'         => 'Z-d',#/A
		'Invitation'           => 'Inv',#/A
		'Silver Rod'           => 'SiR',#/A
		'Platinum Amulet'      => 'PlA',#/A -20/296,89 (removed duplicates)
		'Silver Whistle'       => 'SiW',#/A
		'Ticket'               => 'Tic',#/A
		'Shield'               => 'Shi',#/A
		'Cess'                 => 'Ces',#/A
		'Silver Brooch'        => 'SiB',#/A
		'Map of Varetta'       => 'MoV',#/A
		'Skeleton Key'         => 'SkK',#/A
		'Gold Key'             => 'GoK',#/A
		'Bullwhip'             => 'Bwh',#/A
		'Medal'                => 'Med',#/A
		%{ $self->SUPER::_build_item },
	}
}

sub _build_default_item {
	{
	    6  => { 252 => [ 'Silver Bow of Duadon' ] },
	    11 => { 144 => [] },
	    12 => { 63  => [ 'Kagonite Chainmail' ] },
	}
}

no Moose;

1;
