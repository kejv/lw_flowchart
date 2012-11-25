#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Dictionary::Kai;
use Dictionary::Magnakai;
use Dictionary::Grandmaster;

for my $type ( 'Kai', 'Magnakai', 'Grandmaster' ) {
	my $dict_obj = eval "Dictionary::$type->new";
	open OUT, ">", $type . ".leg";
	for my $obj_name ( 'disc', 'rank', 'item' ) {
		my $obj = $dict_obj->$obj_name;
		my $obj_switched = { map { $obj->{$_} => $_ } keys $obj };
		for my $key ( sort keys $obj_switched ) {
			printf OUT "%-6s%s\n", $key, $obj_switched->{$key};
		}
		print OUT "\n";
	}
	close OUT;
}