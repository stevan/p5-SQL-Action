package SQL::Combine::Action;
use Moose::Role;

use SQL::Combine::Schema;

requires 'execute';
requires 'is_static';

has 'schema' => (
    is       => 'ro',
    isa      => 'SQL::Combine::Schema',
    required => 1
);

has 'relations' => (
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef[SQL::Combine::Action]',
    lazy     => 1,
    default  => sub { +{} },
    handles  => {
        _add_relation => 'set',
        all_relations => 'elements'
    }
);

sub relates_to {
    my ($self, $name, $action) = @_;
    $self->_add_relation( $name, $action );
    $self;
}

sub execute_relations {
    my ($self, $hash) = @_;
    my %relations = $self->all_relations;
    foreach my $rel ( keys %relations ) {
        $hash->{ $rel } = $relations{ $rel }->execute( $hash );
    }
}

sub execute_query {
    my ($self, $query) = @_;

    (blessed $query && $query->does('SQL::Combine::Query'))
        || confess 'The `query` object must implement the SQL::Combine::Query role';

    my $sql  = $query->to_sql;
    my @bind = $query->to_bind;

    $ENV{'SQL_COMBINE_DEBUG_SHOW_SQL'}
        && print STDERR '[',__PACKAGE__,'] SQL: "',$sql,'" BIND: (',(join ', ' => @bind),")\n";

    my $dbh = $self->schema->get_dbh_for_query( $query );
    my $sth = $dbh->prepare( $sql );
    $sth->execute( @bind );

    return $sth;
}

no Moose::Role; 1;

__END__

=pod

=cut
