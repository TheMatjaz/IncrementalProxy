TODO
====

- Squid authentication: http://www.webdnstools.com/articles/squid-proxy-authentication
https://workaround.org/squid-acls/
http://www.switchroot.com/how-to-configure-squid-to-authenticate-users
http://wiki.squid-cache.org/Features/Authentication#Proxy_Authentication
- Squid Helpers http://wiki.squid-cache.org/Features/AddonHelpers#Access_Control_.28ACL.29
- Config example http://wiki.squid-cache.org/ConfigExamples/Authenticate/Bypass

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
