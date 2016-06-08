-- DATABASE SETUP
DROP DATABASE IF EXISTS squid;
CREATE DATABASE squid
    OWNER = matjaz
    ENCODING = 'UTF8'
    LC_COLLATE = 'it_IT.UTF-8'
    LC_CTYPE = 'it_IT.UTF-8'
    CONNECTION LIMIT = 1000
    TEMPLATE = template0
    ;


DROP ROLE IF EXISTS squid;
CREATE ROLE squid 
    WITH LOGIN 
    ENCRYPTED PASSWORD 'squidpostgresqlpw';

DROP ROLE IF EXISTS squid_admin;
CREATE ROLE squid_admin
    WITH LOGIN
    ENCRYPTED PASSWORD 'squidadminpostgresqlpw';
