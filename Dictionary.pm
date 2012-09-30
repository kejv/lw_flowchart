package Dictionary;

use Moose;

# ATTRIBUTES

for my $attr ( qw/disc rank neg_conj conj/ ) {
	my $builder = '_build_' . $attr;
	has $attr => (
		is => 'ro',
		isa => 'HashRef',
		lazy => 1,
		builder => $builder,
	);
}

has 're_choice' => (
	is => 'ro',
	isa => 'RegexpRef',
	lazy => 1,
	builder => '_build_re_choice',
);

# BUILDERS

sub _build_disc {
	{}
}

sub _build_rank {
	{}
}

sub _build_neg_conj {
	{
		' but '     => undef,
		' not '     => undef,
		' nor '     => undef,
		' neither ' => undef,
		' yet '     => undef,
	}
}

sub _build_conj {
	{
		' and ' => undef,
		' or '  => undef,
		%{ shift->neg_conj }
	}
}

sub _build_re_choice {
	my $self = shift;

	my $re = "(";
	$re .= join "|", map keys %{ $self->$_ }, qw/disc rank conj/;
	$re .= ")";

	return qr/$re/;
}

no Moose;

1;

