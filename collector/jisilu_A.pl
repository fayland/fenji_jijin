#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use Mojo::UserAgent;
use Mojo::UserAgent::CookieJar::ChromeMacOS;

my $ua = Mojo::UserAgent->new;
$ua->transactor->name('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.63 Safari/537.36');
$ua->cookie_jar(Mojo::UserAgent::CookieJar::ChromeMacOS->new);

my $tx = $ua->post('https://www.jisilu.cn/data/sfnew/funda_list/?___t=' . time() => form => {
    is_funda_search => 1,
    fundavolume => '',
    maturity => '',
    "market[]" => ['sh', 'sz'],
    "coupon_descr[]" => ['+3.0%', '+3.2%', '+3.5%', '+4.0%', 'other'],
    rp => '50',
});

if (length($tx->res->body)) {
    die unless $tx->res->body =~ /funda_id/;
    open(my $fh, '>', "$Bin/../data/jisilu_A.json");
    print $fh $tx->res->body;
    close($fh);
} else {
    die;
}


1;