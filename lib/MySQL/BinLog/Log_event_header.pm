package MySQL::BinLog::Log_event_header;
use strict;
use warnings;
use utf8;

sub new {
    my ($class, $event) = @_;
    bless [$event], $class;
}

for my $method (qw(
    marker
    timestamp
    type_code
    server_id
    event_length
    next_position
    flags
)) {
    no strict 'refs';
    *{__PACKAGE__ . "::$method"} = eval "sub { _$method(shift->[0]) }";
    die $@ if $@;
}

1;

