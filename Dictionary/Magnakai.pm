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

no Moose;

1;