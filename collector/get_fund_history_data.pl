#!/usr/bin/perl

use strict;
use warnings;
use v5.10;
use LWP::UserAgent;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Win qw/dbh/;
use Encode;
use Data::Dumper;
use Mojo::DOM;
use JSON;

my $ua = LWP::UserAgent->new;
my $dbh = dbh();

my @d = localtime();
my $today = sprintf('%04d-%02d-%02d', $d[5] + 1900, $d[4] + 1, $d[3]);

my $sth = $dbh->prepare("SELECT symbol FROM symbol WHERE type IN ('fund', 'fenjiA', 'fenjiB')");
$sth->execute();
while (my ($s) = $sth->fetchrow_array) {
    my ($max_date) = $dbh->selectrow_array("
        SELECT MAX(date) FROM fund_history WHERE symbol = ?
    ", undef, $s);
    next if ($max_date // '') eq $today;

    my $per_page = $max_date ? 20 : 100;
    my $url = "http://fund.eastmoney.com/f10/F10DataApi.aspx?type=lsjz&code=$s&page=1&per=$per_page&sdate=&edate=&rt=" . rand();
    say "# get $url";
    my $res = $ua->get($url);
    die unless $res->status_line;

    # var apidata={ content:"<table...",records:227,pages:12,curpage:1};
    my $content = encode('utf8', decode('gbk', $res->content));
    my $dom = Mojo::DOM->new($content);
    foreach my $tr ($dom->find('tr')->each) {
        my @tds = $tr->find('td')->each;
        next unless @tds;
        @tds = map { $_->all_text() } @tds;
        # say Dumper(\@tds);
        if ($tds[0] =~ /^20/) {
            $dbh->do("
                INSERT INTO fund_history
                    (symbol, date, net_value, total_value)
                VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE
                    net_value = values(net_value),
                    total_value = values(total_value)
            ", undef, $s, $tds[0], $tds[1], $tds[2]);
        }
    }

    sleep 5;
}

## export fund 净值
my %net_value;
my ($max_date) = $dbh->selectrow_array("SELECT MAX(date) FROM fund_history");
$sth = $dbh->prepare("SELECT * FROM fund_history WHERE date = ?");
$sth->execute($max_date);
while (my $r = $sth->fetchrow_hashref) {
    $net_value{ $r->{symbol} } = $r->{net_value};
}

open(my $fh, '>', "$Bin/../data/fund_value.json");
print $fh encode_json(\%net_value);
close($fh);