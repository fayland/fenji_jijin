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
use JSON;

my $ua = LWP::UserAgent->new;
my $dbh = dbh();

my @d = localtime( time() - 15 * 3600 ); # can 15 hours before now
my $today = sprintf('%04d-%02d-%02d', $d[5] + 1900, $d[4] + 1, $d[3]);

my $sth = $dbh->prepare("SELECT symbol, market FROM symbol WHERE type IN ('index')"); # , 'fenjiA', 'fenjiB'
$sth->execute();
while (my ($s, $market) = $sth->fetchrow_array) {
    my ($max_date) = $dbh->selectrow_array("
        SELECT MAX(date) FROM stock_history WHERE symbol = ?
    ", undef, $s);
    next if ($max_date // '') eq $today;
    my $xx = $market . $s;
    my $url = "http://api.finance.ifeng.com/akdaily/?code=$xx&type=last";
    say "# get $url";
    my $res = $ua->get($url);
    die unless $res->status_line;

    # date：日期
    # open：开盘价
    # high：最高价
    # close：收盘价
    # low：最低价
    # volume：成交量
    # price_change：价格变动
    # p_change：涨跌幅
    # ma5：5日均价
    # ma10：10日均价
    # ma20:20日均价
    # v_ma5:5日均量
    # v_ma10:10日均量
    # v_ma20:20日均量
    # turnover:换手率[注：指数无此项]

    my $data = decode_json($res->decoded_content);
    next unless ref $data->{record} eq 'ARRAY'; # BAD
    foreach my $row (@{$data->{record}}) {
        my ($date, $open, $high, $close, $low, $volume, $price_change, $p_change, $ma5, $ma10, $ma20, $v_ma5, $v_ma10, $v_ma20) = @$row;
        next unless $date =~ /^\d+/;

        $volume =~ s/\,//g;
        $v_ma5 =~ s/\,//g;
        $v_ma10 =~ s/\,//g;
        $v_ma20 =~ s/\,//g;

        $dbh->do("
            INSERT INTO stock_history
                (
                    symbol, date, `open`, high, low, close, volume, price_change, p_change,
                    ma5, ma10, ma20, v_ma5, v_ma10, v_ma20
                )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE
                `open` = values(`open`),
                high = values(high),
                low = values(low),
                close = values(close),
                volume = values(volume),
                price_change = values(price_change),
                p_change = values(p_change),
                ma5 = values(ma5),
                ma10 = values(ma10),
                ma20 = values(ma20),
                v_ma5 = values(v_ma5),
                v_ma10 = values(v_ma10),
                v_ma20 = values(v_ma20)
        ", undef, $s, $date, $open, $high, $low, $close, $volume, $price_change, $p_change, $ma5, $ma10, $ma20, $v_ma5, $v_ma10, $v_ma20);

    }

    say '' . scalar(@{$data->{record}}) . ' inserted';

    sleep 5;
}

`perl $Bin/../miner/index_history_data.pl`;
`perl $Bin/../miner/analysis_index_history.pl`;
