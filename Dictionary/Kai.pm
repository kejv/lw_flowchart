package Dictionary::Kai;

use Moose;

extends 'Dictionary';

sub _build_disc {
	{
		'Camouflage'       => 'Cam',
		'Hunting'          => 'Hun',
		'Sixth Sense'      => 'SiS',
		'Tracking'         => 'Tra',
		'Healing'          => 'Hea',
		'Weaponskill'      => 'Wsk',
		'Mindshield'       => 'Msh',
		'Mindblast'        => 'Mbl',
		'Animal Kinship'   => 'AnK',
		'Mind Over Matter' => 'MOM',
	}
}

sub _build_rank {
	{
		'Aspirant' => 2,
		'Guardian' => 3,
		'Warmarn'  => 4, # Journeyman unused
		'Savant'   => 5,
	}
}

sub _build_item {
	my $self = shift;
	{
		'Sommerswerd'          => 'Som',
		'Magic Spear'          => 'MSp',
		'Effigy'               => 'Eff',
		'Dagger of Vashna'     => 'DoV',
		'Jewelled Mace'        => 'JeM',
		'Crystal Star Pendant' => 'CSP',
		'Silver Helm'          => 'SHe',
		'Firesphere'           => 'Fsp',
		'Glowing Crystal'      => 'GlC',
		'Silver Key'           => 'SiK',
	    %{ $self->SUPER::_build_item },
	}
}

no Moose;

1;