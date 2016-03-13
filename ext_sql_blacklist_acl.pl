#!/usr/bin/env perl
use URI;
use strict;
use DBI;
use Getopt::Long;
use Pod::Usage;
$|=1;

=pod

=head1 NAME

ext_sql_blacklist_acl - Database blacklist checker helper for Squid

=cut

my $dsn = "DBI:mysql:database=squid";
my $db_user = undef;
my $db_passwd = undef;
my $db_table = "blacklist";
my $db_domain_column = "domain"
my $persist = 0;
my $debug = 0;

=pod

=head1 SYNOPSIS

basic_db_auth [options]

=head1 DESCRIPTOIN

This program verifies if the domain is blacklisted in a database

=over 8

=item   B<--dsn>

Database DSN. Default "DBI:mysql:database=squid"

=item   B<--user>

Database User

=item   B<--password>

Database password

=item   B<--table>

Database table. Default "passwd".

=item   B<--usercol>

Username column. Default "user".

=item   B<--passwdcol>

Password column. Default "password".

=item   B<--cond>

Condition, defaults to enabled=1. Specify 1 or "" for no condition
If you use --joomla flag, this condition will be changed to block=0

=item   B<--plaintext>

Database contains plain-text passwords

=item   B<--md5>

Database contains unsalted md5 passwords

=item   B<--salt>

Selects the correct salt to evaluate passwords

=item   B<--persist>

Keep a persistent database connection open between queries. 

=item  B<--joomla>

Tells helper that user database is Joomla DB.  So their unusual salt 
hashing is understood.

=back

=cut

GetOptions(
    'dsn=s' => \$dsn,
    'user=s' => \$db_user,
    'password=s' => \$db_passwd,
    'table=s' => \$db_table,
    'urlcol=s' => \$db_url_column,
    'persist' => \$persist,
    'debug' => \$debug,
    );

my ($_db_handle, $_prepared_statement);

sub close_db() {
    return if !defined($_db_handle);
    undef $_prepared_statement;
    $_db_handle->disconnect();
    undef $_db_handle;
}

sub open_db() {
    return $_prepared_statement if defined $_prepared_statement;
    $_db_handle = DBI->connect($dsn, $db_user, $db_passwd);
    if (!defined $_db_handle) {
        warn ("Could not connect to $dsn\n");
        my @driver_names = DBI->available_drivers();
        my $msg = "DSN drivers apparently installed, available:\n";
        foreach my $dn (@driver_names) {
            $msg .= "\t$dn";
        }
        warn($msg."\n");
        return undef;
    }
    my $sql_query;
    $sql_query = "SELECT 1 FROM $db_table WHERE $db_domain_column LIKE ?";
    $_prepared_statement = $_db_handle->prepare($sql_query) || die;
    return $_prepared_statement;
}

sub query_db($) {
    my ($likedomain) = "%" . @_[0];
    my ($prepared_statement) = open_db() || return undef;
    if (!$prepared_statement->execute($likedomain)) {
        close_db();
        open_db() || return undef;
        $prepared_statement->execute($likedomain) || return undef;;
    }
    return $prepared_statement;
}

sub extract_domain_from_url($) {
    my $url = URI->new( @_[0] );
    my $domain = $url->host;
    return $domain;
}

my $status;
while (<>) {
    my $url = $_;

    $status = "ERR wrong URL format";
    my $domain = extract_domain_from_url($url) || next;

    $status = "ERR database connection error";
    my $sth = query_db($domain) || next;

    $status = "ERR blacklisted";
    my $row = $sth->fetchrow_arrayref() || next;

    $status = "OK";
} continue {
    close_db() if (!$persist);
    print $status . "\n";
}

=pod

=head1 COPYRIGHT

Copyright (C) 2007 Henrik Nordstrom <henrik@henriknordstrom.net>
Copyright (C) 2010 Luis Daniel Lucio Quiroz <dlucio@okay.com.mx> (Joomla support)
This program is free software. You may redistribute copies of it under the
terms of the GNU General Public License version 2, or (at youropinion) any
later version.

=cut
