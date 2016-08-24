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
    next unless @history;

    ## 量能分析
    my @h30 = @history[0..29];
    @h30 = map { $_->{volume} } @h30;
    my $total = sum @h30;
    my $vol30  = $total / 30;
    $row->{vol30} = $vol30;

    my @h60 = @history[0..59];
    @h60 = map { $_->{volume} } @h60;
    $total = sum @h60;
    my $vol60  = $total / 60;
    $row->{vol60} = $vol60;

    $row->{history} = \@history;

    push @rows, $row;
}

my $tt2 = Template->new({
    INCLUDE_PATH => "$Bin/templates",
    INTERPOLATE  => 0,
    POST_CHOMP   => 1,
    PRE_CHOMP    => 1
});
$tt2->process("analysis_index_history.tt2", {
    rows  => \@rows
}, "$Bin/../data/analysis_index_history.html") or die $tt2->error();