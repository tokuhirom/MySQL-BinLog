package MySQL::BinLog::Binary_log_event;
use strict;
use warnings;
use utf8;
use MySQL::BinLog::Log_event_header;

sub header {
    my $self = shift;
    MySQL::BinLog::Log_event_header->new($self);
}

1;

