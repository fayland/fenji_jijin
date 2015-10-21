#!/usr/bin/perl

use strict;
use warnings;
use v5.10;
use LWP::UserAgent;
use Text::CSV;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Win qw/dbh/;
use Encode;
use Data::Dumper;

my $ua = LWP::UserAgent->new;
my $dbh = dbh();

my @d = localtime();
my $today = sprintf('%04d%02d%02d', $d[5] + 1900, $d[4] + 1, $d[3]);

my $csv = Text::CSV->new ( { binary => 1 } )
    or die "Cannot use CSV: ".Text::CSV->error_diag ();

my $sth = $dbh->prepare("SELECT symbol FROM symbol WHERE type='index'");
$sth->execute();
while (my ($s) = $sth->fetchrow_array) {
    my ($max_date) = $dbh->selectrow_array("
        SELECT MAX(date) FROM history WHERE symbol = ?
    ", undef, $s);
    $max_date ||= '20110701';
    $max_date =~ s/\-//g;
    next if $max_date eq $today;
    my $xx = $s =~ /^0/ ? "0$s" : "1$s";
    my $url = "http://quotes.money.163.com/service/chddata.html?code=$xx&start=$max_date&end=$today&fields=TCLOSE;HIGH;LOW;TOPEN;LCLOSE;CHG;PCHG;VOTURNOVER;VATURNOVER";
    say "# get $url";
    my $res = $ua->get($url);
    die unless $res->status_line;

    my $data = encode('utf8', decode('gbk', $res->content));
    my @lines = split(/[\r\n]+/, $data);
    foreach my $line (@lines) {
        $csv->parse($line) or die "Failed to parse $line\n";
        my @cols = $csv->fields();
        # say Dumper(\@cols);

        my $date = $cols[0];
        next unless $date =~ /^\d+/;

        my $close = $cols[3];
        my $high = $cols[4];
        my $low  = $cols[5];
        my $open = $cols[6];
        my $vol  = $cols[10];
        my $rmb  = $cols[11];

        $dbh->do("
            INSERT INTO history
                (symbol, date, `open`, high, low, close, vol, rmb)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE
                `open` = values(`open`),
                high = values(high),
                low = values(low),
                close = values(close),
                vol = values(vol),
                rmb = values(rmb)
        ", undef, $s, $date, $open, $high, $low, $close, $vol, $rmb);

    }

    say '' . (scalar(@lines) - 1) . ' inserted';

    sleep 5;
}
