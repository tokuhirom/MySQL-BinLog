#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;
use MySQL::BinLog;
use Pod::Usage;
use Devel::Peek;
use Getopt::Long;

GetOptions(
    v => \my $verbose,
);

my $url = shift or pod2usage;
say("Connecting tot $url");
my $binlog = MySQL::BinLog->new(MySQL::BinLog::create_transport($url));
$binlog->connect();
$binlog->set_position(4);
say("connected: $binlog");
while (my $event = $binlog->wait_for_next_event()) {
    my $type = $event->get_event_type();
    if ($type eq QUERY_EVENT) {
        printf("QUERY: %s %s\n", $event->db_name, $event->query);
    } elsif ($type eq INCIDENT_EVENT) {
        printf("INCIDENT: %s\n", $event->message);
    } elsif ($type eq ROTATE_EVENT) {
        printf("ROTATE: %s, %s\n", $event->binlog_file, $event->binlog_pos);
    } elsif ($type eq USER_VAR_EVENT) {
        printf("name: %s\n", $event->name);
        printf("value: %s\n", $event->value);
    } else {
        if ($verbose) {
            printf("EVENT: %s %s\n", $event->get_event_type, $event->get_event_type_str);
        }
    }
}

__END__

=head1 SYNOPSIS

    % basic-1.pl mysql://msandbox:msandbox@127.0.0.1:21580

