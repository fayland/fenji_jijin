#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new(
    agent => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.124 Safari/537.36',
);

open(my $fh, '<', "$Bin/jisilu.cookie");
my $cookie = do {
    local $/; <$fh>;
};
close($fh);
$ua->default_header('Cookie', $cookie);

while (1) {
    my $res = $ua->post('http://www.jisilu.cn/data/sfnew/arbitrage_vip_list/?__t=' . time(), [
        is_search => 1,
        "market[]" => ['sh', 'sz'],
        'ptype' => 'price',
        rp => '50',
    ]);

    if (length($res->content)) {
        die unless $res->content =~ /fundA_id/;
        open(my $fh, '>', "$Bin/jisilu.json");
        print $fh $res->content;
        close($fh);
    } else {
        die;
    }

    sleep 20;
}


1;