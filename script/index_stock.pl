#!/usr/bin/perl

use strict;
use warnings;
use v5.10;
use LWP::UserAgent;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Win qw/dbh/;
use Data::Dumper;
use Spreadsheet::ParseExcel;
use Encode;

my $ua = LWP::UserAgent->new;
my $dbh = dbh();

mkdir("$Bin/../data/xls") unless -d "$Bin/../data/xls";

my $select_sth = $dbh->prepare("SELECT symbol FROM stock WHERE name = ?");
my $insert_sth = $dbh->prepare("INSERT IGNORE INTO index_stock (symbolI, symbolS, ratio) VALUES (?, ?, ?)");

my $sth = $dbh->prepare("SELECT symbol FROM symbol WHERE type = 'index'");
$sth->execute();
while (my ($s) = $sth->fetchrow_array) {
    next if $s eq '000974'; # FIXME
    csindex($s) or cnindex($s);
}

# ftp://115.29.204.48/webdata/
sub csindex { # 中证
    my ($s) = @_;

    my $file = "$Bin/../data/xls/${s}cons.xls";
    return 1 if -e $file;
    my $url_s = $s eq '399300' ? '000300' : $s;
    my $url = "http://www.csindex.com.cn/uploads/file/autofile/cons/" . $url_s . "cons.xls";
    say "# get $url";
    my $res = $ua->get($url, ':content_file' => $file);
    sleep 5;
    if ($res->is_success) {
        $dbh->do("DELETE FROM index_stock WHERE symbolI=?", undef, $s);
        my $parser   = Spreadsheet::ParseExcel->new();
        my $workbook = $parser->parse($file);
        for my $worksheet ( $workbook->worksheets() ) {
            my ( $row_min, $row_max ) = $worksheet->row_range();
            my ( $col_min, $col_max ) = $worksheet->col_range();
            for my $row ( 1 .. $row_max ) { # start with 1 b/c 0 is header
                my $cell = $worksheet->get_cell($row, 0); # the first col is code
                next unless $cell;
                my $symbolS = $cell->value();
                $insert_sth->execute($s, $symbolS, 0);
            }
        }
        return 1;
    } else {
        say $res->status_line;
        return 0;
    }
}

# http://www.cnindex.com.cn/docs/yb_399001.xls
sub cnindex { # 深证
    my ($s) = @_;

    my $file = "$Bin/../data/xls/yb_${s}.xls";
    return 1 if -e $file;
    my $url = "http://www.cnindex.com.cn/docs/yb_${s}.xls";
    say "# get $url";
    my $res = $ua->get($url, ':content_file' => $file);
    sleep 5;
    if ($res->is_success) {
        $dbh->do("DELETE FROM index_stock WHERE symbolI=?", undef, $s);
        my $parser   = Spreadsheet::ParseExcel->new();
        my $workbook = $parser->parse($file);
        for my $worksheet ( $workbook->worksheets() ) {
            my ( $row_min, $row_max ) = $worksheet->row_range();
            my ( $col_min, $col_max ) = $worksheet->col_range();
            for my $row ( 1 .. $row_max ) { # start with 1 b/c 0 is header
                my $start_col = 2;

                my $cell = $worksheet->get_cell($row, $start_col); # the first col is code
                next unless $cell;
                my $name = $cell->value();

                ## we have two formats
                ## code, name, ratio
                ## or
                ## name, ratio
                my $symbolS;
                if ($name =~ /^\d{6}$/) {
                    $start_col = 4;
                    $symbolS = $name;
                } else {
                    $start_col = 3;

                    $select_sth->execute( encode('utf8', $name) );
                    ($symbolS) = $select_sth->fetchrow_array;
                    unless ($symbolS) {
                        ($symbolS) = $dbh->selectrow_array("SELECT symbol FROM stock_legacy WHERE name = ?", undef, encode('utf8', $name));
                    }

                    die encode('utf8', $name) unless $symbolS;
                }

                $cell = $worksheet->get_cell($row, $start_col);
                my $ratio = $cell->value();
                $insert_sth->execute($s, $symbolS, $ratio);
            }
        }
        return 1;
    } else {
        say $res->status_line;
        return 0;
    }
}