#!/usr/bin/perl

## 指数变化分析

use strict;
use warnings;
use v5.10;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Win qw/dbh/;
use Encode;
use Data::Dumper;

my $dbh = dbh();

my $sth = $dbh->prepare("SELECT symbol, name FROM symbol WHERE type='index'");
$sth->execute();
while (my ($s, $n) = $sth->fetchrow_array) {
    say $s . ' ' . $n;

    my @history;
    my $history_sth = $dbh->prepare("SELECT * FROM history WHERE symbol = ? ORDER BY date DESC LIMIT 8");
    $history_sth->execute($s);
    while (my $h = $history_sth->fetchrow_hashref) { push @history, $h }

    say '1 Day: ' . sprintf('%.2f', ( 100 * ($history[0]->{close} - $history[1]->{close}) / $history[1]->{close} )) . '%';
    say '3 Day: ' . sprintf('%.2f', ( 100 * ($history[0]->{close} - $history[3]->{close}) / $history[3]->{close} )) . '%';
    say '5 Day: ' . sprintf('%.2f', ( 100 * ($history[0]->{close} - $history[5]->{close}) / $history[5]->{close} )) . '%';
    say '7 Day: ' . sprintf('%.2f', ( 100 * ($history[0]->{close} - $history[7]->{close}) / $history[7]->{close} )) . '%';
}