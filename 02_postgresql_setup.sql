-- postgresql_setup.sql

BEGIN;


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
        FROM incrementalproxy.users AS u
        WHERE u.enabled = TRUE;
    ;

-- Needed for BASIC authentication
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
  , CONSTRAINT unique_user_domain_pair
        UNIQUE (fk_id_user, fk_id_domain)
    );


CREATE OR REPLACE VIEW incrementalproxy.vw_domains_per_user AS 
    SELECT u.username
        ,  d.domain
        ,  dpu.status
        FROM incrementalproxy.domains_per_user AS dpu
        INNER JOIN incrementalproxy.users AS u
            ON dpu.fk_id_user = u.id
        INNER JOIN incrementalproxy.domains AS d 
            ON dpu.fk_id_domain = d.id
    ;

CREATE OR REPLACE FUNCTION incrementalproxy.tgfun_insert_domain_for_user()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    SECURITY DEFINER
    AS $body$
    BEGIN
        INSERT INTO incrementalproxy.domains
            (domain) VALUES
            (NEW.domain)
            ON CONFLICT DO NOTHING
            ;
        INSERT INTO incrementalproxy.domains_per_user (fk_id_user, fk_id_domain, status) VALUES
            ((SELECT id FROM incrementalproxy.users WHERE username = NEW.username)
              , (SELECT id FROM incrementalproxy.domains WHERE domain = NEW.domain)
              , NEW.status)
            ON CONFLICT DO NOTHING
            ;
        RETURN NEW;
    END;
    $body$;

CREATE TRIGGER tg_on_insert_vw_domains_per_user
    INSTEAD OF INSERT
    ON incrementalproxy.vw_domains_per_user
    FOR EACH ROW
    EXECUTE PROCEDURE incrementalproxy.tgfun_insert_domain_for_user();

--GRANT EXECUTE
--    ON FUNCTION incrementalproxy.tgfun_insert_domain_for_user()
--    TO squid;
    
GRANT SELECT, INSERT
    ON incrementalproxy.vw_domains_per_user
    TO squid;

GRANT USAGE, SELECT
    ON ALL SEQUENCES
    IN SCHEMA incrementalproxy
    TO squid;

GRANT USAGE, SELECT, INSERT, UPDATE, DELETE
    ON ALL TABLES
    IN SCHEMA incrementalproxy
    TO squid_admin;

--ROLLBACK;
COMMIT;
