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

my $dbh = dbh();

my @rows;
my $sth = $dbh->prepare("SELECT symbol, name FROM symbol WHERE type='index'");
$sth->execute();
while (my ($s, $n) = $sth->fetchrow_array) {
    my $row = { symbol => $s, name => $n };

    my @history;
    my $history_sth = $dbh->prepare("SELECT * FROM stock_history WHERE symbol = ? ORDER BY date DESC LIMIT 91");
    $history_sth->execute($s);
    while (my $h = $history_sth->fetchrow_hashref) { push @history, $h }

    $row->{history} = \@history;
    push @rows, $row;
}

my $tt2 = Template->new({
    INCLUDE_PATH => "$Bin/templates",
    INTERPOLATE  => 0,
    POST_CHOMP   => 1,
    PRE_CHOMP    => 1
});
$tt2->process("index_history_data.tt2", {
    rows  => \@rows
}, "$Bin/../data/index_history_data.html") or die $tt2->error();