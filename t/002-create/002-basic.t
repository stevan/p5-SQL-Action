#!perl

use strict;
use warnings;

use lib 't/lib';

use Util;
use Data::Dumper;

use Test::More;

BEGIN {
    use_ok('SQL::Action::DBH::Manager');

    use_ok('SQL::Action::Table');

    use_ok('SQL::Action::Create::One');
    use_ok('SQL::Action::Create::Many');

    use_ok('SQL::Action::Fetch::One');
    use_ok('SQL::Action::Fetch::Many');
}

my @DRIVERS = ('sqlite', 'mysql');
my @DBHS    = (
    Util::setup_database( Util::setup_sqlite_dbh ),
    Util::setup_database( Util::setup_mysql_dbh )
);

foreach my $i ( 0, 1 ) {

    my $DRIVER = $DRIVERS[ $i ];
    my $DBH    = $DBHS[ $i ];

    my $ARTICLE_ID = 1;

    my $dbm = SQL::Action::DBH::Manager->new(
        schemas => {
            user     => { rw => $DBH },
            comments => { rw => $DBH },
            articles => { ro => $DBH },
        }
    );
    isa_ok($dbm, 'SQL::Action::DBH::Manager');

    my $Person = SQL::Action::Table->new(
        schema => 'user',
        name   => 'person',
        driver => $DRIVER,
    );

    my $Comment = SQL::Action::Table->new(
        schema => 'comments',
        name   => 'comment',
        driver => $DRIVER,
    );

    my $Article = SQL::Action::Table->new(
        schema => 'articles',
        name   => 'article',
        driver => $DRIVER,
    );

    my $article_query = SQL::Action::Fetch::One->new(
        query => $Article->select(
            columns => [qw[ id title body ]],
            where   => [ id => $ARTICLE_ID ],
        )
    );
    isa_ok($article_query, 'SQL::Action::Fetch::One');

    $article_query->fetch_related(
        comments => SQL::Action::Fetch::Many->new(
            query => $Comment->select(
                columns  => [qw[ id body author ]],
                where    => [ article => $ARTICLE_ID ],
                order_by => 'id',
            )
        )
    );

    subtest '... test some article stuff (before change)' => sub {
        my $article = $article_query->execute( $dbm, {} );

        #warn Dumper $article;

        is_deeply(
            $article,
            {
                id       => 1,
                title    => 'Title(1)',
                body     => 'Body(1)',
                comments => [
                    { id => 1, author => 1, body => 'Yo!' },
                    { id => 2, author => 2, body => 'Hey!' },
                ]
            },
            '... got the expected set of (changed) data'
        );
    };

    subtest '... simple insert with upsert' => sub {

        my $PERSON_ID = 3;

        my $new_person_query = SQL::Action::Create::One->new(
            query => $Person->insert(
                values => [
                    id   => $PERSON_ID,
                    name => 'Jim',
                    age  => 25
                ]
            )
        );

        $new_person_query->create_related(
            comments => SQL::Action::Create::Many->new(
                queries => [
                    $Comment->insert(
                        values => [
                            id       => 5,
                            body     => 'Wassup!',
                            article  => $ARTICLE_ID,
                            author   => $PERSON_ID
                        ],
                    ),
                    $Comment->upsert(
                        values => [
                            id       => 1,
                            body     => 'DOH!',
                            article  => $ARTICLE_ID,
                            author   => $PERSON_ID
                        ]
                    )
                ]
            )
        );

        my $new_person_info = $new_person_query->execute( $dbm, {} );

        #warn Dumper $new_person_info;

        is_deeply(
            $new_person_info,
            {
                id       => $PERSON_ID,
                comments => {
                    ids => [ 5, 1 ]
                }
            },
            '... got the expected insert info'
        );

        my $person_query = SQL::Action::Fetch::One->new(
            query => $Person->select(
                columns => [qw[ id name age ]],
                where   => [ id => $PERSON_ID ],
            )
        );

        $person_query->fetch_related(
            comments => SQL::Action::Fetch::Many->new(
                query => $Comment->select(
                    columns  => [qw[ id body ]],
                    where    => [ author => $PERSON_ID ],
                    order_by => 'id',
                )
            )
        );

        my $jim = $person_query->execute( $dbm, {} );

        #warn Dumper $jim;

        is_deeply(
            $jim,
            {
                id       => $PERSON_ID,
                name     => 'Jim',
                age      => 25,
                comments => [
                    {
                        id   => 1,
                        body => 'DOH!'
                    },
                    {
                        id   => 5,
                        body => 'Wassup!'
                    },
                ]
            },
            '... got the selected data as expected'
        );

    };

    subtest '... test some article stuff (after change)' => sub {
        my $article = $article_query->execute( $dbm, {} );

        #warn Dumper $article;

        is_deeply(
            $article,
            {
                id       => 1,
                title    => 'Title(1)',
                body     => 'Body(1)',
                comments => [
                    { id => 1, author => 3, body => 'DOH!' },
                    { id => 2, author => 2, body => 'Hey!' },
                    { id => 5, author => 3, body => 'Wassup!' },
                ]
            },
            '... got the expected set of (changed) data'
        );
    };
}

done_testing;
