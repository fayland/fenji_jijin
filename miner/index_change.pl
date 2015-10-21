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

open(my $fh, '>', "$Bin/../data/index_change.html");
print $fh qq~<table id="table_index_change" class='table table-striped table-bordered'>\n~;
my $is_head_printed = 0;

my $sth = $dbh->prepare("SELECT symbol, name FROM symbol WHERE type='index'");
$sth->execute();
while (my ($s, $n) = $sth->fetchrow_array) {
    say $s . ' ' . $n;

    my @history;
    my $history_sth = $dbh->prepare("SELECT * FROM history WHERE symbol = ? ORDER BY date DESC LIMIT 8");
    $history_sth->execute($s);
    while (my $h = $history_sth->fetchrow_hashref) { push @history, $h }

    unless ($is_head_printed) {
        print $fh qq~<thead><tr><th>Symbol</th>~;
        foreach my $i (1 .. 7) {
            print $fh qq~<th>$i 日</th>~;
            print $fh qq~<th>$i 日总</th>~;
        }
        print $fh qq~</tr></thead><tbody>\n~;
        $is_head_printed = 1;
    }

    print $fh qq~<tr><td>$s ($n)</td>~;
    foreach my $i (1 .. 7) {
        my $curr  = sprintf('%.2f', ( 100 * ($history[$i - 1]->{close} - $history[$i]->{close}) / $history[$i]->{close} ));
        my $total = sprintf('%.2f', ( 100 * ($history[0]->{close} - $history[$i]->{close}) / $history[$i]->{close} ));

        print $fh qq~<td>$curr%</td>~;
        print $fh qq~<td>$total%</td>~;
    }
    print $fh qq~</tr>\n~;
}

print $fh qq~</tbody></table>\n~;
close($fh);