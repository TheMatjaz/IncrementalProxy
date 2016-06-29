#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Squid3 external ACL helper script to check if an authenticated user is allowed
# to access a certain domain or not

import psycopg2
from urllib.parse import urlparse
from sys import stdin, stdout
import argparse
from gc import collect
import logging


class DomainAccessControllerOnPostgreSql(object):
    """Keeps an active connection to the given DB, rechecking it at each query 
    it performs."""
    def __init__(self, db_host, db_name, db_user, db_passwd, select_statement, 
                insert_statement):
        logging.debug("Creating DomainAccessControllerOnPostgreSql")
        self.connection = None
        self.db_host = db_host
        self.db_name = db_name
        self.db_user = db_user
        self.db_passwd = db_passwd
        self.prepared_select_statement = select_statement
        self.prepared_insert_statement = insert_statement
        self.select_cursor = None
        self.insert_cursor = None

    def open_db_connection_if_closed(self):
        if self.connection is None:
            db_connect_string = "host='{:s}' dbname='{:s}' user='{:s}' password='{:s}'".format(self.db_host, self.db_name, self.db_user, self.db_passwd)
            try:
                logging.info("Creating connection to database")
                self.connection = psycopg2.connect(db_connect_string)
                self.connection.set_session(autocommit = True)
            except:
                logging.error("Unable to connect to the database " + db_connect_string)
                self.connection = None # is this necessary? Just to be sure?
                return False
            return True
        else:
            logging.debug("Database connection existing, skipping creation")
            return True

    def prepare_statement_if_not_already(self):
        if self.select_cursor is None:
            try:
                logging.debug("Creating database cursors")
                self.select_cursor = self.connection.cursor()
                self.insert_cursor = self.connection.cursor()
            except:
                logging.error("Unable to create cursors")
                return False
            try:
                logging.debug("Preparing SELECT statement")
                self.select_cursor.execute(self.prepared_select_statement)
            except:
                logging.error("Unable to prepare SELECT statement")
                return False
            try:
                logging.debug("Preparing INSERT statement")
                self.insert_cursor.execute(self.prepared_insert_statement)
            except:
                logging.error("Unable to prepare INSERT statement")
                return False
            return True
        else:
            logging.debug("Cursors already exist, skipping preparation")
            return True
    
    def close_db_connection_if_open(self):
        if self.connection is not None:
            logging.info("Closing database connection")
            try:
                self.select_cursor.close()
                self.insert_cursor.close()
            except:
                logging.error("Unable to close cursors")
                return False
            try:
                self.connection.close()
            except:
                logging.error("Unable to close connection")
                return False
            return True
        else:
            logging.debug("Database connection already closed, skipping")
            return True

    def is_user_allowed_to_domain(self, username, domain):
        if domain == 'proxy.matjaz.it':
            return True, "proxy.matjaz.it is always allowed"
        try:
            logging.debug("Executing prepared SELECT statement for user {:s} and domain {:s}".format(username, domain))
            execute_select_statement_string = "EXECUTE is_allowed (%s, %s);"
            self.select_cursor.execute(execute_select_statement_string, (username, domain))
        except:
            logging.error("Unable to execute prepared SELECT statement")
            return False
        row = self.select_cursor.fetchone()
        logging.debug("Fetched row from SELECT cursor: " + str(row))
        if row is None:
            # Internal error
            logging.error("Fetched row is empty for unknown reasons")
        else:
            response = row[0]
            if response == None or response == '':
                response = 'error'
            if response == 'allowed' or response == 'limbo' or response == 'unlocked' or response == 'error':
                logging.info("User {:s} is allowed to domain {:s}. Reason: {:s}".format(username, domain, response))
                return True, response
            else:
                logging.info("User {:s} is NOT allowed to domain {:s}. Reason: {:s}".format(username, domain, response))
                return False, response


class SquidInputParser(object):
    def __init__(self):
        logging.debug("Creating SquidInputParser")
        self.requested_url = None
        self.username = None
        self.referer = None
        self.mimetype = None
        self.requested_domain = None
        self.mimetype_is_html = None

    def parse_squid_input_line(self, line):
        # Example input lines that Squid passes to the external redirector tool
        # URL username request_method referer\n
        # http://matjaz.it/ gustin - text/html;%20encoding=utf-8\n
        # http://matjaz.it/style.css gustin http://matjaz.it/ text/css
        logging.debug("Parsing Squid input line")
        line_fields = line.strip().split(' ')
        self.requested_url = line_fields[0]
        self.username = line_fields[1]
        self.referer = line_fields[2]
        self.mimetype = line_fields[3]
        self.requested_domain = self._extract_domain_from_url(self.requested_url)
        logging.debug("Requested url: {:s} and domain: {:s}, referer: {:s}, mime type {:s}".format(self.requested_url, self.requested_domain, self.referer, self.mimetype))
        self.mimetype_is_html = (self.mimetype.lower().find('html') >= 0)
        
    def _extract_domain_from_url(self, url):
        # Thanks to: http://stackoverflow.com/a/21564306/5292928
        parse_result = urlparse(url) # From urllib.parse
        logging.debug("Extracting domain")
        if parse_result.netloc != '':
            return parse_result.netloc
        else:
            # Happens if the url has no protocol
            # example: "facebook.com:443"
            return parse_result.path.split(':', 1)[0]
    

class SquidToThisScriptAdapter(object):
    def __init__(self, db_access_controller):
        logging.debug("Creating SquidToThisScriptAdapter")
        self.db_access_controller = db_access_controller
        self.squid_input_parser = SquidInputParser()

    def allow_user(self, reason):
        logging.debug("Flushing allowance to stdout")
        stdout.write('OK message="' + reason + '"\n')
        stdout.flush()

    def redirect_user(self, reason):
        logging.debug("Flushing redirection to stdout")
        stdout.write('ERR message="'+ reason +'"\n')
        stdout.flush()

    def cycle_over_stdin_lines(self):
        collected_obj = collect() # Garbage collection to reduce memory before starting cycling
        logging.info("{:d} objects cleaned by garbage collector. Staring cycles on stdin, waiting for Squid input".format(collected_obj))
        while True:
            line = stdin.readline()
            logging.debug("Reading line from stdin: {:s}".format(line.strip()))
            if not line:
                # Terminates execution in case of EOF
                logging.warning("EOF on stdin. Terminating.")
                break
            self.squid_input_parser.parse_squid_input_line(line)
            if self.db_access_controller.open_db_connection_if_closed() == False:
                logging.error("Allowing user to domain anyways")
                self.allow_user(reason="error") # in case of DB error, let user access any siteparse_squid_input_line(line)
                continue
            if self.db_access_controller.prepare_statement_if_not_already() == False:
                logging.error("Allowing user to domain anyways")
                self.allow_user(reason="error") # in case of DB error, let user access any siteparse_squid_input_line(line)
                continue
            if self.squid_input_parser.referer != '-' and not self.squid_input_parser.mimetype_is_html:
                # This is a resource or download of a page, so is allowed by default without logging in the DB
                logging.info("Resource is allowed: {:s}".format(self.squid_input_parser.requested_url))
                self.allow_user(reason="resource")
                continue
            is_allowed, reason = self.db_access_controller.is_user_allowed_to_domain(self.squid_input_parser.username, self.squid_input_parser.requested_domain)
            if is_allowed:
                self.allow_user(reason)
            else:
                self.redirect_user(reason)
        self.db_access_controller.close_db_connection_if_open()
                

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
                        help = "Name of the column with the domains in the table")
    parser.add_argument("--col-username",
                        default = "username",
                        help = "Name of the column with the usernames in the table")
    parser.add_argument("--col-status",
                        default = "status",
                        help = "Name of the column with the status of a domain per user in the table")
    parser.add_argument("--loglevel",
                        default = "INFO",
                        help = "Details being logged. Levels are DEBUG, INFO, WARNING, ERROR")
    parser.add_argument("--logfile",
                        default = "/tmp/db_blacklist_helper.log",
                        help = "File to store logs of this program into. If not writable, the default value is used.")

    arguments_dict = parser.parse_args()
    return arguments_dict

def setup_logging(args):
    writable = True
    logfile = args.logfile
    try:
        logfile = open(args.logfile, 'a')
        logfile.close()
    except PermissionError:
        args.logfile = "/tmp/db_blacklist_helper.log"
        writable = False
    logging.basicConfig(filename = args.logfile, level = args.loglevel.upper(), format = '%(asctime)s | %(levelname)s | %(message)s')
    logging.info("==== NEW START ====")
    logging.info("Setting debug level to {:s}".format(args.loglevel.upper()))
    if not writable:
        logging.warning("Logfile {:s} was not writable. Fallback to {:s}".format(logfile, args.logfile))
    logging.debug("Line arguments are: " + str(args))

def prepare_sql_statements(args):
    prepared_select_statement = "PREPARE is_allowed (text, text) AS SELECT incrementalproxy.is_allowed_to_domain($1, $2);"
    logging.debug("Prepared select statement string {:s}".format(prepared_select_statement))
    prepared_insert_statement = "PREPARE insert_new_domain_for_user (text, text) AS INSERT INTO incrementalproxy.vw_domains_per_user ({:s}, {:s}, {:s}) VALUES ($1, $2, 'limbo');".format(args.col_username, args.col_domain, args.col_status)
    logging.debug("Prepared insert statement string {:s}".format(prepared_insert_statement))
    return prepared_select_statement, prepared_insert_statement
    
def main():
    args = parse_command_line_arguments()
    setup_logging(args)
    prepared_select_statement, prepared_insert_statement = prepare_sql_statements(args)
    db_access_controller = DomainAccessControllerOnPostgreSql(args.db_host, args.db_name, args.db_user, args.db_password, prepared_select_statement, prepared_insert_statement)
    squid_db_adapter = SquidToThisScriptAdapter(db_access_controller)
    squid_db_adapter.cycle_over_stdin_lines()

if __name__ == "__main__":
    main()
