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
my ($max_date) = $dbh->selectrow_array("SELECT max(date) FROM stock_high_data");
$sth = $dbh->prepare("SELECT * FROM stock_high_data WHERE date = ?");
$sth->execute($max_date);
while (my $r = $sth->fetchrow_hashref) {
    my $symbol = $r->{symbol};

    $get_symbol_name->execute($symbol);
    $r->{name} = $get_symbol_name->fetchrow_array;

    ## find the related index for the symbol
    $index_stock_sth->execute($symbol);
    while (my ($symbolI, $ratio) = $index_stock_sth->fetchrow_array) {
        unless ($data{$symbolI}) {
            $data{$symbolI} = { zhangting => [], others => [] };
            $get_symbol_name->execute($symbolI);
            $data{$symbolI}{name} = $get_symbol_name->fetchrow_array;
            $data{$symbolI}{total} = $dbh->selectrow_array("SELECT COUNT(*) FROM index_stock WHERE symbolI = ?", undef, $symbolI);
        }

        $r->{ratio} = $ratio;
        if ($r->{is_highest}) {
            push @{ $data{$symbolI}{zhangting} }, { %$r };
        } else {
            push @{ $data{$symbolI}{others} }, { %$r };
        }
    }
}

my $tt2 = Template->new({
    INCLUDE_PATH => "$Bin/templates",
    INTERPOLATE  => 1,               # expand "$var" in plain text
    POST_CHOMP   => 1,               # cleanup whitespace
});
$tt2->process("stock_high_data.tt2", {
    I_to_B => \%I_to_B,
    data  => \%data,
}, "$Bin/../data/stock_high_data.html") or die $tt2->error();