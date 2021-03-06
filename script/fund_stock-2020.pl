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
my $list = [
    ['sz150205', 'sz150206', 'sz399973', '160630'],
    ['sz150221', 'sz150222', 'sz399959', '164402'],
    ['sz150181', 'sz150182', 'sz399967', '161024'],
    ['sz150186', 'sz150187', 'sz399967', '163115'],
    ['sz150209', 'sz150210', 'sz399974', '161026'],
    ['sz150085', 'sz150086', 'sz399005', '163111'],
    ['sz150106', 'sz150107', 'sz399005', '161118'],
    ['sz150152', 'sz150153', 'sz399006', '161022'],
    ['sz150213', 'sz150214', 'sz399958', '161223'],
    ['sz150303', 'sz150304', 'sz399673', '160420'],
    ['sz150194', 'sz150195', 'sz399970', '161025'],
    ['sz150179', 'sz150180', 'sz399935', '160626'],
    ['sz150231', 'sz150232', 'sz399811', '163116'],
    ['sz150173', 'sz150174', 'sh000998', '165522'],
    ['sz150203', 'sz150204', 'sz399971', '160629'],
    ['sz150130', 'sz150131', 'sz399394', '160219'],
    ['sz150196', 'sz150197', 'sz399395', '160221'],
    ['sz150171', 'sz150172', 'sz399707', '163113'],
    ['sz150200', 'sz150201', 'sz399975', '161720'],
    ['sz150223', 'sz150224', 'sz399975', '161027'],
    ['sz150235', 'sz150236', 'sz399975', '160633'],
    ['sz150315', 'sz150316', 'sz399803', '161031'],
    ['sz150307', 'sz150308', 'sz399804', '161030'],
    ['sz150211', 'sz150212', 'sz399976', '161028'],
    ['sz150184', 'sz150185', 'sh000827', '163114'],
    ['sz150051', 'sz150052', 'sz399300', '165515'],
    ['sz150022', 'sz150023', 'sz399001', '163109'],
    ['sz150018', 'sz150019', 'sz399004', '161812'],
    ['sz150227', 'sz150228', 'sz399986', '160631'],
    ['sz150157', 'sz150158', 'sh000974', '165521'],
    ['sz150277', 'sz150278', 'sz399807', '160639'],
    ['sz150198', 'sz150199', 'sz399396', '160222'],
    ['sz150177', 'sz150178', 'sz399966', '160625'],

    ['sz150117', 'sz150118', 'sz399393', '160218'], # 房地产
    ['sz150143', 'sz150144', 'sh000832', '161826'], # 转债
    ['sz150265', 'sz150266', 'sz399991', '168201'], # 一带
    ['sz150123', 'sz150124', 'sz399550', '165312'], # 50
    ['sz150096', 'sz150097', 'sh000979', '161715'], # 商品
    ['sz150287', 'sz150288', 'sz399440', '168203'], # 钢铁
    ['sz150251', 'sz150252', 'sz399990', '161724'], # 煤炭
    ['sz150217', 'sz150218', 'sz399412', '164905'], # 新能源
    ['sz150100', 'sz150101', 'sh000805', '160620'], # 资源
    ['sz150261', 'sz150262', 'sz399989', '162412'], # 医疗

    ['sz150331', 'sz150332', 'sz399805', '165315'], # 网金融
    ['sz150269', 'sz150270', 'sz399997', '161725'], # 白酒

    ['sz150028', 'sz150029', 'sz399905', '165511'], # 中证500
];
foreach my $one (@$list) {
    my $fund_id = $one->[3];
    # my ($was_done) = $dbh->selectrow_array("
    #     SELECT COUNT(*) FROM fund_stock WHERE fund_id = ?
    # ", undef, $fund_id);
    # next if $was_done;

    next if $fund_id eq '161826';

    say "# on $fund_id";
    my $url_part = ($fund_id eq '161826') ? 'detail_fund_bonds' : 'detail_fund_stocks';
    my $tx = $ua->post("https://www.jisilu.cn/data/lof/$url_part/$fund_id?___jsl=LST___t=" . time() => form => {
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

`perl $Bin/../miner/fund_stock-2020.pl`;
