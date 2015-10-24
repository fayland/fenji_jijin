#!/usr/bin/perl

use strict;
use warnings;
use v5.10;
use LWP::UserAgent;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Win qw/dbh/;
use Data::Dumper;
use Text::CSV;
use Encode;
use Try::Tiny;

my $ua = LWP::UserAgent->new;
my $dbh = dbh();

mkdir("$Bin/../data/xls") unless -d "$Bin/../data/xls";

my $insert_sth = $dbh->prepare("INSERT IGNORE INTO stock (symbol, name, market) VALUES (?, ?, ?)");

my $file = "$Bin/../data/csv/all.csv";
unless (-e $file) {
    my $url = "http://218.244.146.57/static/all.csv";
    say "# get $url";
    $ua->get($url, ':content_file' => $file);
}

my $csv = Text::CSV->new( { binary => 1 } )  # should set binary attribute.
    or die "Cannot use CSV: ".Text::CSV->error_diag();

open(my $fh, '<', $file) or die;
while ( my $row = $csv->getline( $fh ) ) {
    my $code = $row->[0];
    my $name = $row->[1];
    next unless $code =~ /^\d{6}$/;

    try { $name = encode('utf8', decode('gbk', $name)); };
    say $code . '-' . $name;

    my $market;
    $market = 'sh' if $code =~ /^6/;
    $market = 'sz' if $code =~ /^[03]/;

    $insert_sth->execute($code, $name, $market);
}
$csv->eof or $csv->error_diag();
close $fh;

