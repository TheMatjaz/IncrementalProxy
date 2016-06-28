#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Testing script to understand how and what Squid passes to an external_acl
# helper script

from sys import stdin, stdout
from urllib.parse import urlparse
import datetime

def extract_domain_from_url(url):
    # Thanks to: http://stackoverflow.com/a/21564306/5292928
    parse_result = urlparse(url) # From urllib.parse
    if parse_result.netloc != '':
        return parse_result.netloc
    else:
        # Probably happens if the url has no protocol
        # example: "facebook.com/messages/something.html"
        return parse_result.path.split('/', 1)[0]

def extract_fields_from_line(line):
    # The line is formatted as "URL username"
    # Example: "https://www.facebook.com/index.html?var=2 johndoe"
    url, username, request, referer = line.strip().split(' ', 3)
    return url, username, referer

logfile = open("/tmp/squidhelper.log", 'a')

while True:
    line = stdin.readline()
    if not line:
        # EOF
        break
    logfile.write("LINE> " + line)
    domain, username, referer = extract_fields_from_line(line)
    logfile.write("RSLT> " + str(datetime.datetime.now()) + ", Domain: " + domain + ", Username: " + username + ", Referer: " + referer + "\n")
    logfile.flush()
    if domain.find("f") >=0 and referer == "-":
        stdout.write('OK status=307 url="http://localhost:20080/"\n')
    else:
        stdout.write("OK\n")
    stdout.flush()

logfile.close()
