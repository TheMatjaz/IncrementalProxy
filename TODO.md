TODO
====

- http://www.switchroot.com/how-to-configure-squid-to-authenticate-users
- http://wiki.squid-cache.org/Features/Authentication#Proxy_Authentication
- Squid Helpers http://wiki.squid-cache.org/Features/AddonHelpers#Access_Control_.28ACL.29
- Config example http://wiki.squid-cache.org/ConfigExamples/Authenticate/Bypassù
- HTTPS connections

DONE
====

- Start a AWS EC2 instance, update it, upgrade it, install swap (2 GB), install Squid3 and lighttpd
- Add elastic IP address to instance
- Add nashira.matjaz.it subdomain that links to elastic IP
- Make squid run on 8080 (http://www.webdnstools.com/articles/installing-squid-proxy-server)
- Open port 8080 in the EC2 firewall
- Add whitelist (http://www.webdnstools.com/articles/squid-proxy-whitelist)
http://www.switchroot.com/how-to-configure-squid-proxy-server-centos-fedora-or-rhel
- Mysql DB preparation for authentication: http://wiki.squid-cache.org/ConfigExamples/Authenticate/Mysql
- Testing the proxy with Basic authentication: https://addons.mozilla.org/en-gb/firefox/addon/foxyproxy-standard/
  `curl -x http://proxy.matjaz.it:8080 --proxy-user gustin:pwgustin --proxy-basic -L http://wikipedia.org`
- Basic authentication working correctly
- `sudo ln -s /home/ubuntu/Development/IncrementalProxy/squid.conf /etc/squid3/squid.conf` symbolic link of the config file to the one in the git repository
- Domains whitelist in git repo
- Custom error pages setup http://www.thedumbterminal.co.uk/posts/2005/11/changing_squid_error_pages.html
- Squid authentication: http://www.webdnstools.com/articles/squid-proxy-authentication
https://workaround.org/squid-acls/
- Activate caching
- CPAN -i URI to install the URI Perl Module
- Awesome PostgreSQL database to store the allowed/denied/limbo domains per each user
- Enabled PG access from anywhere to DB squid and user squid
