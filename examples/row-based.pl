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
);

my %table_map;
my $url = shift or pod2usage;
my $binlog = MySQL::BinLog->new(MySQL::BinLog::create_transport($url));
$binlog->connect();
$binlog->set_position(4);
say("connected: $binlog");
while (my $event = $binlog->wait_for_next_event()) {
    my $type = $event->get_event_type();
    if ($type eq TABLE_MAP_EVENT) {
        $table_map{$event->table_id} = $event;
    } elsif ($type ~~ [WRITE_ROWS_EVENT, UPDATE_ROWS_EVENT, DELETE_ROWS_EVENT]) {
        my $table_event = $table_map{$event->table_id}
            or die "Unknown table: " . $event->table_id;
        my $rows = MySQL::BinLog::Row_event_set->new($event, $table_event);
        my $iter = $rows->begin();
        while (my $row = $iter->next()) {
            if ($type eq WRITE_ROWS_EVENT) {
                say("INSERT");
                show_row($row);
            } elsif ($type eq UPDATE_ROWS_EVENT) {
                say("UPDATE BEFORE");
                show_row($row);
                say("UPDATE AFTER");
                show_row($iter->next());
            } elsif ($type eq DELETE_ROWS_EVENT) {
                say("DELETE");
                show_row($row);
            }
        }
    }
}

sub show_row {
    my $row = shift;
    my $fields_iter = $row->begin;
    while (my $field = $fields_iter->next) {
        printf("       TYPE: %-10s STR: %s\n", $field->type_str, $field->as_string);
    }
}

__END__

=head1 SYNOPSIS

    % basic-1.pl mysql://msandbox:msandbox@127.0.0.1:21580

