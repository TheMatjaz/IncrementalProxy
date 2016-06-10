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

DROP TYPE IF EXISTS incrementalproxy.enum_domain_status CASCADE;
CREATE TYPE incrementalproxy.enum_domain_status AS ENUM (
    'limbo'
  , 'allowed'
  , 'denied'
  , 'banned'
    );

DROP TABLE IF EXISTS incrementalproxy.domains CASCADE;
CREATE TABLE incrementalproxy.domains (
    id      serial NOT NULL
  , domain  text   NOT NULL UNIQUE
  , a_priori_status incrementalproxy.enum_domain_status NOT NULL DEFAULT 'allowed'
  , comment text   DEFAULT  NULL

  , PRIMARY KEY (id)
  , CONSTRAINT domain_not_empty
        CHECK (NOT incrementalproxy.is_empty(domain))
    );

CREATE INDEX idx_domain
    ON incrementalproxy.domains(domain);


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

DROP TABLE IF EXISTS incrementalproxy.domain_unlocks CASCADE;
CREATE TABLE incrementalproxy.domain_unlocks (
    id           serial             NOT NULL
  , fk_id_domains_per_user integer NOT NULL
  , reason       text
  , unlock_start timestamptz NOT NULL DEFAULT current_timestamp
  , unlock_end   timestamptz NOT NULL DEFAULT current_timestamp + '1 hour'::interval

  , PRIMARY KEY (id)
  , FOREIGN KEY (fk_id_domains_per_user)
        REFERENCES incrementalproxy.domains_per_user(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
  , CONSTRAINT unlock_end_after_start
        CHECK (unlock_end > unlock_start)
    );

    
CREATE OR REPLACE VIEW incrementalproxy.vw_domains_per_user AS 
    SELECT dpu.id
        ,  u.username
        ,  d.domain
        ,  dpu.status
        ,  un.unlock_end
        FROM incrementalproxy.domains_per_user AS dpu
        INNER JOIN incrementalproxy.users AS u
            ON dpu.fk_id_user = u.id
        INNER JOIN incrementalproxy.domains AS d 
            ON dpu.fk_id_domain = d.id
        LEFT JOIN (
            SELECT fk_id_domains_per_user
                ,  max(unlock_end) AS unlock_end
                FROM incrementalproxy.domain_unlocks
                GROUP BY fk_id_domains_per_user
            ) AS un
            ON dpu.id = un.fk_id_domains_per_user
    ;

CREATE OR REPLACE VIEW incrementalproxy.vw_domain_unlocks AS 
    SELECT du.id
        ,  dpu.username
        ,  dpu.domain
        ,  dpu.status
        ,  du.reason
        ,  du.unlock_start
        ,  du.unlock_end
        FROM incrementalproxy.domain_unlocks AS du
        INNER JOIN incrementalproxy.vw_domains_per_user AS dpu
            ON dpu.id = du.fk_id_domains_per_user
    ;

GRANT INSERT
    ON incrementalproxy.vw_domain_unlocks
    TO squid;


CREATE OR REPLACE FUNCTION incrementalproxy.tgfun_insert_domain_for_user()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    SECURITY DEFINER
    AS $body$
    BEGIN
        INSERT INTO incrementalproxy.domains
            (domain, a_priori_status) VALUES
            (NEW.domain, DEFAULT)
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


CREATE OR REPLACE FUNCTION incrementalproxy.tgfun_update_domain_permission_per_user()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $body$
    BEGIN
        UPDATE incrementalproxy.domains_per_user
          SET status = NEW.status
          WHERE id = OLD.id;
        RETURN NEW;
    END;
    $body$;

CREATE TRIGGER tg_on_update_status_vw_domains_per_user
    INSTEAD OF UPDATE
    ON incrementalproxy.vw_domains_per_user
    FOR EACH ROW
    EXECUTE PROCEDURE incrementalproxy.tgfun_update_domain_permission_per_user();


CREATE OR REPLACE FUNCTION incrementalproxy.tgfun_insert_domain_unlock()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    SECURITY DEFINER
    AS $body$
    BEGIN
        INSERT INTO incrementalproxy.vw_domains_per_user
            (username, domain, status) VALUES
            (NEW.username, NEW.domain, 'denied')
            ON CONFLICT DO NOTHING
            ;
        INSERT INTO incrementalproxy.domain_unlocks (fk_id_domains_per_user, reason, unlock_end) VALUES
            ((SELECT id FROM incrementalproxy.vw_domains_per_user WHERE username = NEW.username AND domain = NEW.domain)
              , NEW.reason
              , NEW.unlock_end)
            ON CONFLICT DO NOTHING
            ;
        RETURN NEW;
    END;
    $body$;

CREATE TRIGGER tg_on_insert_vw_domain_unlocks
    INSTEAD OF INSERT
    ON incrementalproxy.vw_domain_unlocks
    FOR EACH ROW
    EXECUTE PROCEDURE incrementalproxy.tgfun_insert_domain_unlock();


CREATE OR REPLACE FUNCTION incrementalproxy.is_allowed_to_domain(par_username text, par_domain text)
    RETURNS RECORD
    LANGUAGE plpgsql
    SECURITY DEFINER
    AS $body$
    DECLARE
        var_status text;
        var_unlock_end timestamptz;
        returnable RECORD;
    BEGIN
        SELECT status, unlock_end
        INTO var_status, var_unlock_end
        FROM incrementalproxy.vw_domains_per_user
        WHERE username = par_username
            AND domain = par_domain;
        IF var_status = 'banned' THEN
            SELECT FALSE, 'banned forever on this domain' INTO returnable;
        ELSIF var_status = 'denied' AND var_unlock_end IS NULL THEN
            SELECT FALSE, 'forbidden domain' INTO returnable;
        ELSIF var_status = 'denied' AND var_unlock_end IS NOT NULL THEN
            IF var_unlock_end > current_timestamp THEN
                SELECT TRUE, 'unlocked temporarly' INTO returnable;
            ELSE
                SELECT FALSE, 'temporary unlock expired' INTO returnable;
            END IF;
        ELSIF var_status = 'limbo' THEN
            SELECT TRUE, 'allowed but pending for approval' INTO returnable;
        ELSIF var_status = 'allowed' THEN
            SELECT TRUE, 'allowed permanently' INTO returnable;
        ELSIF var_status IS NULL THEN
            SELECT TRUE, 'first visit: allowed' INTO returnable;
        ELSE
            SELECT TRUE, 'internal error: allowed' INTO returnable;
        END IF;
        RETURN returnable;
    END;
    $body$;

GRANT EXECUTE
    ON FUNCTION incrementalproxy.is_allowed_to_domain(text, text)
    TO squid;
    
GRANT SELECT, INSERT
    ON incrementalproxy.vw_domains_per_user
    TO squid;

GRANT USAGE, SELECT
    ON ALL SEQUENCES
    IN SCHEMA incrementalproxy
    TO squid;

GRANT SELECT, INSERT, UPDATE, DELETE
    ON ALL TABLES
    IN SCHEMA incrementalproxy
    TO squid_admin;

--ROLLBACK;
COMMIT;
