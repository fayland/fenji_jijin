#!/usr/bin/perl

use strict;
use warnings;
use v5.10;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Win qw/dbh/;
use LWP::UserAgent;
use Data::Dumper;
use Encode;

my $ua = LWP::UserAgent->new;
my $dbh = dbh();

my $list = [
    ['sz150205', 'sz150206', 'sz399973', '160630'],
    ['sz150221', 'sz150222', 'sz399959', '164402'],
    ['sz150181', 'sz150182', 'sz399967', '161024'],
    ['sz150186', 'sz150187', 'sz399967', '163115'],
    ['sz150209', 'sz150210', 'sz399974', '161026'],
    ['sz150085', 'sz150086', 'sz399005', '163111'],
    ['sz150106', 'sz150107', 'sz399005', '161118'],
    ['sz150152', 'sz150153', 'sz399006', '161022'],
    ['sz150194', 'sz150195', 'sz399970', '161025'],
    ['sz150179', 'sz150180', 'sz399935', '160626'],
    ['sz150173', 'sz150174', 'sh000998', '165522'],
    ['sz150203', 'sz150204', 'sz399971', '160629'],
    ['sz150130', 'sz150131', 'sz399394', '160219'],
    ['sz150196', 'sz150197', 'sz399395', '160221'],
    ['sz150171', 'sz150172', 'sz399707', '163113'],
    ['sz150315', 'sz150316', 'sz399803', '161031'],
    ['sz150307', 'sz150308', 'sz399804', '161030'],
    ['sz150211', 'sz150212', 'sz399976', '161028'],
    ['sz150184', 'sz150185', 'sh000827', '163114'],
    ['sz150051', 'sz150052', 'sz399300', '165515'],
    ['sz150018', 'sz150019', 'sz399004', '161812'],
    ['sz150227', 'sz150228', 'sz399986', '160631'],
    ['sz150157', 'sz150158', 'sh000974', '165521'],
    ['sz150277', 'sz150278', 'sz399807', '160639'],
    ['sz150198', 'sz150199', 'sz399396', '160222']
];

my $symbol_sth = $dbh->prepare("INSERT IGNORE INTO symbol (symbol, name, type, market) VALUES (?, ?, ?, ?)");
my $fenji_sth = $dbh->prepare("INSERT IGNORE INTO fenji_comb (symbolA, symbolB, symbolI, symbolF) VALUES (?, ?, ?, ?)");
foreach my $row (@$list) {
    my $sa = $row->[0];
    my $sb = $row->[1];
    my $sz = $row->[2];
    my $sf = $row->[3];

    my ($is_done) = $dbh->selectrow_array("SELECT 1 FROM fenji_comb WHERE symbolF = ?", undef, $sf);
    next if $is_done;

    my %name;
    foreach my $s ($sa, $sb, $sz) {
        my $res = $ua->get("http://hq.sinajs.cn/list=$s");
        die unless $res->is_success;
        # var hq_str_sz150205="国防A,0.967,0.968,0
        my ($n) = ($res->content =~ /\"(.*?)\,/);
        die unless $n;
        $name{$s} = encode('utf8', decode('gbk', $n));
    }

    my $res = $ua->get("http://hqqd.fund123.cn/HQ_NV_" . $sf . '.js');
    die unless $res->is_success;
    # var HQ_NV_160630 = ['160630', '鹏华中证国防指数分级',
    my ($sf_name) = ($res->decoded_content =~ /\[\'\d+\'\,\s*\'(.*?)\'/);
    die unless $sf_name;

    my $sa_name = $name{$sa};
    my $sb_name = $name{$sb};
    my $sz_name = $name{$sz};
    ($sa =~ s/^(sz|sh)//) and my ($sa_market) = $1;
    ($sb =~ s/^(sz|sh)//) and my ($sb_market) = $1;
    ($sz =~ s/^(sz|sh)//) and my ($sz_market) = $1;

    $symbol_sth->execute($sa, $sa_name, 'fenjiA', $sa_market);
    $symbol_sth->execute($sb, $sb_name, 'fenjiB', $sb_market);
    $symbol_sth->execute($sz, $sz_name, 'index', $sz_market);
    $symbol_sth->execute($sf, $sf_name, 'fund', '');

    $fenji_sth->execute($sa, $sb, $sz, $sf);

    sleep 1;
}