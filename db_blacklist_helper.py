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
    def __init__(self, db_host, db_name, db_user, db_passwd, select_statement, insert_statement):
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

    def add_domain_to_users_limbo(self, username, domain):
        try:
            logging.debug("Executing prepared INSERT statement for user {:s} and domain {:s}".format(username, domain))
            execute_insert_statement_string = "EXECUTE insert_new_domain_for_user(%s, %s);"
            self.insert_cursor.execute(execute_insert_statement_string, (username, domain))
            return True
        except:
            logging.error("Unable to execute prepared INSERT statement")
            return False

    def is_user_allowed_to_domain(self, username, domain):
        try:
            logging.debug("Executing prepared SELECT statement for user {:s} and domain {:s}".format(username, domain))
            execute_select_statement_string = "EXECUTE status_for_user_on_domain (%s, %s);"
            self.select_cursor.execute(execute_select_statement_string, (username, domain))
        except:
            logging.error("Unable to execute prepared SELECT statement")
            return False
        row = self.select_cursor.fetchone()
        logging.debug("Fetched row from SELECT cursor: " + str(row))
        if row is None:
            # First time visit of this website for this user
            logging.info("User {:s} visits domain {:s} for the first time: adding entry with limbo status".format(username, domain))
            return self.add_domain_to_users_limbo(username, domain)
        else:
            # The domain is in the list for this user
            status = row[0]
            if status == "denied":
                logging.info("User {:s} is NOT allowed to domain {:s}".format(username, domain))
                return False
            else:
                logging.info("User {:s} is allowed to domain {:s} with status {:s}".format(username, domain, status))
                return True


class SquidInputParser(object):
    def __init__(self):
        logging.debug("Creating SquidInputParser")
        self.requested_url = None
        self.username = None
        self.client_ip = None
        self.request_method = None
        self.requested_domain = None

    def parse_squid_input_line(self, line):
        # Example input lines that Squid passes to the external redirector tool
        # URL <Space> client_ip "/" fqdn <Space> user <Space> method [<Space> kvpairs]<NL>
        #
        # pintrest.com:443 140.105.225.106/- gustin CONNECT myip=172.31.24.53 myport=8080
        # http://pintrest.com/ 140.105.225.106/- gustin GET myip=172.31.24.53 myport=8080
        # ftp://pintrest.com/ 140.105.225.106/- gustin GET myip=172.31.24.53 myport=8080
        # http://pintrest.com/index.html 140.105.225.106/- gustin GET myip=172.31.24.53 myport=8080
        logging.debug("Parsing Squid input line")
        line_fields = line.strip().split(' ')
        self.requested_url = line_fields[0]
        self.client_ip = line_fields[1].split('/')[0]
        self.username = line_fields[2]
        self.request_method = line_fields[3]
        self.requested_domain = self._extract_domain_from_url(self.requested_url)
        logging.debug("Requested url: {:s} and domain: {:s}".format(self.requested_url, self.requested_domain))
        
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
    

class SquidDatabaseAdapter(object):
    def __init__(self, db_access_controller, redirection_url):
        logging.debug("Creating SquidDatabaseAdapter")
        self.db_access_controller = db_access_controller
        self.squid_input_parser = SquidInputParser()
        self.redirection_url = redirection_url

    def allow_user(self):
        logging.debug("Flushing allowance to stdout")
        stdout.write("\n")
        stdout.flush()

    def redirect_user(self):
        logging.debug("Flushing redirection to stdout")
        stdout.write(self.redirection_url + "\n")
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
                self.allow_user() # in case of DB error, let user access any siteparse_squid_input_line(line)
                continue
            if self.db_access_controller.prepare_statement_if_not_already() == False:
                logging.error("Allowing user to domain anyways")
                self.allow_user() # in case of DB error, let user access any siteparse_squid_input_line(line)
                continue
            if self.db_access_controller.is_user_allowed_to_domain(self.squid_input_parser.username, self.squid_input_parser.requested_domain):
                self.allow_user()
            else:
                self.redirect_user()
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
    parser.add_argument("--redirection-url",
                        default = "http://proxy.matjaz.it/",
                        help = "URL where to redirect a user when accessing a denied domain")
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

def prepare_statements(args):
    prepared_select_statement = "PREPARE status_for_user_on_domain (text, text) AS SELECT status FROM {:s} WHERE {:s} = $1 AND {:s} = $2;".format(args.db_table, args.col_username, args.col_domain)
    logging.debug("Prepared select statement string {:s}".format(prepared_select_statement))
    prepared_insert_statement = "PREPARE insert_new_domain_for_user (text, text) AS INSERT INTO incrementalproxy.vw_domains_per_user ({:s}, {:s}, {:s}) VALUES ($1, $2, 'limbo');".format(args.col_username, args.col_domain, args.col_status)
    logging.debug("Prepared insert statement string {:s}".format(prepared_insert_statement))
    return prepared_select_statement, prepared_insert_statement
    
def main():
    args = parse_command_line_arguments()
    setup_logging(args)
    prepared_select_statement, prepared_insert_statement = prepare_statements(args)
    db_access_controller = DomainAccessControllerOnPostgreSql(args.db_host, args.db_name, args.db_user, args.db_password, prepared_select_statement, prepared_insert_statement)
    squid_db_adapter = SquidDatabaseAdapter(db_access_controller, args.redirection_url)
    squid_db_adapter.cycle_over_stdin_lines()

if __name__ == "__main__":
    main()
