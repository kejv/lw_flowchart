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
		'Sommerswerd'          => 'Som',#+ 123
		'Magic Spear'          => 'MSp',#/A
		'Effigy'               => 'Eff',#/A
		'Dagger of Vashna'     => 'DoV',#/A
		'Jewelled Mace'        => 'JeM',#/A
		'Crystal Star Pendant' => 'CSP',#+ 349
		'Silver Helm'          => 'SHe',#/A
		'Firesphere'           => 'Fsp',#/A
		'Glowing Crystal'      => 'GlC',#/A
		'Ornate Silver Key'    => 'OSK',#+ 3/280
		'Blue Stone Triangle'  => 'BST',#/A +3/84, 309
		'Blue Stone Disc'      => 'BSD',#/A
		'Copper Key'           => 'CoK',#/A
		'Diamond'              => 'Dia',#/A
		'Onyx Medallion'       => 'OnM',#/A
		'Scroll'               => 'Scr',#/A
		'Black Crystal Cube'   => 'BCC',#/A
		%{ $self->SUPER::_build_item },
	}
}

sub _build_default_item {
	{
		1 => { 349 => [ 'Crystal Star Pendant' ] },
		2 => { 123 => [ 'Sommerswerd' ] },
		3 => {
			84   => [ 'Blue Stone Triangle' ],
			280  => [ 'Ornate Silver Key' ],
			309  => [ 'Blue Stone Triangle', 'Firesphere' ],
		},
	}
}

no Moose;

1;
