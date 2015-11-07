package SQL::Combine::Table::Upsert;
use Moose;

use SQL::Composer::Upsert;

with 'SQL::Combine::Table::Query';

has '_composer' => (
    is      => 'rw',
    isa     => 'SQL::Composer::Upsert',
    handles => [qw[
        to_sql
        to_bind
        from_rows
    ]]
);

has 'primary_key' => ( is => 'ro', isa => 'Str', default => 'id' );
has 'insert_id'   => (
    is        => 'ro',
    isa       => 'Num',
    predicate => 'has_insert_id',
    writer    => 'set_insert_id',
);

sub BUILD {
    my ($self, $params) = @_;

    my %values = ref $params->{values} eq 'HASH' ? %{ $params->{values} } : @{ $params->{values} };
    if ( my $id = $values{ $self->primary_key } ) {
        $self->set_insert_id( $id );
    }

    $self->_composer(
        SQL::Composer::Upsert->new(
            driver => $self->table->driver,
            into   => $self->table->name,

            values => $params->{values},
        )
    );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
