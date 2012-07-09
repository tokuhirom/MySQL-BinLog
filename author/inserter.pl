#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;

use DBI;

my $dbh = DBI->connect('dbi:mysql:hostname=127.0.0.1;port=21580', 'msandbox', 'msandbox', {RaiseError => 1})
    or die;
my $sth = $dbh->prepare(q{INSERT INTO foo.john (id) values (?)});
$sth->execute(3);

