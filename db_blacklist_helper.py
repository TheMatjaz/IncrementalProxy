#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Squid3 external ACL helper script to check if an authenticated user is allowed
# to access a certain domain or not

import psycopg2
from urllib.parse import urlparse
from sys import stdin, stdout
import argparse
from gc import collect


class DomainAccessControllerOnPostgreSql(object):
    def __init__(self, db_host, db_name, db_user, db_passwd, statement):
        self.connection = None
        self.db_host = db_host
        self.db_name = db_name
        self.db_user = db_user
        self.db_passwd = db_passwd
        self.prepared_statement = statement
        self.prepared_cursor = None
        self.error_string = None

    def open_db_connection_if_closed(self):
        if self.connection is None:
            db_connect_string = "host='{:s}' dbname='{:s}' user='{:s}' password='{:s}'".format(self.db_host, self.db_name, self.db_user, self.db_passwd)
            try:
                self.connection = psycopg2.connect(db_connect_string)
            except:
                self.error_string = "ERR Unable to connect to the database"
                self.connection = None # is this necessary? Just to be sure?
                return False
            return True
        else:
            return True

    def prepare_statement_if_not_already(self):
        if self.prepared_cursor is None:
            try:
                self.prepared_cursor = self.connection.cursor()
            except:
                self.error_string = "ERR Unable to create cursor"
                return False
            try:
                self.prepared_cursor.execute(self.prepared_statement)
            except:
                self.error_string = "ERR Unable to prepare statement"
                return False
            return True
        else:
            return True
    
    def close_db_connection_if_open(self):
        if self.connection is not None:
            try:
                self.prepared_cursor.close()
            except:
                self.error_string = "ERR Unable to close prepared cursor"
                self.prepared_cursor = None
                return False
            try:
                self.connection.close()
            except:
                self.error_string = "ERR Unable to close connection"
                self.connection = None
                return False
            return True
        else:
            return True

    def is_user_allowed_to_domain(self, username, domain):
        try:
            execute_statement = "EXECUTE user_domain_select (%s, %s);"
            self.prepared_cursor.execute(execute_statement, (username, domain))
        except:
            self.error_string = "ERR Unable to execute prepared statement"
            return False
        row = self.prepared_cursor.fetchone()
        if row is not None:
            # The domain is in the blacklist for this user
            self.error_string = "ERR User is not allowed to this domain"
            return False
        else:
            # User is allowed
            return True


class SquidInputParser(object):
    def __init__(self):
        self.requested_url = None
        self.username = None
        self.client_ip = None
        self.request_method = None
        self.requested_domain = 

    def parse_squid_input_line(self, line):
        # Example input lines that Squid passes to the external redirector tool
        # URL <Space> client_ip "/" fqdn <Space> user <Space> method [<Space> kvpairs]<NL>
        #
        # pintrest.com:443 140.105.225.106/- gustin CONNECT myip=172.31.24.53 myport=8080
        # http://pintrest.com/ 140.105.225.106/- gustin GET myip=172.31.24.53 myport=8080
        # ftp://pintrest.com/ 140.105.225.106/- gustin GET myip=172.31.24.53 myport=8080
        # http://pintrest.com/index.html 140.105.225.106/- gustin GET myip=172.31.24.53 myport=8080
        line_fields = line.strip().split(' ')
        self.requested_url = line_fields[0]
        self.client_ip = line_fields[1].split('/')[0]
        self.username = line_fields[2]
        self.request_method = line.fields[3]
        self.requested_domain = _extract_domain_from_url(self.requested_url)
        
    def _extract_domain_from_url(self, url):
        # Thanks to: http://stackoverflow.com/a/21564306/5292928
        parse_result = urlparse(url) # From urllib.parse
        if parse_result.netloc != '':
            return parse_result.netloc
        else:
            # Happens if the url has no protocol
            # example: "facebook.com:443"
            return parse_result.path.split(':', 1)[0]
    

class SquidDatabaseAdapter(object):
    def __init__(self, db_access_controller, redirection_url):
        self.db_access_controller = db_access_controller
        self.squid_input_parser = SquidInputParser()
        self.redirection_url = redirection_url

    def allow_user(self):
        stdout.write("\n")
        stdout.flush()

    def redirect_user(self):
        stdout.write(self.redirection_url + "\n")
        stdout.flush()

    def cycle_over_stdin_lines(self):
        collect() # Garbage collection to reduce memory before starting cycling
        while True:
            line = stdin.readline()
            if not line:
                # Terminates execution in case of EOF
                break
            self.squid_input_parser.parse_squid_input_line(line)
            if db_access_controller.open_db_connection_if_closed() == False:
                allow_user() # in case of DB error, let user access any siteparse_squid_input_line(line)
                continue
            if db_access_controller.prepare_statement_if_not_already() == False:
                allow_user() # in case of DB error, let user access any siteparse_squid_input_line(line)
                continue
            if db_access_controller.is_user_allowed_to_domain(self.squid_input_parser.username, self.squid_input_parser.requested_domain):
                allow_user()
            else:
                redirect_user()
        if controller.close_db_connection_if_open() == False:
                

def parse_command_line_arguments():
    this_program_description = """\
Squid3 external ACL helper script to check if an authenticated user
is allowed to access a certain domain or not"""
    parser = argparse.ArgumentParser(description = this_program_description,
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("--db-user",
                        default = "squid",
                        help = "User for database access")
    parser.add_argument("--db-password",
                        default = "squidpostgresqlpw",
                        help = "Clear text password for database access")
    parser.add_argument("--db-host",
                        default = "localhost",
                        help = "Host of the database as DNS name or IP address")
    parser.add_argument("--db-name",
                        default = "squid",
                        help = "Name of the database to connect to")
    parser.add_argument("--db-table",
                        default = "incrementalproxy.vw_domains_per_user",
                        help = "Name of the table to select usernames and domains from")
    parser.add_argument("--col-domain",
                        default = "domain",
                        help = "Name of the column with the domains")
    parser.add_argument("--col-username",
                        default = "username",
                        help = "Name of the column with the usernames")
    arguments_dict = parser.parse_args()
    return arguments_dict

def main():
    args = parse_command_line_arguments()
    prepared_statement = "PREPARE user_domain_select (text, text) AS SELECT TRUE FROM {:s} WHERE {:s} = $1 AND $2 LIKE {:s};".format(args.db_table, args.col_username, args.col_domain)
    controller = DomainAccessControllerOnPostgreSql(args.db_host, args.db_name, args.db_user, args.db_password, prepared_statement)
    cycle_over_stdin_lines(controller)
    if controller.close_db_connection_if_open() == False:
        stdout.write(controller.error_string + "\n")
        stdout.flush()

if __name__ == "__main__":
    main()
