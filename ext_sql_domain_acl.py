#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Python3 Helper script for Squid3 to check if an authenticated user is
# allowed to access a certain domain or not

import psycopg2
import psycopg2.extensions
from urllib.parse import urlparse
from sys import stdin

class DomainAccessControllerOnPostgreSql(object):
    def __init__(self, persist_connection = True, db_host = "localhost", db_name = "squid", db_user = "squid", db_passwd = "squidpostgresqlpw"):
        self.persist_connection = persist_connection;
        self.connection = None
        self.db_host = "localhost"
        self.db_name = "squid"
        self.db_user = "squid"
        self.db_passwd = "squidpostgresqlpw"
        self.prepared_cursor = None
        self.error_string = None

    def open_db_connection_if_closed(self):
        if self.connection is None:
            db_connect_string = "host='{:s}' dbname='{:s}' user='{:s}' password='{:s}'".format(self.db_name, self.db_user, self.db_passwd, self.db_host)
            try:
                self.connection = psycopg2.connect(db_connect_string)
            except:
                self.error_string = "ERR Unable to connect to the database"
                self.connection = None # is this necessary? Just to be sure?
                return False
            return True
        else:
            return True


    def prepare_statement_if_not_already(self, statement):
        if self.prepared_cursor is not None:
            try:
                self.prepared_cursor = self.connection.cursor(cursor_factory = PreparingCursor)
            except:
                self.error_string = "ERR Unable to create cursor for prepared statement"
                return False
            try:
                self.prepared_cursor.prepare(statement)
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
            self.prepared_cursor.execute(username, domain)
        except:
            self.error_string = "ERR Unable to execute prepared statement"
            return False
        row = self.prepared_cursor.fetchone()
        if row is None:
            self.error_string = "ERR User is not allowed to this domain"
            return False
        else:
            # User is allowed
            # self.error_string = "OK" # Tags?
            return True

def extract_domain_from_url(url):
    # Thanks to: http://stackoverflow.com/a/21564306/5292928
    parse_result = urlparse(url) # From urllib.parse
    if parse_result.netloc != '':
        return parse_result.netloc
    else:
        # Probably happens if the url has no protocol
        # example: "facebook.com/messages/something.html"
        return parse_result.netloc.split('/', 1)[0]

def extract_domain_and_username_from_line(line):
    # The line is formatted as "URL username"
    # Example: "https://www.facebook.com/index.html?var=2 johndoe"
    url, username = line.strip().split(' ', 1)
    url = url.strip('%')
    username = url.strip('%')
    return extract_domain_from_url(url), username
        
def main():
    db_table = "incrementalproxy.vw_domains_per_user"
    db_username_column = "username"
    db_domain_column = "domain"
    prepared_statement = "SELECT TRUE FROM {:s} WHERE {:s} = %s AND %s LIKE {:s}".format(db_table, db_username_column, db_domain_column)
    controller = DomainAccessControllerOnPostgreSql()
    for line in stdin:
        if controller.open_db_connection_if_closed() == False:
            print(controller.error_string)
            continue
        domain, username = extract_domain_and_username_from_line(line)
        if controller.is_user_allowed_to_domain(username, domain):
            print("OK")
        else:
            print(controller.error_string)
        if controller.prepare_stament_if_not_already() == False:
            print(controller.error_string)
            continue
        if self.persist_connection == False:
            if controller.close_db_connection_if_open() == False:
                print(controller.error_string)
                continue

    
if __name__ == "__main__":
    main()
