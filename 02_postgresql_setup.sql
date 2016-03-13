-- postgresql_setup.sql

BEGIN;

CREATE ROLE squid 
    WITH LOGIN 
    ENCRYPTED PASSWORD 'squidpostgresqlpw';

-- Set the pg_hba.conf file to allow only localhost connections from 
-- the squid user: 
-- http://www.postgresql.org/docs/current/static/auth-pg-hba-conf.html

GRANT SELECT, INSERT, UPDATE
    ON DATABASE squid
    TO squid;

CREATE OR REPLACE FUNCTION is_empty(string text)
    RETURNS BOOLEAN
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT string ~ '^[[:space:]]*$';
    $body$;

DROP TABLE IF EXISTS users CASCADE;
CREATE TABLE users (
    id       smallserial   NOT NULL
  , user     text     NOT NULL UNIQUE
  , password text     NOT NULL
  , enabled  boolean  NOT NULL DEFAULT TRUE
  , fullname text     DEFAULT  NULL
  , comment  text     DEFAULT  NULL

    PRIMARY KEY (id)
  , CONSTRAINT password_not_empty
        CHECK (NOT is_empty(password))
  , CONSTRAINT user_name_length
        CHECK (length(user) < 200)
  , CONSTRAINT fullname_length
        CHECK (length(fullname) < 250)
    );

CREATE INDEX idx_user 
    ON users(user);

INSERT INTO users (user, password, fullname, comment) VALUES
    ('testuser', 'test', 'Mr. Test User', 'For testing purpouse')
  , ('testuser2', 'test', 'Mr. Test User 2', NULL)
    ;

DROP TABLE IF EXISTS domains CASCADE;
CREATE TABLE domains (
    id      serial NOT NULL
  , domain  text   NOT NULL UNIQUE
  , comment text   DEFAULT  NULL

    PRIMARY KEY (id)
  , CONSTRAINT domain_not_empty
        CHECK (NOT is_empty(domain))
    );

INSERT INTO domains (domain) VALUES
    ('%facebook.com')
  , ('%twitter.com')
  , ('%pintrest.com')
  , ('%youtube.com')
  , ('%vimeo.com')
    ;

DROP TYPE IF EXISTS enum_domain_status CASCADE;
CREATE TYPE enum_domain_status AS ENUM (
    'never seen'
  , 'limbo'
  , 'allowed'
  , 'denied'
    );

DROP TABLE IF NOT EXISTS domains_per_user CASCADE;
CREATE TABLE domains_per_user (
    id           serial             NOT NULL
  , fk_id_user   smallint           NOT NULL
  , fk_id_domain integer            NOT NULL
  , status       enum_domain_status DEFAULT 'never seen'

    PRIMARY KEY (id)
  , FOREIGN KEY (fk_id_user)
        REFERENCES users(id)
        ON UPDATE CASCADE  -- When the user id is updated or removed
        ON DELETE CASCADE  -- update/delete his/her domains as well.
  , FOREIGN KEY (fk_id_domain)
        REFERENCES domains(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
  , CONSTRAINT domain_not_empty
        CHECK (NOT is_empty(domain))
    );

CREATE OR REPLACE VIEW vw_domains_per_user AS 
    SELECT dpu.id
        ,  u.user
        ,  d.domain
        ,  d.status
        FROM domains_per_user AS dpu
        LEFT JOIN users AS u
            ON dpu.fk_id_user = us.id
        LEFT JOIN domains AS d 
            ON dpu.fk_id_domain = d.id
    ;

--ROLLBACK;
COMMIT;
