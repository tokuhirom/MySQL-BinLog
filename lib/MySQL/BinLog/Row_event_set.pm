package MySQL::BinLog::Row_event_set;
use strict;
use warnings;
use utf8;

sub new {
    my ($class, $row_event, $table_map_event) = @_;
    bless [$row_event, $table_map_event], $class;
}

sub begin {
    my ($self) = @_;
    return _begin($self->[0], $self->[1]);
}

package MySQL::BinLog::Row_event_set::iterator;

sub new {
    my ($class, $row_event_set) = @_;
    bless [$row_event_set], $class;
}

1;

