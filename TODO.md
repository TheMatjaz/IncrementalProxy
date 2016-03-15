TODO
====

- http://www.switchroot.com/how-to-configure-squid-to-authenticate-users
- http://wiki.squid-cache.org/Features/Authentication#Proxy_Authentication
- Squid Helpers http://wiki.squid-cache.org/Features/AddonHelpers#Access_Control_.28ACL.29
- Config example http://wiki.squid-cache.org/ConfigExamples/Authenticate/Bypassù
- HTTPS connections
- Check the status column
- Tag messages in error responses
- Logging to file and DB for the helper script
- Logging to DB for accesses on the table (a trigger on the domains_per_user view)
- Remove "%" character removal from %URL
- http://www.squid-cache.org/Versions/v3/3.3/cfgman/url_rewrite_program.html

Use an URL rewriter instead of an allower? Apparently the user can be passed to an URL rewriter - just make the python script check the DB and let it pass or rewrite the URL to something else. The page is directly the administration page of the proxy, where one can insert records in the limbo.
The URL rewriter is easier to setup than the ACL. This allows an external ACL managment, basically with a clean rewriting if needed. Still wont work for HTTPS without bumping SSL, which we won't do.
- https://gofedora.com/how-to-write-custom-redirector-rewritor-plugin-squid-python/


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
- Installed "cpan -i DBD::Pg" to use Postgresql for authentication instead of Mysql
- https://gofedora.com/how-to-write-custom-redirector-rewritor-plugin-squid-python/
- https://www.safaribooksonline.com/library/view/squid-the-definitive/0596001622/ch12s05.html
- http://etutorials.org/Server+Administration/Squid.+The+definitive+guide/Chapter+12.+Authentication+Helpers/12.5+External+ACLs/
- Authentication via PostgreSQL
