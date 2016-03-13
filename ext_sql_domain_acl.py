#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Python3 Helper script for Squid3 to check if an authenticated user is
# allowed to access a certain domain or not

import psycopg2
import psycopg2.extensions
from urllib.parse import urlparse
from sys import stdin

db_host = "localhost"
db_name = "squid"
db_user = "squid"
db_passwd = "squidpostgresqlpw"
db_table = "incrementalproxy.vw_domains_per_user"
db_username_column = "username"
db_domain_column = "domain"
db_connect_string = " host='{:s}' dbname='{:s}' user='{:s}' password='{:s}'".format(db_name, db_user, db_passwd, db_host)
prepared_sql_select = "SELECT TRUE FROM {:s} WHERE {:s} = %s AND %s LIKE {:s}".format(db_table, db_username_column, db_domain_column)

class PostgreSQLConnector(object):
    def __init__(self):
        self.persist_connection = True
        self.connection = None
        self.cursor = None
        self.prepared_cursor = None
        
    def open_db_connection(self):
        if self.connection is None:
            try:
                self.connection = psycopg2.connect(db_connect_string)
            except:
                print("ERR Unable to connect to the database")
                self.connection = None # is this necessary? Just to be sure?
                return
            try:
                self.cursor = self.connection.cursor()
            except:
                print("ERR Unable to create cursor")
            try:
                self.prepared_cursor = self.connection.cursor(cursor_factory = PreparingCursor)
            except:
                print("ERR Unable to create cursor for prepared statement")
            try:
                self.prepared_cursor.prepare(prepared_sql_select)
            except:
                print("ERR Unable to prepare statement")

    def close_db_connection(self):
        if self.connection is not None:
            self.cursor.close()
            self.prepared_cursor.close()
            self.connection.close()
            self.connection = None

    def is_user_allowed_to_domain(self, username, domain):
        try:
            self.prepared_cursor.execute(username, domain)
        except:
            print("ERR Unable to execute prepared statement")
            return
        row = self.prepared_cursor.fetchone()
        if row is None:
            print("ERR User is not allowed to this domain")
        else:
            print("OK") # user is allowed to this domain
        
def extract_domain_from_url(url):
    # Thanks to: http://stackoverflow.com/a/21564306/5292928
    parse_result = urlparse(url) # From urllib.parse
    if parse_result.netloc != '':
        return parse_result.netloc
    else:
        # Probably happens if the url has no protocol, like 'http://' or similar
        return parse_result.netloc.split('/')[0]
        
#def cycle_parsing_on_stdin():
#    for line in stdin:
    

def main():
    pgconnector = PostgreSQLConnector()
    pgconnector.open_db_connection()
    cycle_parsing_on_stdin()
    pgconnector.close_db_connection()

    
if __name__ == "__main__":
    main()
