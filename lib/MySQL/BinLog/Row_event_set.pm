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
__END__

=head1 NAME

MySQL::BinLog::Row_event_set - event set

=head1 MySQL::BinLog::Row_event_set

=over 4

=item MySQL::BinLog::Row_event_set->new(MySQL::BinLog::Binary_log_event::Row $row_event, MySQL::BinLog::Binary_log_event::Table_map $table_map) : MySQL::BinLog::Row_event_set

Create a new instance of MySQL::BinLog::Row_event_set.

=item my $iterator = $row_event_set->begin();

Create new iterator instance(I<MySQL::BinLog::Row_event_set::iterator>).

=back

=head1 MySQL::BinLog::Row_event_set::iterator

=over 4

=item $iter->next() : Maybe[MySQL::BinLog::Row_of_fields]

Get a next row from iterator. This method returns undef when it reached to end.

=back

