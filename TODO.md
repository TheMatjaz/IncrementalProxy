TODO
====

- http://www.switchroot.com/how-to-configure-squid-to-authenticate-users
- http://wiki.squid-cache.org/Features/Authentication#Proxy_Authentication
- Squid Helpers http://wiki.squid-cache.org/Features/AddonHelpers#Access_Control_.28ACL.29
- Config example http://wiki.squid-cache.org/ConfigExamples/Authenticate/Bypass
- Logging to DB for accesses on the table (a trigger on the domains_per_user view)
- strip leading www from domain
- table for webUI administrators logins
- md5 for logins: users AND admins. Use md5 for both username + password( + salt?)
- custom error page for unathenticated users. When login fails, show this page. Should be ERR_something
- timestamps when a domains is added?
- log tables for any changes in the vw_domains_per_user
- check the connection.status value instead of using the "is None" condition -> does not work! Issue a stupid query "SELECT 1;": http://stackoverflow.com/questions/1281875/making-sure-that-psycopg2-database-connection-alive <- THIS IS VERY IMPORTANT! 



- `update incrementalproxy.vw_domains_per_user set status = 'allowed' where id = 2;`
- `update incrementalproxy.vw_domains_per_user set status = 'allowed' where domain like '%google.%';`



Sinteza celotnega projekta
==========================

- L'utente richiede un nuovo sito web mai richiesto in precedenza: gli è permesso e viene aggiunto a `domains_per_user` con status `limbo`
- L'amministratore del proxy ogni tanto controlla questa tabella per regolare quali domini sono permessi a quali utenti
- Esiste una tabella di domini bloccati per tutti: in questo modo per ogni nuovo utente registrato, c'è un trigger che aggiunge tutti questi siti alla tabella `domains_per_user` per quell'utente con status `denied`
- Esiste una tabella di domini permessi per tutti, analogamente al punto precendente.
- Quanto un utente vuole accedere ad un sito bloccato, esso deve andare su `http://proxy.matjaz.it`, inserire il dominio che vuole visitare, con il tempo di sblocco e la motivazione
- Esiste una tabella `reasons_for_unlock` che contiene le colonne `user`, `domain`, `reason`, `unlock_starttime`, `unlock_endtime` nella quale vengono salvate le motivazioni. Quando una motivazione viene scritta, viene automaticamente inserita in questa tabella. La colonna `status` di quel `domain_per_user` viene modificata in `unlock`. Nella stessa tabella c'è anche una FK alla `reason_for_unlock`.
- Ad ogni richiesta, se lo status è `unlock`, viene controllato l'`unlock_endtime`. Se è passato, lo status viene cambiato in `denied` e la FK a `unlock_endtime` viene posta a NULL. Altrimenti lo stato non viene modificato e la richiesta viene approvata.



CANCELED
========

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
- Installed "cpan -i DBD::Pg" to use Postgresql for authentication instead of Mysql
- https://gofedora.com/how-to-write-custom-redirector-rewritor-plugin-squid-python/
- https://www.safaribooksonline.com/library/view/squid-the-definitive/0596001622/ch12s05.html
- http://etutorials.org/Server+Administration/Squid.+The+definitive+guide/Chapter+12.+Authentication+Helpers/12.5+External+ACLs/
- Authentication via PostgreSQL
- Remove "%" character removal from %URL
- looks like the insertions queries are not working: autocommit you idiot!
- https://gofedora.com/how-to-write-custom-redirector-rewritor-plugin-squid-python/
- Logging to file and DB for the helper script
- Check the status column
- http://www.squid-cache.org/Versions/v3/3.3/cfgman/url_rewrite_program.html                                        
- Use an URL rewriter instead of an allower? Apparently the user can be passed to an URL rewriter - just make the python script check the DB and let it pass or rewrite the URL to something else. The page is directly the administration page of the proxy, where one can insert records in the limbo. The URL rewriter is easier to setup than the ACL. This allows an external ACL managment, basically with a clean rewriting if needed. Still wont work for HTTPS without bumping SSL, which we won't do.
