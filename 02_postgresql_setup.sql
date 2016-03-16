-- postgresql_setup.sql

BEGIN;

DROP ROLE IF EXISTS squid;
CREATE ROLE squid 
    WITH LOGIN 
    ENCRYPTED PASSWORD 'squidpostgresqlpw';

DROP ROLE IF EXISTS squid_admin;
CREATE ROLE squid_admin
    WITH LOGIN
    ENCRYPTED PASSWORD 'squidadminpostgresqlpw';

CREATE SCHEMA IF NOT EXISTS incrementalproxy
    AUTHORIZATION squid_admin;

GRANT USAGE
    ON SCHEMA incrementalproxy
    TO squid;

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

CREATE OR REPLACE VIEW incrementalproxy.vw_users AS 
    SELECT u.username
        ,  u.password
        ,  u.enabled
        FROM incrementalproxy.users AS u
        WHERE u.enabled = TRUE;
    ;

-- Neede for BASIC authentication
GRANT SELECT
    ON incrementalproxy.vw_users
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

CREATE INDEX idx_domain
    ON incrementalproxy.domains(domain);

--GRANT SELECT, INSERT, UPDATE
--    ON incrementalproxy.domains
--    TO squid;

DROP TYPE IF EXISTS incrementalproxy.enum_domain_status CASCADE;
CREATE TYPE incrementalproxy.enum_domain_status AS ENUM (
    'limbo'
  , 'allowed'
  , 'denied'
    );

DROP TABLE IF EXISTS incrementalproxy.domains_per_user CASCADE;
CREATE TABLE incrementalproxy.domains_per_user (
    id           serial             NOT NULL
  , fk_id_user   smallint           NOT NULL
  , fk_id_domain integer            NOT NULL
  , status       incrementalproxy.enum_domain_status NOT NULL DEFAULT 'limbo'

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

--GRANT SELECT, INSERT, UPDATE
--    ON incrementalproxy.domains
--    TO squid;

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

CREATE OR REPLACE RULE insert_domains_for_user
    AS ON INSERT
    TO incrementalproxy.vw_domains_per_user
    DO INSTEAD (
        INSERT INTO incrementalproxy.domains (domain) VALUES
            (NEW.domain)
            ON CONFLICT DO NOTHING
            ;
        INSERT INTO incrementalproxy.domains_per_user
            (fk_id_user, fk_id_domain, status) VALUES
            ((SELECT id FROM incrementalproxy.users WHERE username = NEW.username)
              , (SELECT id FROM incrementalproxy.domains WHERE domain = NEW.domain)
              , (NEW.status))
            ON CONFLICT DO NOTHING
            ;
    );

CREATE OR REPLACE RULE update_domains_for_user
    AS ON UPDATE
    TO incrementalproxy.vw_domains_per_user
    DO INSTEAD (
        INSERT INTO incrementalproxy.domains (domain) VALUES
            (NEW.domain)
            ON CONFLICT DO NOTHING
            ;
        UPDATE incrementalproxy.domains_per_user
            SET status = NEW.status
            WHERE fk_id_user = (SELECT id FROM incrementalproxy.users WHERE username = OLD.username)
                AND fk_id_domain = (SELECT id FROM incrementalproxy.domains WHERE domain = NEW.domain)
            ;
    );

CREATE OR REPLACE RULE delete_domains_for_user
    AS ON DELETE
    TO incrementalproxy.vw_domains_per_user
    DO INSTEAD (
        DELETE FROM incrementalproxy.domains_per_user
            WHERE fk_id_user = (SELECT id FROM incrementalproxy.users WHERE username = OLD.username)
                AND fk_id_domain = (SELECT id FROM incrementalproxy.domains WHERE domain = OLD.domain)
            ;
    );

GRANT SELECT, INSERT
    ON incrementalproxy.vw_domains_per_user
    TO squid;

GRANT USAGE,SELECT
    ON ALL SEQUENCES
    IN SCHEMA incrementalproxy
    TO squid;

--ROLLBACK;
COMMIT;
