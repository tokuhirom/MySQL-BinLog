package MySQL::BinLog;
use strict;
use warnings;
use 5.014000;
our $VERSION = '0.01';
use parent qw(Exporter);

our %TYPES = (
    MYSQL_TYPE_DECIMAL     => 0,
    MYSQL_TYPE_TINY        => 1,
    MYSQL_TYPE_SHORT       => 2,
    MYSQL_TYPE_LONG        => 3,
    MYSQL_TYPE_FLOAT       => 4,
    MYSQL_TYPE_DOUBLE      => 5,
    MYSQL_TYPE_NULL        => 6,
    MYSQL_TYPE_TIMESTAMP   => 7,
    MYSQL_TYPE_LONGLONG    => 8,
    MYSQL_TYPE_INT24       => 9,
    MYSQL_TYPE_DATE        => 10,
    MYSQL_TYPE_TIME        => 11,
    MYSQL_TYPE_DATETIME    => 12,
    MYSQL_TYPE_YEAR        => 13,
    MYSQL_TYPE_NEWDATE     => 14,
    MYSQL_TYPE_VARCHAR     => 15,
    MYSQL_TYPE_BIT         => 16,
    MYSQL_TYPE_NEWDECIMAL  => 246,
    MYSQL_TYPE_ENUM        => 247,
    MYSQL_TYPE_SET         => 248,
    MYSQL_TYPE_TINY_BLOB   => 249,
    MYSQL_TYPE_MEDIUM_BLOB => 250,
    MYSQL_TYPE_LONG_BLOB   => 251,
    MYSQL_TYPE_BLOB        => 252,
    MYSQL_TYPE_VAR_STRING  => 253,
    MYSQL_TYPE_STRING      => 254,
    MYSQL_TYPE_GEOMETRY    => 255
);
our %EVENTS = (
    UNKNOWN_EVENT            => 0,
    START_EVENT_V3           => 1,
    QUERY_EVENT              => 2,
    STOP_EVENT               => 3,
    ROTATE_EVENT             => 4,
    INTVAR_EVENT             => 5,
    LOAD_EVENT               => 6,
    SLAVE_EVENT              => 7,
    CREATE_FILE_EVENT        => 8,
    APPEND_BLOCK_EVENT       => 9,
    EXEC_LOAD_EVENT          => 10,
    DELETE_FILE_EVENT        => 11,
    NEW_LOAD_EVENT           => 12,
    RAND_EVENT               => 13,
    USER_VAR_EVENT           => 14,
    FORMAT_DESCRIPTION_EVENT => 15,
    XID_EVENT                => 16,
    BEGIN_LOAD_QUERY_EVENT   => 17,
    EXECUTE_LOAD_QUERY_EVENT => 18,
    TABLE_MAP_EVENT          => 19,
    PRE_GA_WRITE_ROWS_EVENT  => 20,
    PRE_GA_UPDATE_ROWS_EVENT => 21,
    PRE_GA_DELETE_ROWS_EVENT => 22,
    WRITE_ROWS_EVENT         => 23,
    UPDATE_ROWS_EVENT        => 24,
    DELETE_ROWS_EVENT        => 25,
    INCIDENT_EVENT           => 26,
    USER_DEFINED             => 27,
);
my %constants = (
    %EVENTS,
    %TYPES,
);
use constant;
constant->import(\%constants);

our @EXPORT = (keys %constants);

require XSLoader;
XSLoader::load('MySQL::BinLog', $VERSION);

for my $child_moniker (grep /::$/, keys %MySQL::BinLog::Binary_log_event::) {
    $child_moniker =~ s/::$//;
    no strict 'refs';
    unshift @{"MySQL::BinLog::Binary_log_event::${child_moniker}::ISA"}, 'MySQL::BinLog::Binary_log_event';
    *{"MySQL::BinLog::Binary_log_event::${child_moniker}::get_event_type"} = *MySQL::BinLog::Binary_log_event::get_event_type;
}

use MySQL::BinLog::Binary_log_event;
use MySQL::BinLog::Row_event_set;
use MySQL::BinLog::Value;

1;
__END__

=encoding utf8

=head1 NAME

MySQL::BinLog - mysql replication listener in Perl5

=head1 SYNOPSIS

    use MySQL::BinLog;

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

=head1 DESCRIPTION

MySQL::BinLog is libreplication binding for Perl5.

You can write your own replication listener for mysql.

=head1 Row based vs. Statement based

Statement based/Mixed replication is less useful to use. You would use row based replication for this module. 

You can handle WRITE_ROWS_EVENT, UPDATE_ROWS_EVENT, DELETE_ROWS_EVENT on only row based binlog.

=head1 EXAMPLE CODE

See examples/row-based.pl in distribution.

=head1 FUNCTIONS

=over 4

=item create_transport(Str $url) : MySQL::BinLog::Binary_log_driver

Create instance of from url like 'mysql://msandbox:msandbox@127.0.0.1:21580'.

=back

=head1 METHODS

=over 4

=item my $binlog = MySQL::BinLog->new(MySQL::BinLog::Binary_log_driver $driver)

create new instance of MySQL::BinLog. You must pass $driver by getting from create_transport().

=item $binlog->connect() : Void

Connect to the server. throw exception when failed to connect.

=item $binlog->set_position(Int $i) : Void

Set binlog position to I<$i>. die when failed.

=item $binlog->get_position(): Int

Get current binlog position.

=item $binlog->wait_for_next_event() : MySQL::BinLog::Binary_log_event

Wait a event from server and return event object.

Return value is child class instance of MySQL::BinLog::Binary_log_event.

=back

=head1 MySQL::BinLog::Binary_log_event

Base class for event classes.

=over 4

=item $event->get_event_type() : Int

get a event type id.

=item $event->get_event_type_str() : Str

Get event name in string.

=back

=head1 MySQL::BinLog::Binary_log_event::Query

=over 4

=item query

=item db_name

=back

=head1 MySQL::BinLog::Binary_log_event::Incident

=over 4

=item message

=item type

=back

=head1 MySQL::BinLog::Binary_log_event::User_var

=over 4

=item name

=item value

=back

=head1 MySQL::BinLog::Binary_log_event::Rotate

=over 4

=item name

=item value

=back

=head1 MySQL::BinLog::Binary_log_event::Table_map

=over 4

=back table_id

=item flags

=item db_name

=item table_name

=item columns

=item metadata

=item null_bits

=back

=head1 MySQL::BinLog::Binary_log_event::Row

=over 4

=item table_id

=item flags

=item columns_len

=item null_bits_len

=item columns_before_image

=item used_columns

=item row

=back

=head1 CONSTANTS

=head2 types

    MYSQL_TYPE_DECIMAL     => 0,
    MYSQL_TYPE_TINY        => 1,
    MYSQL_TYPE_SHORT       => 2,
    MYSQL_TYPE_LONG        => 3,
    MYSQL_TYPE_FLOAT       => 4,
    MYSQL_TYPE_DOUBLE      => 5,
    MYSQL_TYPE_NULL        => 6,
    MYSQL_TYPE_TIMESTAMP   => 7,
    MYSQL_TYPE_LONGLONG    => 8,
    MYSQL_TYPE_INT24       => 9,
    MYSQL_TYPE_DATE        => 10,
    MYSQL_TYPE_TIME        => 11,
    MYSQL_TYPE_DATETIME    => 12,
    MYSQL_TYPE_YEAR        => 13,
    MYSQL_TYPE_NEWDATE     => 14,
    MYSQL_TYPE_VARCHAR     => 15,
    MYSQL_TYPE_BIT         => 16,
    MYSQL_TYPE_NEWDECIMAL  => 246,
    MYSQL_TYPE_ENUM        => 247,
    MYSQL_TYPE_SET         => 248,
    MYSQL_TYPE_TINY_BLOB   => 249,
    MYSQL_TYPE_MEDIUM_BLOB => 250,
    MYSQL_TYPE_LONG_BLOB   => 251,
    MYSQL_TYPE_BLOB        => 252,
    MYSQL_TYPE_VAR_STRING  => 253,
    MYSQL_TYPE_STRING      => 254,
    MYSQL_TYPE_GEOMETRY    => 255

=head1 events

    UNKNOWN_EVENT            => 0,
    START_EVENT_V3           => 1,
    QUERY_EVENT              => 2,
    STOP_EVENT               => 3,
    ROTATE_EVENT             => 4,
    INTVAR_EVENT             => 5,
    LOAD_EVENT               => 6,
    SLAVE_EVENT              => 7,
    CREATE_FILE_EVENT        => 8,
    APPEND_BLOCK_EVENT       => 9,
    EXEC_LOAD_EVENT          => 10,
    DELETE_FILE_EVENT        => 11,
    NEW_LOAD_EVENT           => 12,
    RAND_EVENT               => 13,
    USER_VAR_EVENT           => 14,
    FORMAT_DESCRIPTION_EVENT => 15,
    XID_EVENT                => 16,
    BEGIN_LOAD_QUERY_EVENT   => 17,
    EXECUTE_LOAD_QUERY_EVENT => 18,
    TABLE_MAP_EVENT          => 19,
    PRE_GA_WRITE_ROWS_EVENT  => 20,
    PRE_GA_UPDATE_ROWS_EVENT => 21,
    PRE_GA_DELETE_ROWS_EVENT => 22,
    WRITE_ROWS_EVENT         => 23,
    UPDATE_ROWS_EVENT        => 24,
    DELETE_ROWS_EVENT        => 25,
    INCIDENT_EVENT           => 26,
    USER_DEFINED             => 27,

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
