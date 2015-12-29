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
use List::Util qw/sum/;

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

    ## M25 均线
    my @h25 = @history[0..24];
    @h25 = map { $_->{close} } @h25;
    my $total = sum @h25;
    my $ma25  = $total / 25;
    $row->{BIAS25} = int(($history[0]->{close} - $ma25) * 10000 / $ma25) / 100;

    my @h30 = @history[0..29];
    @h30 = map { $_->{close} } @h30;
    $total = sum @h30;
    my $ma30 = $total / 30;
    # $row->{BIAS30} = int(($history[0]->{close} - $ma30) * 10000 / $ma30) / 100;

    my @h5 = @history[0..4];
    @h5 = map { $_->{close} } @h5;
    $total = sum @h5;
    my $ma5 = $total / 5;
    # my @h60 = @history[0..59];
    # @h60 = map { $_->{close} } @h60;
    # $total = sum @h60;
    # my $ma60 = int(100 * $total / 60) / 100;

    $row->{MA5_30} = int(($ma5 - $ma30) * 10000 / $ma30) / 100;

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