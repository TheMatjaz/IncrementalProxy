#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Testing script to understand how and what Squid passes to an external_acl
# helper script

from sys import stdin
from urllib.parse import urlparse

def extract_domain_from_url(url):
    # Thanks to: http://stackoverflow.com/a/21564306/5292928
    parse_result = urlparse(url) # From urllib.parse
    if parse_result.netloc != '':
        return parse_result.netloc
    else:
        # Probably happens if the url has no protocol
        # example: "facebook.com/messages/something.html"
        return parse_result.path.split('/', 1)[0]

def extract_domain_and_username_from_line(line):
    # The line is formatted as "URL username"
    # Example: "https://www.facebook.com/index.html?var=2 johndoe"
    url, username = line.strip().split(' ', 1)
    url = url.strip('%')
    username = username.strip('%')
    return extract_domain_from_url(url), username


logfile = open("/tmp/squidhelper.log", 'a')
for line in stdin:
    logfile.write(line)
    domain, username = extract_domain_and_username_from_line(line)
    logfile.write(domain + " " + username)
    print("OK")

logfile.close()
