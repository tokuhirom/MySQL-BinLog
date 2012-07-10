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

my $last_table_event;
my $url = shift or pod2usage;
say("Connecting tot $url");
my $binlog = MySQL::BinLog->new(MySQL::BinLog::create_transport($url));
$binlog->connect();
$binlog->set_position(4);
say("connected: $binlog");
while (my $event = $binlog->wait_for_next_event()) {
    my $type = $event->get_event_type();
    printf("[event] server_id: %s event_length: %s next_position: %s type: %s, type_code:%s\n", $event->header->server_id, $event->header->event_length, $event->header->next_position, $event->get_event_type_str, $event->header->type_code);
    if ($type eq QUERY_EVENT) {
        printf("QUERY: %s %s\n", $event->db_name, $event->query);
    } elsif ($type eq INCIDENT_EVENT) {
        printf("INCIDENT: message: %s type: %s\n", $event->message, $event->type);
    } elsif ($type eq ROTATE_EVENT) {
        printf("ROTATE: %s, %s\n", $event->binlog_file, $event->binlog_pos);
    } elsif ($type eq USER_VAR_EVENT) {
        printf("name: %s\n", $event->name);
        printf("value: %s\n", $event->value);
    } elsif ($type eq TABLE_MAP_EVENT) {
        $last_table_event = $event;
        printf(
            "  TABLE_MAP_EVENT: %s, table_id: %s table_name: %s, columns: %s metadata: %s, null_bits: %s\n",
            $event->db_name, $event->table_id,
            $event->table_name,
            join( ':', $event->columns ),
            join( ':', $event->metadata ),
            join( ':', $event->null_bits ),
        );
    } elsif ($type eq WRITE_ROWS_EVENT) {
        printf(
            "  WRITE_ROWS: %s\n",
            join(' ',
                $event->table_id,
                $event->flags,
                $event->columns_len,
                $event->null_bits_len,
                join( ':', $event->columns_before_image ),
                join( ':', $event->used_columns ),
                join( ':', $event->row ),
            )
        );
        if ($last_table_event) {
            my $rows = MySQL::BinLog::Row_event_set->new($event, $last_table_event);
            my $iter = $rows->begin();
            while (my $row = $iter->next()) {
                say "    SIZE: " . $row->size;
                my $fields_iter = $row->begin;
                while (my $field = $fields_iter->next) {
                    printf("       TYPE: %s STR: %s\n", $field->type, $field->as_string);
                }
            }
        }
    } else {
        if ($verbose) {
            printf("EVENT: %s %s\n", $event->get_event_type, $event->get_event_type_str);
        }
    }
}

__END__

=head1 SYNOPSIS

    % basic-1.pl mysql://msandbox:msandbox@127.0.0.1:21580

