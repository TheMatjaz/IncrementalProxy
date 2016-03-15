#!/usr/bin/env python
 
import sys
def modify_url(line):
    list = line.split(' ')
    # first element of the list is the URL
    old_url = list[0]
    new_url = '\n'
    # take the decision and modify the url if needed
    # do remember that the new_url should contain a '\n' at the end.
    if old_url.find('pintrest.com') >= 0:
        new_url = 'http://proxy.matjaz.it/' + new_url
    return new_url
 
while True:
    # the format of the line read from stdin is
    # URL ip-address/fqdn ident method
    # for example
    # http://saini.co.in 172.17.8.175/saini.co.in - GET -
    line = sys.stdin.readline().strip()
    # new_url is a simple URL only
    # for example
    # http://fedora.co.in
    new_url = modify_url(line)
    sys.stdout.write(new_url)
    sys.stdout.flush()
