#!/usr/bin/perl

my %graph = ( A => {B=>1,C=>2}, B => {A=>1,C=>1}, C => {A=>1,B=>1} );

use Paths::Graph;

my $g = Paths::Graph->new(-origin=>"A",-destiny=>"C",-graph=>\%graph);

my @paths = $g->shortest_path();

for my $path (@paths) {
	print "Shortest Path:" . join ("->" , @$path) . " Cost:". $g->get_path_cost(@$path) ."\n";
}