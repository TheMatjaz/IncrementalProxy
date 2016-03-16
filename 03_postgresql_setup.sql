DELETE FROM incrementalproxy.users;
DELETE FROM incrementalproxy.domains;

INSERT INTO incrementalproxy.users (username, password, fullname, comment) VALUES
    ('testuser', 'test', 'Mr. Test User', 'For testing purpouse')
  , ('testuser2', 'test', 'Mr. Test User 2', NULL)
  , ('gustin', 'pwgustin', 'Matjaž Guštin', 'Admin')
  , ('davanzo', 'UnaPasswordACaso', 'Giorgio Davanzo', 'Professore')
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

