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

CREATE OR REPLACE RULE insert_domains_to_vw
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
            ;
    );

CREATE OR REPLACE RULE update_domains_in_vw
    AS ON UPDATE
    TO incrementalproxy.vw_domains_per_user
    DO INSTEAD (
        UPDATE incrementalproxy.domains 
            SET domain = NEW.domain
            WHERE domain = OLD.domain
            ;
        UPDATE incrementalproxy.domains_per_user
            SET status = NEW.status
            WHERE fk_id_user = (SELECT id FROM incrementalproxy.users WHERE username = OLD.username)
                AND fk_id_domain = (SELECT id FROM incrementalproxy.domains WHERE domain = NEW.domain)
            ;
    );

CREATE OR REPLACE RULE delete_domains_from_vw
    AS ON DELETE
    TO incrementalproxy.vw_domains_per_user
    DO INSTEAD (
        DELETE FROM incrementalproxy.domains_per_user
            WHERE fk_id_user = (SELECT id FROM incrementalproxy.users WHERE username = OLD.username)
                AND fk_id_domain = (SELECT id FROM incrementalproxy.domains WHERE domain = OLD.domain)
            ;
    );

GRANT SELECT, INSERT, UPDATE, DELETE
    ON incrementalproxy.vw_domains_per_user
    TO squid;

--ROLLBACK;
COMMIT;