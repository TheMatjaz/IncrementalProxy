INSERT INTO incrementalproxy.users (username, password, fullname, comment) VALUES
    ('testuser', 'test', 'Mr. Test User', 'For testing purpouse')
  , ('testuser2', 'test', 'Mr. Test User 2', NULL)
    ;

INSERT INTO incrementalproxy.domains (domain) VALUES
    ('facebook.com')
  , ('twitter.com')
  , ('pintrest.com')
  , ('youtube.com')
  , ('vimeo.com')
    ;

INSERT INTO incrementalproxy.domains_per_user (fk_id_user, fk_id_domain) VALUES
    ((SELECT id FROM users WHERE username = 'gustin'), (SELECT id FROM domains WHERE domain = 'facebook.com'))
  , ((SELECT id FROM users WHERE username = 'gustin'), (SELECT id FROM domains WHERE domain = 'twitter.com'))
  , ((SELECT id FROM users WHERE username = 'davanzo'), (SELECT id FROM domains WHERE domain = 'facebook.com'))
  , ((SELECT id FROM users WHERE username = 'davanzo'), (SELECT id FROM domains WHERE domain = 'youtube.com'))
    ;
