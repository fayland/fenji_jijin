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
use JSON -support_by_pp;

my $ua = LWP::UserAgent->new;
my $dbh = dbh();

## only 涨 >= 8

my @d = localtime();
my $today = sprintf('%04d-%02d-%02d', $d[5] + 1900, $d[4] + 1, $d[3]);

# $today = '2015-10-23'; # FIX
my $base_url = "http://vip.stock.finance.sina.com.cn/quotes_service/api/json_v2.php/Market_Center.getHQNodeData?num=80&sort=changepercent&asc=0&node=hs_a&symbol=&_s_r_a=page&page=";

$dbh->do("DELETE FROM stock_high_data WHERE date = ?", undef, $today);

my $page = 0;
while (1) {
    $page++;
    my $url = $base_url . $page;
    say "# get $url";
    my $res = $ua->get($url);
    die unless $res->status_line;

    my $data = JSON->new->allow_barekey->decode( encode('utf8', decode('gbk', $res->content)) );
    foreach my $row (@{$data}) {
        last if $row->{changepercent} < 8;

        $dbh->do("
            INSERT INTO stock_high_data
                (
                    symbol, date, `open`, high, low, close, prev_close, p_change, is_highest,
                    turnover_ratio, volume, amount
                )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ", undef,
            $row->{code},
            $today,
            $row->{open},
            $row->{high},
            $row->{low},
            $row->{trade},
            $row->{settlement},
            $row->{changepercent},
            $row->{sell} == 0 ? 1 : 0,
            $row->{turnoverratio},
            $row->{volume},
            $row->{amount}
        );
    }

    last if $data->[-1]->{changepercent} < 8;

    sleep 5;
}
