package MySQL::BinLog::Value;
use strict;
use warnings;
use utf8;

sub type_str {
    my $self = shift;
    my %type_id2str = reverse %MySQL::BinLog::TYPES;
    my $type = ($type_id2str{$self->type} =~ s/MYSQL_TYPE_//r);
}

1;

