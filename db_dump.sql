--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.2
-- Dumped by pg_dump version 9.5.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE IF EXISTS squid;
--
-- Name: squid; Type: DATABASE; Schema: -; Owner: matjaz
--

CREATE DATABASE squid WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'it_IT.UTF-8' LC_CTYPE = 'it_IT.UTF-8';


ALTER DATABASE squid OWNER TO matjaz;

\connect squid

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: incrementalproxy; Type: SCHEMA; Schema: -; Owner: squid_admin
--

CREATE SCHEMA incrementalproxy;


ALTER SCHEMA incrementalproxy OWNER TO squid_admin;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = incrementalproxy, pg_catalog;

--
-- Name: enum_domain_status; Type: TYPE; Schema: incrementalproxy; Owner: matjaz
--

CREATE TYPE enum_domain_status AS ENUM (
    'limbo',
    'allowed',
    'denied',
    'banned'
);


ALTER TYPE enum_domain_status OWNER TO matjaz;

--
-- Name: is_allowed_to_domain(text, text); Type: FUNCTION; Schema: incrementalproxy; Owner: matjaz
--

CREATE FUNCTION is_allowed_to_domain(par_username text, par_domain text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
    DECLARE
        var_status text;
        var_unlock_end timestamptz;
    BEGIN
        SELECT status, unlock_end
        INTO var_status, var_unlock_end
        FROM incrementalproxy.vw_domains_per_user
        WHERE username = par_username
            AND domain = par_domain;
        IF var_status = 'banned' THEN
            RETURN 'banned';
        ELSIF var_status = 'denied' AND var_unlock_end IS NULL THEN
            RETURN 'denied';
        ELSIF var_status = 'denied' AND var_unlock_end IS NOT NULL THEN
            IF var_unlock_end > current_timestamp THEN
                RETURN 'unlocked';
            ELSE
                RETURN 'expired';
            END IF;
        ELSIF var_status = 'limbo' THEN
            RETURN 'limbo';
        ELSIF var_status = 'allowed' THEN
            RETURN 'allowed';
        ELSIF var_status IS NULL THEN
            RETURN 'first';
        ELSE
            RETURN 'error';
        END IF;
    END;
    $$;


ALTER FUNCTION incrementalproxy.is_allowed_to_domain(par_username text, par_domain text) OWNER TO matjaz;

--
-- Name: is_empty(text); Type: FUNCTION; Schema: incrementalproxy; Owner: matjaz
--

CREATE FUNCTION is_empty(string text) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
        SELECT string ~ '^[[:space:]]*$';
    $_$;


ALTER FUNCTION incrementalproxy.is_empty(string text) OWNER TO matjaz;

--
-- Name: tgfun_insert_domain_for_user(); Type: FUNCTION; Schema: incrementalproxy; Owner: matjaz
--

CREATE FUNCTION tgfun_insert_domain_for_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
    $$;


ALTER FUNCTION incrementalproxy.tgfun_insert_domain_for_user() OWNER TO matjaz;

--
-- Name: tgfun_insert_domain_unlock(); Type: FUNCTION; Schema: incrementalproxy; Owner: matjaz
--

CREATE FUNCTION tgfun_insert_domain_unlock() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
    $$;


ALTER FUNCTION incrementalproxy.tgfun_insert_domain_unlock() OWNER TO matjaz;

--
-- Name: tgfun_update_domain_permission_per_user(); Type: FUNCTION; Schema: incrementalproxy; Owner: matjaz
--

CREATE FUNCTION tgfun_update_domain_permission_per_user() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        UPDATE incrementalproxy.domains_per_user
          SET status = NEW.status
          WHERE id = OLD.id;
        RETURN NEW;
    END;
    $$;


ALTER FUNCTION incrementalproxy.tgfun_update_domain_permission_per_user() OWNER TO matjaz;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: domain_unlocks; Type: TABLE; Schema: incrementalproxy; Owner: matjaz
--

CREATE TABLE domain_unlocks (
    id integer NOT NULL,
    fk_id_domains_per_user integer NOT NULL,
    reason text,
    unlock_start timestamp with time zone DEFAULT now() NOT NULL,
    unlock_end timestamp with time zone DEFAULT (now() + '01:00:00'::interval) NOT NULL,
    CONSTRAINT unlock_end_after_start CHECK ((unlock_end > unlock_start))
);


ALTER TABLE domain_unlocks OWNER TO matjaz;

--
-- Name: domain_unlocks_id_seq; Type: SEQUENCE; Schema: incrementalproxy; Owner: matjaz
--

CREATE SEQUENCE domain_unlocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE domain_unlocks_id_seq OWNER TO matjaz;

--
-- Name: domain_unlocks_id_seq; Type: SEQUENCE OWNED BY; Schema: incrementalproxy; Owner: matjaz
--

ALTER SEQUENCE domain_unlocks_id_seq OWNED BY domain_unlocks.id;


--
-- Name: domains; Type: TABLE; Schema: incrementalproxy; Owner: matjaz
--

CREATE TABLE domains (
    id integer NOT NULL,
    domain text NOT NULL,
    a_priori_status enum_domain_status DEFAULT 'allowed'::enum_domain_status NOT NULL,
    comment text,
    CONSTRAINT domain_not_empty CHECK ((NOT is_empty(domain)))
);


ALTER TABLE domains OWNER TO matjaz;

--
-- Name: domains_id_seq; Type: SEQUENCE; Schema: incrementalproxy; Owner: matjaz
--

CREATE SEQUENCE domains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE domains_id_seq OWNER TO matjaz;

--
-- Name: domains_id_seq; Type: SEQUENCE OWNED BY; Schema: incrementalproxy; Owner: matjaz
--

ALTER SEQUENCE domains_id_seq OWNED BY domains.id;


--
-- Name: domains_per_user; Type: TABLE; Schema: incrementalproxy; Owner: matjaz
--

CREATE TABLE domains_per_user (
    id integer NOT NULL,
    fk_id_user smallint NOT NULL,
    fk_id_domain integer NOT NULL,
    status enum_domain_status DEFAULT 'limbo'::enum_domain_status NOT NULL
);


ALTER TABLE domains_per_user OWNER TO matjaz;

--
-- Name: domains_per_user_id_seq; Type: SEQUENCE; Schema: incrementalproxy; Owner: matjaz
--

CREATE SEQUENCE domains_per_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE domains_per_user_id_seq OWNER TO matjaz;

--
-- Name: domains_per_user_id_seq; Type: SEQUENCE OWNED BY; Schema: incrementalproxy; Owner: matjaz
--

ALTER SEQUENCE domains_per_user_id_seq OWNED BY domains_per_user.id;


--
-- Name: users; Type: TABLE; Schema: incrementalproxy; Owner: matjaz
--

CREATE TABLE users (
    id smallint NOT NULL,
    username text NOT NULL,
    password text NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    fullname text,
    comment text,
    CONSTRAINT fullname_length CHECK ((length(fullname) < 250)),
    CONSTRAINT password_not_empty CHECK ((NOT is_empty(password))),
    CONSTRAINT username_length CHECK ((length(username) < 200))
);


ALTER TABLE users OWNER TO matjaz;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: incrementalproxy; Owner: matjaz
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE users_id_seq OWNER TO matjaz;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: incrementalproxy; Owner: matjaz
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: vw_domains_per_user; Type: VIEW; Schema: incrementalproxy; Owner: matjaz
--

CREATE VIEW vw_domains_per_user AS
 SELECT dpu.id,
    u.username,
    d.domain,
    dpu.status,
    un.unlock_end
   FROM (((domains_per_user dpu
     JOIN users u ON ((dpu.fk_id_user = u.id)))
     JOIN domains d ON ((dpu.fk_id_domain = d.id)))
     LEFT JOIN ( SELECT domain_unlocks.fk_id_domains_per_user,
            max(domain_unlocks.unlock_end) AS unlock_end
           FROM domain_unlocks
          GROUP BY domain_unlocks.fk_id_domains_per_user) un ON ((dpu.id = un.fk_id_domains_per_user)));


ALTER TABLE vw_domains_per_user OWNER TO matjaz;

--
-- Name: vw_domain_unlocks; Type: VIEW; Schema: incrementalproxy; Owner: matjaz
--

CREATE VIEW vw_domain_unlocks AS
 SELECT du.id,
    dpu.username,
    dpu.domain,
    dpu.status,
    du.reason,
    du.unlock_start,
    du.unlock_end
   FROM (domain_unlocks du
     JOIN vw_domains_per_user dpu ON ((dpu.id = du.fk_id_domains_per_user)));


ALTER TABLE vw_domain_unlocks OWNER TO matjaz;

--
-- Name: vw_users; Type: VIEW; Schema: incrementalproxy; Owner: matjaz
--

CREATE VIEW vw_users AS
 SELECT u.username,
    u.password
   FROM users u
  WHERE (u.enabled = true);


ALTER TABLE vw_users OWNER TO matjaz;

--
-- Name: id; Type: DEFAULT; Schema: incrementalproxy; Owner: matjaz
--

ALTER TABLE ONLY domain_unlocks ALTER COLUMN id SET DEFAULT nextval('domain_unlocks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: incrementalproxy; Owner: matjaz
--

ALTER TABLE ONLY domains ALTER COLUMN id SET DEFAULT nextval('domains_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: incrementalproxy; Owner: matjaz
--

ALTER TABLE ONLY domains_per_user ALTER COLUMN id SET DEFAULT nextval('domains_per_user_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: incrementalproxy; Owner: matjaz
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Data for Name: domain_unlocks; Type: TABLE DATA; Schema: incrementalproxy; Owner: matjaz
--

INSERT INTO domain_unlocks VALUES (1, 3, 'Testing triggers', '2016-06-10 21:08:11.300956+00', '2016-06-10 21:13:11.300956+00');


--
-- Name: domain_unlocks_id_seq; Type: SEQUENCE SET; Schema: incrementalproxy; Owner: matjaz
--

SELECT pg_catalog.setval('domain_unlocks_id_seq', 1, true);


--
-- Data for Name: domains; Type: TABLE DATA; Schema: incrementalproxy; Owner: matjaz
--

INSERT INTO domains VALUES (6, 'facebook.com', 'denied', NULL);
INSERT INTO domains VALUES (7, 'google.com', 'allowed', NULL);
INSERT INTO domains VALUES (8, 'matjaz.it', 'allowed', NULL);
INSERT INTO domains VALUES (9, 'proxy.matjaz.it', 'allowed', NULL);
INSERT INTO domains VALUES (11, 'pintrest.com', 'allowed', NULL);
INSERT INTO domains VALUES (15, 'twitter.com', 'allowed', NULL);
INSERT INTO domains VALUES (18, 'cdn.jsdelivr.net', 'allowed', NULL);
INSERT INTO domains VALUES (19, 's0.wp.com', 'allowed', NULL);
INSERT INTO domains VALUES (20, 'www.youtube.com', 'allowed', NULL);
INSERT INTO domains VALUES (21, 'i.ytimg.com', 'allowed', NULL);
INSERT INTO domains VALUES (22, 'yt3.ggpht.com', 'allowed', NULL);
INSERT INTO domains VALUES (23, 'trello.com', 'allowed', NULL);
INSERT INTO domains VALUES (24, 'www.facebook.com', 'allowed', NULL);
INSERT INTO domains VALUES (25, 'fbstatic-a.akamaihd.net', 'allowed', NULL);
INSERT INTO domains VALUES (27, 'www.pinterest.com', 'allowed', NULL);
INSERT INTO domains VALUES (28, 's-passets-cache-ak0.pinimg.com', 'allowed', NULL);
INSERT INTO domains VALUES (29, 's-media-cache-ak0.pinimg.com', 'allowed', NULL);
INSERT INTO domains VALUES (30, 'ocsp.digicert.com', 'allowed', NULL);


--
-- Name: domains_id_seq; Type: SEQUENCE SET; Schema: incrementalproxy; Owner: matjaz
--

SELECT pg_catalog.setval('domains_id_seq', 30, true);


--
-- Data for Name: domains_per_user; Type: TABLE DATA; Schema: incrementalproxy; Owner: matjaz
--

INSERT INTO domains_per_user VALUES (2, 1, 6, 'denied');
INSERT INTO domains_per_user VALUES (3, 1, 11, 'denied');
INSERT INTO domains_per_user VALUES (4, 1, 8, 'allowed');
INSERT INTO domains_per_user VALUES (5, 1, 9, 'allowed');
INSERT INTO domains_per_user VALUES (6, 2, 6, 'denied');
INSERT INTO domains_per_user VALUES (7, 2, 15, 'denied');
INSERT INTO domains_per_user VALUES (8, 2, 7, 'limbo');
INSERT INTO domains_per_user VALUES (9, 1, 15, 'limbo');
INSERT INTO domains_per_user VALUES (10, 1, 18, 'limbo');
INSERT INTO domains_per_user VALUES (11, 1, 19, 'limbo');
INSERT INTO domains_per_user VALUES (12, 1, 20, 'limbo');
INSERT INTO domains_per_user VALUES (13, 1, 21, 'limbo');
INSERT INTO domains_per_user VALUES (14, 1, 22, 'limbo');
INSERT INTO domains_per_user VALUES (15, 1, 23, 'limbo');
INSERT INTO domains_per_user VALUES (16, 1, 24, 'limbo');
INSERT INTO domains_per_user VALUES (17, 1, 25, 'limbo');
INSERT INTO domains_per_user VALUES (19, 1, 27, 'limbo');
INSERT INTO domains_per_user VALUES (20, 1, 28, 'limbo');
INSERT INTO domains_per_user VALUES (21, 1, 29, 'limbo');
INSERT INTO domains_per_user VALUES (22, 1, 30, 'limbo');


--
-- Name: domains_per_user_id_seq; Type: SEQUENCE SET; Schema: incrementalproxy; Owner: matjaz
--

SELECT pg_catalog.setval('domains_per_user_id_seq', 22, true);


--
-- Data for Name: users; Type: TABLE DATA; Schema: incrementalproxy; Owner: matjaz
--

INSERT INTO users VALUES (1, 'gustin', 'pwgustin', true, 'Matjaž Guštin', 'Admin');
INSERT INTO users VALUES (2, 'davanzo', 'UnaPasswordACaso', true, 'Giorgio Davanzo', 'Professore');
INSERT INTO users VALUES (3, 'jaka', 'thebestpasswordevar', true, 'Jaka Cikač', 'Beta tester');


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: incrementalproxy; Owner: matjaz
--

SELECT pg_catalog.setval('users_id_seq', 3, true);


--
-- Name: domain_unlocks_pkey; Type: CONSTRAINT; Schema: incrementalproxy; Owner: matjaz
--

ALTER TABLE ONLY domain_unlocks
    ADD CONSTRAINT domain_unlocks_pkey PRIMARY KEY (id);


--
-- Name: domains_domain_key; Type: CONSTRAINT; Schema: incrementalproxy; Owner: matjaz
--

ALTER TABLE ONLY domains
    ADD CONSTRAINT domains_domain_key UNIQUE (domain);


--
-- Name: domains_per_user_pkey; Type: CONSTRAINT; Schema: incrementalproxy; Owner: matjaz
--

ALTER TABLE ONLY domains_per_user
    ADD CONSTRAINT domains_per_user_pkey PRIMARY KEY (id);


--
-- Name: domains_pkey; Type: CONSTRAINT; Schema: incrementalproxy; Owner: matjaz
--

ALTER TABLE ONLY domains
    ADD CONSTRAINT domains_pkey PRIMARY KEY (id);


--
-- Name: unique_user_domain_pair; Type: CONSTRAINT; Schema: incrementalproxy; Owner: matjaz
--

ALTER TABLE ONLY domains_per_user
    ADD CONSTRAINT unique_user_domain_pair UNIQUE (fk_id_user, fk_id_domain);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: incrementalproxy; Owner: matjaz
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users_username_key; Type: CONSTRAINT; Schema: incrementalproxy; Owner: matjaz
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: idx_domain; Type: INDEX; Schema: incrementalproxy; Owner: matjaz
--

CREATE INDEX idx_domain ON domains USING btree (domain);


--
-- Name: idx_user; Type: INDEX; Schema: incrementalproxy; Owner: matjaz
--

CREATE INDEX idx_user ON users USING btree (username);


--
-- Name: tg_on_insert_vw_domain_unlocks; Type: TRIGGER; Schema: incrementalproxy; Owner: matjaz
--

CREATE TRIGGER tg_on_insert_vw_domain_unlocks INSTEAD OF INSERT ON vw_domain_unlocks FOR EACH ROW EXECUTE PROCEDURE tgfun_insert_domain_unlock();


--
-- Name: tg_on_insert_vw_domains_per_user; Type: TRIGGER; Schema: incrementalproxy; Owner: matjaz
--

CREATE TRIGGER tg_on_insert_vw_domains_per_user INSTEAD OF INSERT ON vw_domains_per_user FOR EACH ROW EXECUTE PROCEDURE tgfun_insert_domain_for_user();


--
-- Name: tg_on_update_status_vw_domains_per_user; Type: TRIGGER; Schema: incrementalproxy; Owner: matjaz
--

CREATE TRIGGER tg_on_update_status_vw_domains_per_user INSTEAD OF UPDATE ON vw_domains_per_user FOR EACH ROW EXECUTE PROCEDURE tgfun_update_domain_permission_per_user();


--
-- Name: domain_unlocks_fk_id_domains_per_user_fkey; Type: FK CONSTRAINT; Schema: incrementalproxy; Owner: matjaz
--

ALTER TABLE ONLY domain_unlocks
    ADD CONSTRAINT domain_unlocks_fk_id_domains_per_user_fkey FOREIGN KEY (fk_id_domains_per_user) REFERENCES domains_per_user(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: domains_per_user_fk_id_domain_fkey; Type: FK CONSTRAINT; Schema: incrementalproxy; Owner: matjaz
--

ALTER TABLE ONLY domains_per_user
    ADD CONSTRAINT domains_per_user_fk_id_domain_fkey FOREIGN KEY (fk_id_domain) REFERENCES domains(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: domains_per_user_fk_id_user_fkey; Type: FK CONSTRAINT; Schema: incrementalproxy; Owner: matjaz
--

ALTER TABLE ONLY domains_per_user
    ADD CONSTRAINT domains_per_user_fk_id_user_fkey FOREIGN KEY (fk_id_user) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: incrementalproxy; Type: ACL; Schema: -; Owner: squid_admin
--

REVOKE ALL ON SCHEMA incrementalproxy FROM PUBLIC;
REVOKE ALL ON SCHEMA incrementalproxy FROM squid_admin;
GRANT ALL ON SCHEMA incrementalproxy TO squid_admin;
GRANT USAGE ON SCHEMA incrementalproxy TO squid;


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: domain_unlocks; Type: ACL; Schema: incrementalproxy; Owner: matjaz
--

REVOKE ALL ON TABLE domain_unlocks FROM PUBLIC;
REVOKE ALL ON TABLE domain_unlocks FROM matjaz;
GRANT ALL ON TABLE domain_unlocks TO matjaz;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE domain_unlocks TO squid_admin;


--
-- Name: domain_unlocks_id_seq; Type: ACL; Schema: incrementalproxy; Owner: matjaz
--

REVOKE ALL ON SEQUENCE domain_unlocks_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE domain_unlocks_id_seq FROM matjaz;
GRANT ALL ON SEQUENCE domain_unlocks_id_seq TO matjaz;
GRANT SELECT,USAGE ON SEQUENCE domain_unlocks_id_seq TO squid;


--
-- Name: domains; Type: ACL; Schema: incrementalproxy; Owner: matjaz
--

REVOKE ALL ON TABLE domains FROM PUBLIC;
REVOKE ALL ON TABLE domains FROM matjaz;
GRANT ALL ON TABLE domains TO matjaz;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE domains TO squid_admin;


--
-- Name: domains_id_seq; Type: ACL; Schema: incrementalproxy; Owner: matjaz
--

REVOKE ALL ON SEQUENCE domains_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE domains_id_seq FROM matjaz;
GRANT ALL ON SEQUENCE domains_id_seq TO matjaz;
GRANT SELECT,USAGE ON SEQUENCE domains_id_seq TO squid;


--
-- Name: domains_per_user; Type: ACL; Schema: incrementalproxy; Owner: matjaz
--

REVOKE ALL ON TABLE domains_per_user FROM PUBLIC;
REVOKE ALL ON TABLE domains_per_user FROM matjaz;
GRANT ALL ON TABLE domains_per_user TO matjaz;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE domains_per_user TO squid_admin;


--
-- Name: domains_per_user_id_seq; Type: ACL; Schema: incrementalproxy; Owner: matjaz
--

REVOKE ALL ON SEQUENCE domains_per_user_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE domains_per_user_id_seq FROM matjaz;
GRANT ALL ON SEQUENCE domains_per_user_id_seq TO matjaz;
GRANT SELECT,USAGE ON SEQUENCE domains_per_user_id_seq TO squid;


--
-- Name: users; Type: ACL; Schema: incrementalproxy; Owner: matjaz
--

REVOKE ALL ON TABLE users FROM PUBLIC;
REVOKE ALL ON TABLE users FROM matjaz;
GRANT ALL ON TABLE users TO matjaz;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE users TO squid_admin;


--
-- Name: users_id_seq; Type: ACL; Schema: incrementalproxy; Owner: matjaz
--

REVOKE ALL ON SEQUENCE users_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE users_id_seq FROM matjaz;
GRANT ALL ON SEQUENCE users_id_seq TO matjaz;
GRANT SELECT,USAGE ON SEQUENCE users_id_seq TO squid;


--
-- Name: vw_domains_per_user; Type: ACL; Schema: incrementalproxy; Owner: matjaz
--

REVOKE ALL ON TABLE vw_domains_per_user FROM PUBLIC;
REVOKE ALL ON TABLE vw_domains_per_user FROM matjaz;
GRANT ALL ON TABLE vw_domains_per_user TO matjaz;
GRANT SELECT,INSERT ON TABLE vw_domains_per_user TO squid;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE vw_domains_per_user TO squid_admin;


--
-- Name: vw_domain_unlocks; Type: ACL; Schema: incrementalproxy; Owner: matjaz
--

REVOKE ALL ON TABLE vw_domain_unlocks FROM PUBLIC;
REVOKE ALL ON TABLE vw_domain_unlocks FROM matjaz;
GRANT ALL ON TABLE vw_domain_unlocks TO matjaz;
GRANT INSERT ON TABLE vw_domain_unlocks TO squid;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE vw_domain_unlocks TO squid_admin;


--
-- Name: vw_users; Type: ACL; Schema: incrementalproxy; Owner: matjaz
--

REVOKE ALL ON TABLE vw_users FROM PUBLIC;
REVOKE ALL ON TABLE vw_users FROM matjaz;
GRANT ALL ON TABLE vw_users TO matjaz;
GRANT SELECT ON TABLE vw_users TO squid;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE vw_users TO squid_admin;


--
-- PostgreSQL database dump complete
--

