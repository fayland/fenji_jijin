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

my $ua = LWP::UserAgent->new;
my $dbh = dbh();

my $url = 'http://data.eastmoney.com/stock/tradedetail.html'; # 龙虎榜
say "# get $url";
my $res = $ua->get($url);
die unless $res->status_line;

my $insert_sth = $dbh->prepare("
    INSERT INTO longhubang
        (date, symbol, p_change, rmb_vol, buy_rmb_vol, buy_rmb_ratio, sell_rmb_vol, sell_rmb_ratio, reason)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
");

my $dom = Mojo::DOM->new( encode('utf8', decode('gb2312', $res->content)) );

# date from <input id="notice_Ddl" class="ddl" type="text" readonly="readonly" value="2015-10-23" />
my $date = $dom->at('input#notice_Ddl')->attr('value');
$dbh->do("DELETE FROM longhubang WHERE date = ?", undef, $date);


my $tbody = $dom->at('tbody');
foreach my $tr ($tbody->find('tr.all')->each) {
    my @tds = $tr->find('td')->each;
    @tds = map { $_->all_text() } @tds;
    say Dumper(\@tds);

    next if @tds < 10;
    die unless $tds[1] =~ /^\d{6}$/;

    my $p_change = $tds[4]; $p_change =~ s/\%$// or die;
    my $buy_rmb_ratio = $tds[7]; $buy_rmb_ratio =~ s/\%$// or die;
    my $sell_rmb_ratio = $tds[9]; $sell_rmb_ratio =~ s/\%$// or die;

    $insert_sth->execute(
        $date,
        $tds[1],
        $p_change,
        $tds[5],
        $tds[6],
        $buy_rmb_ratio,
        $tds[8],
        $sell_rmb_ratio,
        $tds[10]
    );
}

