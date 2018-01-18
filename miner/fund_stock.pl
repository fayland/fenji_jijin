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

my $fund_stock_sth = $dbh->prepare("SELECT symbol, ratio FROM fund_stock WHERE fund_id = ? order by ratio DESC");
my $get_symbol_name = $dbh->prepare("SELECT name, market FROM symbol WHERE symbol = ?");

# all combs
my @combs;
my $sth = $dbh->prepare("SELECT * FROM fenji_comb");
$sth->execute();
while (my $r = $sth->fetchrow_hashref) {
    next if $r->{symbolF} eq '161826';

    $get_symbol_name->execute($r->{symbolB});
    my ($b_name, $b_market) = $get_symbol_name->fetchrow_array;
    $get_symbol_name->execute($r->{symbolI});
    my ($i_name, $i_market) = $get_symbol_name->fetchrow_array;

    my @zc;
    $fund_stock_sth->execute($r->{symbolF});
    while (my ($s, $ratio) = $fund_stock_sth->fetchrow_array) {
        $get_symbol_name->execute($s);
        my ($s_name, $market) = $get_symbol_name->fetchrow_array;
        # say "$s, $s_name, $market";
        push @zc, {
            id => $s,
            sid => $market . $s,
            name => $s_name,
            ratio => $ratio
        };
    }

    push @combs, {
        b_id   => $r->{symbolB},
        b_sid  => $b_market . $r->{symbolB},
        b_name => $b_name,
        i_id   => $r->{symbolI},
        i_sid  => $i_market . $r->{symbolI},
        i_name => $i_name,
        all => \@zc
    }
}

my $tt2 = Template->new({
    INCLUDE_PATH => "$Bin/templates",
    INTERPOLATE  => 1,               # expand "$var" in plain text
    POST_CHOMP   => 1,               # cleanup whitespace
});
$tt2->process("fund_stock.tt2", {
    combs  => \@combs,
}, "$Bin/../data/fund_stock.html") or die $tt2->error();