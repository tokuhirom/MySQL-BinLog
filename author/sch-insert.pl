#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;
use TheSchwartz;

my @dsn = ('dbi:mysql:hostname=127.0.0.1;port=21580;database=sch', 'msandbox', 'msandbox');
my $sch = TheSchwartz->new(
    databases => [
        +{
            dsn  => $dsn[0],
            user => $dsn[1],
            pass => $dsn[2],
        }
    ],
) or die;
$sch->insert('MyWorker');
