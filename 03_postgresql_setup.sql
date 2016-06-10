DELETE FROM incrementalproxy.users;
DELETE FROM incrementalproxy.domains;

INSERT INTO incrementalproxy.users (username, password, fullname, comment) VALUES
  , ('gustin', 'pwgustin', 'Matjaž Guštin', 'Admin')
  , ('davanzo', 'UnaPasswordACaso', 'Giorgio Davanzo', 'Professore')
  , ('jaka', 'thebestpasswordevar', 'Jaka Cikač', 'Beta tester')
    ;

INSERT INTO incrementalproxy.domains(domain, a_priori_status) VALUES
    ('facebook.com', 'denied')
  , ('google.com', 'allowed')
  , ('matjaz.it', 'allowed')
  , ('proxy.matjaz.it', 'allowed')
    ;

INSERT INTO incrementalproxy.vw_domains_per_user (username, domain, status) VALUES
    ('gustin', 'facebook.com', 'denied')
  , ('gustin', 'pintrest.com', 'denied')
  , ('gustin', 'matjaz.it', 'allowed')
  , ('gustin', 'proxy.matjaz.it', 'allowed')
  , ('davanzo', 'facebook.com', 'denied')
  , ('davanzo', 'twitter.com', 'denied')
  , ('davanzo', 'google.com', 'limbo')
    ;

