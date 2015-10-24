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

my $index_stock_sth = $dbh->prepare("SELECT symbolI, ratio FROM index_stock WHERE symbolS = ?");
my $get_symbol_name = $dbh->prepare("SELECT name FROM symbol WHERE symbol = ?");

# all combs
my %I_to_B;
my $sth = $dbh->prepare("SELECT * FROM fenji_comb");
$sth->execute();
while (my $r = $sth->fetchrow_hashref) {
    $get_symbol_name->execute($r->{symbolB});
    $I_to_B{ $r->{symbolI} } = {
        symbol => $r->{symbolB},
        name   => $get_symbol_name->fetchrow_array
    };
}


my %data;
my ($max_date) = $dbh->selectrow_array("SELECT max(date) FROM longhubang");
$sth = $dbh->prepare("SELECT * FROM longhubang WHERE date = ?");
$sth->execute($max_date);
while (my $r = $sth->fetchrow_hashref) {
    my $symbol = $r->{symbol};

    ## good news or bad
    my $good_or_bad = 0;
    my $p_change = $r->{p_change};
    if ($p_change > 5) {
        $good_or_bad++;
    } elsif ($p_change < -5) {
        $good_or_bad--;
    }

    if ($r->{buy_rmb_ratio} > $r->{sell_rmb_ratio} * 2) {
        $good_or_bad++;
    } elsif ($r->{sell_rmb_ratio} > $r->{buy_rmb_ratio} * 2) {
        $good_or_bad--;
    }

    $get_symbol_name->execute($symbol);
    $r->{name} = $get_symbol_name->fetchrow_array;

    ## find the related index for the symbol
    $index_stock_sth->execute($symbol);
    while (my ($symbolI, $ratio) = $index_stock_sth->fetchrow_array) {
        unless ($data{$symbolI}) {
            $data{$symbolI} = { good => [], eq => [], bad => [] };
            $get_symbol_name->execute($symbolI);
            $data{$symbolI}{name} = $get_symbol_name->fetchrow_array;
        }

        $r->{ratio} = $ratio;
        if ($good_or_bad > 0) {
            push @{ $data{$symbolI}{good} }, { %$r };
        } elsif ($good_or_bad < 0) {
            push @{ $data{$symbolI}{bad} }, { %$r };
        } else {
            push @{ $data{$symbolI}{eq} }, { %$r };
        }
    }
}

my $tt2 = Template->new({
    INCLUDE_PATH => "$Bin/templates",
    INTERPOLATE  => 1,               # expand "$var" in plain text
    POST_CHOMP   => 1,               # cleanup whitespace
});
$tt2->process("longhubang.tt2", {
    I_to_B => \%I_to_B,
    data  => \%data,
}, "$Bin/../data/longhubang.html") or die $tt2->error();