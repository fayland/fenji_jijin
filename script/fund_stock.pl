#!/usr/bin/perl

use strict;
use warnings;
use v5.10;
use LWP::UserAgent;
use HTTP::Cookies::ChromeMacOS;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Win qw/dbh/;
use Data::Dumper;
use Encode;
use HTTP::Cookies::ChromeMacOS;
use JSON;

# use Chrome cookie
my $cookie = HTTP::Cookies::ChromeMacOS->new();
$cookie->load( $ENV{HOME} . "/Library/Application Support/Google/Chrome/Default/Cookies" );

my $ua = LWP::UserAgent->new(
    agent => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.66 Safari/537.36',
    cookie_jar => $cookie
);

my $dbh = dbh();

## get all funds
my $sth = $dbh->prepare("SELECT symbolF FROM fenji_comb");
$sth->execute();
while (my ($fund_id) = $sth->fetchrow_array) {
    # my ($was_done) = $dbh->selectrow_array("
    #     SELECT COUNT(*) FROM fund_stock WHERE fund_id = ?
    # ", undef, $fund_id);
    # next if $was_done;

    next if $fund_id eq '161826';

    say "# on $fund_id";
    my $url_part = ($fund_id eq '161826') ? 'detail_fund_bonds' : 'detail_fund_stocks';
    my $res = $ua->post("https://www.jisilu.cn/data/lof/$url_part/$fund_id?___t=" . time(), [
        is_search => 1,
        fund_id => $fund_id,
        rp => 50,
        page => 1
    ]);
    my $data = decode_json($res->content);
    # print Dumper(\$data);
    $dbh->do("DELETE FROM fund_stock WHERE fund_id = ?", undef, $fund_id);
    foreach my $row (@{$data->{rows}}) {
        my $s = $row->{cell}->{asset_id};
        my $ratio = $row->{cell}->{ratio}; $ratio =~ s/\%$//;
        say "\t$s - $ratio";
        $dbh->do("INSERT INTO fund_stock (fund_id, symbol, ratio) VALUES (?, ?, ?)", undef, $fund_id, $s, $ratio);
    }
    sleep 10;
}

`perl $Bin/../miner/fund_stock.pl`;
