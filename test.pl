#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Tarjan;

$, = ",";
my $g = { 1 => [2], 2 => [1] };

for my $SCC ( @{ Tarjan::strongly_connected_components($g) } ) {
	print @$SCC;
}