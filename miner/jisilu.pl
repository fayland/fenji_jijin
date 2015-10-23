#!/usr/bin/perl

use strict;
use warnings;
use v5.10;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Win qw/dbh/;
use Encode;
use JSON;
use Data::Dumper;
use Template;

my @d = localtime();
my $today = sprintf('%04d-%02d-%02d', $d[5] + 1900, $d[4] + 1, $d[3]);

## get jisilu data into hash
open(my $fh, '<', "$Bin/../data/jisilu.json");
my $content = do { local $/; <$fh> };
close($fh);

my %data;
my $data = decode_json( encode('utf8', $content) );
foreach my $x (@{$data->{rows}}) {
    $data{$x->{id}} = $x->{cell};
}

open($fh, '<', "$Bin/../data/jisilu_A.json");
$content = do { local $/; <$fh> };
close($fh);

my %dataA;
$data = decode_json( encode('utf8', $content) );
foreach my $x (@{$data->{rows}}) {
    $dataA{$x->{id}} = $x->{cell};
}

# all combs
my @combs;
my $sth = dbh()->prepare("SELECT * FROM fenji_comb");
$sth->execute();
while (my $r = $sth->fetchrow_hashref) {
    push @combs, $r;
}

my $tt2 = Template->new({
    INCLUDE_PATH => $Bin,
    INTERPOLATE  => 1,               # expand "$var" in plain text
    POST_CHOMP   => 1,               # cleanup whitespace
});
$tt2->process("jisilu.tt2", {
    combs => \@combs,
    data  => \%data,
    dataA => \%dataA,
}, "$Bin/../data/jisilu.html") or die $tt2->error();