package Dictionary;

use Moose;

# ATTRIBUTES

for my $attr ( qw/disc rank item neg_conj conj dirait default_item/ ) {
	my $builder = '_build_' . $attr;
	has $attr => (
		is => 'ro',
		isa => 'HashRef',
		lazy => 1,
		builder => $builder,
	);
}

for my $attr ( qw/re_choice re_item/ ) {
	my $builder = '_build_' . $attr;
	has $attr => (
		is => 'ro',
		isa => 'RegexpRef',
		lazy => 1,
		builder => $builder,
	);
}

has book_no => (
	is => 'ro',
	isa => 'Int',
);

# BUILDERS

sub _build_disc {
	{}
}

sub _build_rank {
	{}
}

sub _build_item {
	{}
}

sub _build_dirait {
	my $self = shift;

	return {
		%{ $self->disc },
		%{ $self->rank },
		%{ $self->item },
	}
}

sub _build_neg_conj {
	{
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

sub _build_default_item {
	{}
}

sub _build_re_item {
	my $self = shift;

	my $re = join "|", keys %{ $self->item };
	return qr/$re/;
}

sub _build_re_choice {
	my $self = shift;

	my $re = join "|", map keys %{ $self->$_ }, qw/dirait conj/;
	return qr/$re/;
}

no Moose;

1;

