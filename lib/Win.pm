package Win;

use strict;
use warnings;
use base 'Exporter';
use DBI;

our @EXPORT_OK = qw/dbh/;

sub dbh {
    return DBI->connect(
        "DBI:mysql:database=stock:mysql_enable_utf8=1", "root", "fayland",
        { RaiseError => 1, AutoCommit => 1 }
    );
}

1;