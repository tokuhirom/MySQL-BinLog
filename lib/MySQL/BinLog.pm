package MySQL::BinLog;
use strict;
use warnings;
use 5.008008;
our $VERSION = '0.01';
use parent qw(Exporter);

my %constants = (
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
use constant;
constant->import(\%constants);

our @EXPORT = (keys %constants);

require XSLoader;
XSLoader::load('MySQL::BinLog', $VERSION);

*MySQL::BinLog::Binary_log_event::Query::get_event_type = *MySQL::BinLog::Binary_log_event::get_event_type;
*MySQL::BinLog::Binary_log_event::User_var::get_event_type = *MySQL::BinLog::Binary_log_event::get_event_type;
*MySQL::BinLog::Binary_log_event::Rotate::get_event_type = *MySQL::BinLog::Binary_log_event::get_event_type;
*MySQL::BinLog::Binary_log_event::Incident::get_event_type = *MySQL::BinLog::Binary_log_event::get_event_type;

BEGIN {
for my $child_moniker (grep /::$/, keys %MySQL::BinLog::Binary_log_event::) {
    $child_moniker =~ s/::$//;
    no strict 'refs';
    unshift @{"MySQL::BinLog::Binary_log_event::${child_moniker}::ISA"}, 'MySQL::BinLog::Binary_log_event';
}
}

use MySQL::BinLog::Binary_log_event;

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
