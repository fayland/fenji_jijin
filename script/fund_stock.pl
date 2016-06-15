#!/usr/bin/perl

use strict;
use warnings;
use v5.10;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Win qw/dbh/;
use Data::Dumper;
use Encode;
use Mojo::UserAgent;
use Mojo::UserAgent::CookieJar::ChromeMacOS;

my $ua = Mojo::UserAgent->new;
$ua->transactor->name('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.63 Safari/537.36');
$ua->cookie_jar(Mojo::UserAgent::CookieJar::ChromeMacOS->new);

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
    my $tx = $ua->post("https://www.jisilu.cn/data/lof/$url_part/$fund_id?___t=" . time() => form => {
        is_search => 1,
        fund_id => $fund_id,
        rp => 50,
        page => 1
    });
    my $data = $tx->res->json;
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
