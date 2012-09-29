package Dictionary;

# DISCIPLINES

our $kai_disc = {
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
};

our $magnakai_disc = {
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
};

our $grand_master_disc = {
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
};

# LEVELS OF TRAINING
# the value indicates number of book where you can first reach this rank

our $kai_rank = {
	'Aspirant' => 2,
	'Guardian' => 3,
	'Warmarn'  => 4, # Journeyman unused
	'Savant'   => 5,
};

our $magnakai_rank = {
	'Primate'     => 7,
	'Tutelary'    => 8,
	'Principalin' => 9,
	'Mentora'     => 10,
	'Scion-kai'   => 11,
	'Archmaster'  => 12,
};

our $grand_master_rank = {
	'Kai Grand Guardian' => 14,
	'Sun Knight'         => 15,
	'Sun Lord'           => 16,
	'Sun Thane'          => 17,
	'Grand Thane'        => 18,
	'Grand Crown'        => 19,
	'Sun Prince'         => 20,
};

# LOGICAL CONJUNCTIONS

our $conj = {
	' and ' => undef,
	' or '  => undef,
	' but ' => undef,
	' not ' => undef,
	' nor ' => undef,
	' neither ' => undef,
	' yet ' => undef,
};