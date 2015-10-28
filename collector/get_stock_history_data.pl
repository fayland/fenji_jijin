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

my $sth = $dbh->prepare("SELECT symbol, market FROM symbol WHERE type IN ('index', 'fenjiA', 'fenjiB')");
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

## 指数变化
open(my $fh, '>', "$Bin/../data/index_change.html");
print $fh qq~<table id="table_index_change" class='table table-striped table-bordered'>\n~;
my $is_head_printed = 0;

$sth = $dbh->prepare("SELECT symbol, name FROM symbol WHERE type='index'");
$sth->execute();
while (my ($s, $n) = $sth->fetchrow_array) {
    say $s . ' ' . $n;

    my @history;
    my $history_sth = $dbh->prepare("SELECT * FROM stock_history WHERE symbol = ? ORDER BY date DESC LIMIT 91");
    $history_sth->execute($s);
    while (my $h = $history_sth->fetchrow_hashref) { push @history, $h }

    unless ($is_head_printed) {
        print $fh qq~<thead><tr><th>Symbol</th>~;
        foreach my $i (1, 2, 3, 7, 30, 60, 90) {
            print $fh qq~<th>$i 日</th>~;
            print $fh qq~<th>$i 日总</th>~ if $i < 7;
        }
        print $fh qq~</tr></thead><tbody>\n~;
        $is_head_printed = 1;
    }

    print $fh qq~<tr><td>$s ($n)</td>~;
    foreach my $i (1, 2, 3, 7, 30, 60, 90) {
        my $curr  = $history[$i] ? sprintf('%.2f', ( 100 * ($history[$i - 1]->{close} - $history[$i]->{close}) / $history[$i]->{close} )) : '0';
        my $total = $history[$i] ? sprintf('%.2f', ( 100 * ($history[0]->{close} - $history[$i]->{close}) / $history[$i]->{close} )) : '0';

        print $fh qq~<td>$curr%</td>~;
        print $fh qq~<td>$total%</td>~ if $i < 7;
    }
    print $fh qq~</tr>\n~;
}

print $fh qq~</tbody></table>\n~;
close($fh);