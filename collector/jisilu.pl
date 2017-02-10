#!/usr/bin/perl

use strict;
use warnings;
use v5.10;
use FindBin qw/$Bin/;
use Mojo::UserAgent;
use Mojo::UserAgent::CookieJar::ChromeMacOS;

$| = 1; # flush

my $ua = Mojo::UserAgent->new;
$ua->transactor->name('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.63 Safari/537.36');
$ua->cookie_jar(Mojo::UserAgent::CookieJar::ChromeMacOS->new);

while (1) {
    my $tx = $ua->post('https://www.jisilu.cn/data/sfnew/arbitrage_vip_list/?___t=' . time() => form => {
        is_search => 1,
        "market[]" => ['sh', 'sz'],
        'ptype' => 'price',
        rp => '50',
        page => 1,
    });

    if (length($tx->res->body)) {
        die unless $tx->res->body =~ /fundA_id/;
        open(my $fh, '>', "$Bin/../data/jisilu.json");
        print $fh $tx->res->body;
        close($fh);

        # say Dumper(\$tx->res->json); use Data::Dumper;

        # random update
        if (int(rand(100)) == 1) {
            print `perl $Bin/../miner/jisilu.pl`;
        }
    } else {
        die;
    }

    # at least run once
    my @d = localtime();
    my $hour = $d[2];
    my $min  = $d[1];
    exit if $hour < 9;
    exit if $hour > 15;
    exit if $hour == 15 and $min > 10;

    sleep 20;
}

1;