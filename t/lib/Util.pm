package Util;

use strict;
use warnings;

use DBI;

sub setup_sqlite_dbh {
    return DBI->connect(
        ('dbi:SQLite:dbname=:memory:', '', ''),
        {
            PrintError => 0,
            RaiseError => 1,
        }
    );
}

{
    my @_mysql_db_to_clean_up;
    my $_mysql_db_name_counter = 0;

    sub setup_mysql_dbh {
        my $db_name = sprintf('sql_combine_test_%0.5d' => $_mysql_db_name_counter++);
        system('mysql', '-e', "DROP DATABASE IF EXISTS $db_name");
        system('mysql', '-e', "CREATE DATABASE $db_name");
        my $dbh = DBI->connect(
            ('dbi:mysql:database=' . $db_name . ';host=localhost', '', ''),
            {
                PrintError => 0,
                RaiseError => 1,
            }
        );
        push @_mysql_db_to_clean_up => $db_name;
        return $dbh;
    }

    END {
        map system('mysql', '-e', "DROP DATABASE IF EXISTS $_"), @_mysql_db_to_clean_up;
    }
}

sub setup_article_table {
    my ($dbh) = @_;

    $dbh->do(q[DROP TABLE IF EXISTS `article`]);
    $dbh->do(q[
        CREATE TABLE `article` (
            `id`       INT(10)   PRIMARY KEY,
            `title`    CHAR(255) NOT NULL,
            `body`     TEXT      NOT NULL,
            `created`  DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated`  DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `status`   CHAR(50)  NOT NULL DEFAULT "pending",
            `approver` INT(10)
        )
    ]);

    $dbh->do(q[ INSERT INTO `article` (`id`, `title`, `body`, `approver`) VALUES(1, "Title(1)", "Body(1)", 1) ]);
    $dbh->do(q[ INSERT INTO `article` (`id`, `title`, `body`, `approver`) VALUES(2, "Title(2)", "Body(2)", 1) ]);

    return $dbh;
}

sub setup_person_table {
    my ($dbh) = @_;

    $dbh->do(q[DROP TABLE IF EXISTS `person`]);
    $dbh->do(q[
        CREATE TABLE `person` (
            `id`   INT(10)   PRIMARY KEY,
            `name` CHAR(255) NOT NULL DEFAULT "anonymous",
            `age`  INT(10)   NOT NULL DEFAULT "100"
        )
    ]);

    $dbh->do(q[ INSERT INTO `person` (`id`, `name`, `age`) VALUES(1, "Bob", 30) ]);
    $dbh->do(q[ INSERT INTO `person` (`id`, `name`, `age`) VALUES(2, "Alice", 32) ]);

    return $dbh;
}

sub setup_comment_table {
    my ($dbh) = @_;

    $dbh->do(q[DROP TABLE IF EXISTS `comment`]);
    $dbh->do(q[
        CREATE TABLE `comment` (
            `id`      INT(10) PRIMARY KEY,
            `body`    TEXT    NOT NULL,
            `author`  INT(10) NOT NULL,
            `article` INT(10) NOT NULL
        )
    ]);

    $dbh->do(q[ INSERT INTO `comment` (`id`, `body`, `author`, `article`) VALUES(1, "Yo!", 1, 1) ]);
    $dbh->do(q[ INSERT INTO `comment` (`id`, `body`, `author`, `article`) VALUES(2, "Hey!", 2, 1) ]);

    $dbh->do(q[ INSERT INTO `comment` (`id`, `body`, `author`, `article`) VALUES(3, "Yo! (again)", 1, 2) ]);
    $dbh->do(q[ INSERT INTO `comment` (`id`, `body`, `author`, `article`) VALUES(4, "Hey! (again)", 2, 2) ]);

    return $dbh;
}

sub setup_xref_article_author_table {
    my ($dbh) = @_;

    $dbh->do(q[DROP TABLE IF EXISTS `xref_article_author`]);
    $dbh->do(q[
        CREATE TABLE `xref_article_author` (
            `author`  INT(10) NOT NULL,
            `article` INT(10) NOT NULL
        )
    ]);

    $dbh->do(q[ INSERT INTO `xref_article_author` (`author`, `article`) VALUES(1, 1) ]);
    $dbh->do(q[ INSERT INTO `xref_article_author` (`author`, `article`) VALUES(2, 1) ]);
    $dbh->do(q[ INSERT INTO `xref_article_author` (`author`, `article`) VALUES(2, 2) ]);

    return $dbh;
}

sub setup_database {
    my ($dbh) = @_;

    setup_article_table( $dbh );
    setup_person_table( $dbh );
    setup_comment_table( $dbh );
    setup_xref_article_author_table( $dbh );

    return $dbh;
}

1;
