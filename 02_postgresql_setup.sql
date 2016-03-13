-- postgresql_setup.sql

BEGIN;

CREATE ROLE squid 
    WITH LOGIN 
    ENCRYPTED PASSWORD 'squidpostgresqlpw';

CREATE SCHEMA IF NOT EXISTS squid
    AUTHORIZATION squid;

-- Set the pg_hba.conf file to allow only localhost connections from 
-- the squid user: 
-- http://www.postgresql.org/docs/current/static/auth-pg-hba-conf.html

CREATE OR REPLACE FUNCTION squid.is_empty(string text)
    RETURNS BOOLEAN
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT string ~ '^[[:space:]]*$';
    $body$;

DROP TABLE IF EXISTS squid.users CASCADE;
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

CREATE INDEX squid.idx_user 
    ON users(user);

GRANT SELECT
    ON squid.users
    TO squid;

INSERT INTO squid.users (user, password, fullname, comment) VALUES
    ('testuser', 'test', 'Mr. Test User', 'For testing purpouse')
  , ('testuser2', 'test', 'Mr. Test User 2', NULL)
    ;

DROP TABLE IF EXISTS squid.domains CASCADE;
CREATE TABLE squid.domains (
    id      serial NOT NULL
  , domain  text   NOT NULL UNIQUE
  , comment text   DEFAULT  NULL

    PRIMARY KEY (id)
  , CONSTRAINT domain_not_empty
        CHECK (NOT is_empty(domain))
    );

GRANT SELECT, INSERT, UPDATE
    ON squid.domains
    TO squid.squid;

INSERT INTO squid.domains (domain) VALUES
    ('%facebook.com')
  , ('%twitter.com')
  , ('%pintrest.com')
  , ('%youtube.com')
  , ('%vimeo.com')
    ;

DROP TYPE IF EXISTS squid.enum_domain_status CASCADE;
CREATE TYPE squid.enum_domain_status AS ENUM (
    'never seen'
  , 'limbo'
  , 'allowed'
  , 'denied'
    );

DROP TABLE IF NOT EXISTS squid.domains_per_user CASCADE;
CREATE TABLE squid.domains_per_user (
    id           serial             NOT NULL
  , fk_id_user   smallint           NOT NULL
  , fk_id_domain integer            NOT NULL
  , status       enum_domain_status DEFAULT 'never seen'

    PRIMARY KEY (id)
  , FOREIGN KEY (fk_id_user)
        REFERENCES squid.users(id)
        ON UPDATE CASCADE  -- When the user id is updated or removed
        ON DELETE CASCADE  -- update/delete his/her domains as well.
  , FOREIGN KEY (fk_id_domain)
        REFERENCES squid.domains(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
  , CONSTRAINT domain_not_empty
        CHECK (NOT is_empty(domain))
    );

GRANT SELECT, INSERT, UPDATE
    ON squid.domains
    TO squid.squid;

CREATE OR REPLACE VIEW squid.vw_domains_per_user AS 
    SELECT dpu.id
        ,  u.user
        ,  d.domain
        ,  d.status
        FROM squid.domains_per_user AS dpu
        LEFT JOIN squid.users AS u
            ON dpu.fk_id_user = us.id
        LEFT JOIN squid.domains AS d 
            ON dpu.fk_id_domain = d.id
    ;

--ROLLBACK;
COMMIT;
