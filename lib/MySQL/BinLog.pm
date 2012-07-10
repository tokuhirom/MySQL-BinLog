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

MySQL::BinLog - A module for you

=head1 SYNOPSIS

  use MySQL::BinLog;

=head1 DESCRIPTION

MySQL::BinLog is

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
