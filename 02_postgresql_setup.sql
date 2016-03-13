-- postgresql_setup.sql

BEGIN;

CREATE ROLE squid 
    WITH LOGIN 
    ENCRYPTED PASSWORD 'squidpostgresqlpw';

CREATE SCHEMA IF NOT EXISTS incrementalproxy
    AUTHORIZATION squid;

-- Set the pg_hba.conf file to allow only localhost connections from 
-- the squid user: 
-- http://www.postgresql.org/docs/current/static/auth-pg-hba-conf.html

CREATE OR REPLACE FUNCTION incrementalproxy.is_empty(string text)
    RETURNS BOOLEAN
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT string ~ '^[[:space:]]*$';
    $body$;

DROP TABLE IF EXISTS incrementalproxy.users CASCADE;
CREATE TABLE incrementalproxy.users (
    id       smallserial   NOT NULL
  , username text     NOT NULL UNIQUE
  , password text     NOT NULL
  , enabled  boolean  NOT NULL DEFAULT TRUE
  , fullname text     DEFAULT  NULL
  , comment  text     DEFAULT  NULL

  , PRIMARY KEY (id)
  , CONSTRAINT password_not_empty
        CHECK (NOT incrementalproxy.is_empty(password))
  , CONSTRAINT username_length
        CHECK (length(username) < 200)
  , CONSTRAINT fullname_length
        CHECK (length(fullname) < 250)
    );

CREATE INDEX idx_user 
    ON incrementalproxy.users(username);

GRANT SELECT
    ON incrementalproxy.users
    TO squid;

DROP TABLE IF EXISTS incrementalproxy.domains CASCADE;
CREATE TABLE incrementalproxy.domains (
    id      serial NOT NULL
  , domain  text   NOT NULL UNIQUE
  , comment text   DEFAULT  NULL

  , PRIMARY KEY (id)
  , CONSTRAINT domain_not_empty
        CHECK (NOT incrementalproxy.is_empty(domain))
    );

GRANT SELECT, INSERT, UPDATE
    ON incrementalproxy.domains
    TO squid;

DROP TYPE IF EXISTS incrementalproxy.enum_domain_status CASCADE;
CREATE TYPE incrementalproxy.enum_domain_status AS ENUM (
    'never seen'
  , 'limbo'
  , 'allowed'
  , 'denied'
    );

DROP TABLE IF EXISTS incrementalproxy.domains_per_user CASCADE;
CREATE TABLE incrementalproxy.domains_per_user (
    id           serial             NOT NULL
  , fk_id_user   smallint           NOT NULL
  , fk_id_domain integer            NOT NULL
  , status       incrementalproxy.enum_domain_status DEFAULT 'never seen'

  , PRIMARY KEY (id)
  , FOREIGN KEY (fk_id_user)
        REFERENCES incrementalproxy.users(id)
        ON UPDATE CASCADE  -- When the user id is updated or removed
        ON DELETE CASCADE  -- update/delete his/her domains as well.
  , FOREIGN KEY (fk_id_domain)
        REFERENCES incrementalproxy.domains(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
    );

GRANT SELECT, INSERT, UPDATE, DELETE
    ON incrementalproxy.domains
    TO squid;

CREATE OR REPLACE VIEW incrementalproxy.vw_domains_per_user AS 
    SELECT dpu.id
        ,  u.username
        ,  d.domain
        ,  dpu.status
        FROM incrementalproxy.domains_per_user AS dpu
        INNER JOIN incrementalproxy.users AS u
            ON dpu.fk_id_user = u.id
        INNER JOIN incrementalproxy.domains AS d 
            ON dpu.fk_id_domain = d.id
    ;

--ROLLBACK;
COMMIT;
