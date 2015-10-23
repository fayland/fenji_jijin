#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use LWP::UserAgent;
use HTTP::Cookies::ChromeMacOS;

# use Chrome cookie
my $cookie = HTTP::Cookies::ChromeMacOS->new();
$cookie->load( $ENV{HOME} . "/Library/Application Support/Google/Chrome/Default/Cookies" );

my $ua = LWP::UserAgent->new(
    agent => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.124 Safari/537.36',
    cookie_jar => $cookie
);

my $res = $ua->post('http://www.jisilu.cn/data/sfnew/funda_list/?___t=' . time(), [
    is_funda_search => 1,
    fundavolume => '',
    maturity => '',
    "market[]" => ['sh', 'sz'],
    "coupon_descr[]" => ['+3.0%', '+3.2%', '+3.5%', '+4.0%', 'other'],
    rp => '50',
]);

if (length($res->content)) {
    die unless $res->content =~ /funda_id/;
    open(my $fh, '>', "$Bin/../data/jisilu_A.json");
    print $fh $res->content;
    close($fh);
} else {
    die;
}


1;