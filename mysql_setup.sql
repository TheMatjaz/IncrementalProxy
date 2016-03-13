-- Mysql setup for Squid authentication
-- Docs: http://wiki.squid-cache.org/ConfigExamples/Authenticate/Mysql

CREATE DATABASE `squid`;

GRANT SELECT ON `squid`.* to `squid`@`localhost` IDENTIFIED BY 'squidpwtomysql';

USE `squid`;

CREATE TABLE `users` (
      `id`       INT(16)     NOT NULL AUTO_INCREMENT PRIMARY KEY
    , `user`     VARCHAR(32) NOT NULL UNIQUE
    , `password` VARCHAR(35) NOT NULL DEFAULT ''
    , `enabled`  TINYINT(1)  NOT NULL DEFAULT '1'
    , `fullname` VARCHAR(60)          DEFAULT NULL
    , `comment`  VARCHAR(60)          DEFAULT NULL
    );

INSERT INTO `users` (`user`, `password`, `fullname`, `comment`) VALUES
      ('testuser', 'test', 'Test user', 'for testing purpouse')
    ;

CREATE TABLE `domains` (
      `id`      INT(16)      NOT NULL AUTO_INCREMENT PRIMARY KEY
    , `domain`  VARCHAR(255) NOT NULL UNIQUE
    , `comment` VARCHAR(200) DEFAULT NULL
    );

INSERT INTO `domains` (`domain`) VALUES
      ('%facebook.com')
    , ('%twitter.com')
    , ('%pintrest.com')
    , ('%youtube.com')
    , ('%vimeo.com')
    ;

CREATE TABLE `domains_per_user` (
      `id` INT(16) NOT NULL AUTO_INCREMENT PRIMARY KEY
    , `fk_id_user` INT(16) NOT NULL REFERENCES `users`(`id`)
    , `fk_id_domain` INT(16) NOT NULL REFERENCES `domains`(`id`)
    , `status` ENUM('limbo', 'allowed', 'denied') DEFAULT NULL
    );

CREATE VIEW `vw_domains_per_user` AS 
    SELECT b.id
        ,  u.user
        ,  d.domain
        ,  d.status
        FROM `blacklist`    AS `b`
        LEFT JOIN `users`   AS `u` ON b.fk_id_user = u.id
        LEFT JOIN `domains_per_user` AS `d` ON b.fk_id_domain = d.id
    ;

INSERT INTO `domains_per_user` (`fk_id_user`, `fk_id_domain`) VALUES
      ((SELECT id FROM users WHERE user = 'gustin'), (SELECT id FROM domains WHERE domain = '%facebook.com'))
    , ((SELECT id FROM users WHERE user = 'gustin'), (SELECT id FROM domains WHERE domain = '%twitter.com'))
    , ((SELECT id FROM users WHERE user = 'davanzo'), (SELECT id FROM domains WHERE domain = '%facebook.com'))
    , ((SELECT id FROM users WHERE user = 'davanzo'), (SELECT id FROM domains WHERE domain = '%youtube.com'))
    ;

-- Find a blacklisted domain for a user
SELECT status
    FROM `vw_domains_per_user` AS `b`
    WHERE b.user = 'gustin'
        AND 'http://www.facebook.com' LIKE b.domain;

-- As prepared statement
SELECT status
    FROM `vw_domains_per_user` AS `b`
    WHERE b.user = ?
        AND ? LIKE b.domain;

-- Find domains in limbos per each user
SELECT id
    ,  user
    ,  domain
    FROM vw_domains_per_user
    WHERE status = 'limbo';

-- Set status of a domain per user
UPDATE domains_per_user
    SET status = ?
    WHERE 
    
