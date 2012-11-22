package MySQL::BinLog::Value;
use strict;
use warnings;
use utf8;

sub type_str {
    my $self = shift;
    my %type_id2str = reverse %MySQL::BinLog::TYPES;
    my $type = $type_id2str{$self->type};
    $type =~ s/MYSQL_TYPE_//;
    $type;
}

1;
__END__

=head1 NAME

MySQL::BinLog::Value - value object

=head1 METHODS

=over 4

=item $value->type_str

type name in string

=item $value->type()

Get type id

=item $value->length()

=item $value->is_null()

=item $value->as_string()

=back
