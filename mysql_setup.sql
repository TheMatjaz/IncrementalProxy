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

CREATE TABLE `blacklist` (
      `id` INT(16) NOT NULL AUTO_INCREMENT PRIMARY KEY
    , `fk_id_user` INT(16) NOT NULL REFERENCES `users`(`id`)
    , `fk_id_domain` INT(16) NOT NULL REFERENCES `domains`(`id`)
    );

CREATE VIEW `vw_blacklist` AS 
    SELECT b.id
        ,  u.user
        ,  d.domain
        FROM `blacklist`     AS `b`
        LEFT JOIN `users`   AS `u` ON b.fk_id_user = u.id
        LEFT JOIN `domains` AS `d` ON b.fk_id_domain = d.id
    ;

INSERT INTO `blacklist` (`fk_id_user`, `fk_id_domain`) VALUES
      ((SELECT id FROM users WHERE user = 'gustin'), (SELECT id FROM domains WHERE domain = '%facebook.com'))
    , ((SELECT id FROM users WHERE user = 'gustin'), (SELECT id FROM domains WHERE domain = '%twitter.com'))
    , ((SELECT id FROM users WHERE user = 'davanzo'), (SELECT id FROM domains WHERE domain = '%facebook.com'))
    , ((SELECT id FROM users WHERE user = 'davanzo'), (SELECT id FROM domains WHERE domain = '%youtube.com'))
    ;

-- Find a blacklisted domain for a user
SELECT TRUE AS blacklisted
    FROM `vw_blacklist` AS `b`
    WHERE b.user = 'gustin'
        AND 'http://www.facebook.com' LIKE b.domain;

-- As prepared statement
SELECT TRUE AS blacklisted
    FROM `vw_blacklist` AS `b`
    WHERE b.user = ?
        AND ? LIKE b.domain;
