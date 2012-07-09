package MySQL::BinLog;
use strict;
use warnings;
use 5.008008;
our $VERSION = '0.01';
use parent qw(Exporter);

use constant {
    QUERY_EVENT              => 2,
    USER_VAR_EVENT           => 14,
    ROTATE_EVENT             => 4,
    FORMAT_DESCRIPTION_EVENT => 15,
    XID_EVENT                => 16,
    INCIDENT_EVENT           => 26,
};

our @EXPORT = qw(QUERY_EVENT USER_VAR_EVENT ROTATE_EVENT INCIDENT_EVENT);

require XSLoader;
XSLoader::load('MySQL::BinLog', $VERSION);

*MySQL::BinLog::Binary_log_event::Query::get_event_type = *MySQL::BinLog::Binary_log_event::get_event_type;
*MySQL::BinLog::Binary_log_event::User_var::get_event_type = *MySQL::BinLog::Binary_log_event::get_event_type;
*MySQL::BinLog::Binary_log_event::Rotate::get_event_type = *MySQL::BinLog::Binary_log_event::get_event_type;
*MySQL::BinLog::Binary_log_event::Incident::get_event_type = *MySQL::BinLog::Binary_log_event::get_event_type;

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
