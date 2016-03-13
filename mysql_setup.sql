-- Mysql setup for Squid authentication
-- Docs: http://wiki.squid-cache.org/ConfigExamples/Authenticate/Mysql

CREATE DATABASE `squid`;

GRANT SELECT ON `squid`.* to `squid`@`localhost` IDENTIFIED BY 'squidpwtomysql';

USE `squid`;

CREATE TABLE `passwd` (
      `user`     VARCHAR(32) NOT NULL DEFAULT ''
    , `password` VARCHAR(35) NOT NULL DEFAULT ''
    , `enabled`  TINYINT(1)  NOT NULL DEFAULT '1'
    , `fullname` VARCHAR(60)          DEFAULT NULL
    , `comment`  VARCHAR(60)          DEFAULT NULL
    
    PRIMARY KEY (`user`)
    );

INSERT INTO `passwd` VALUES
    ('testuser','test',1,'Test User','for testing purpose');

CREATE TABLE `blacklist` (
      `id`      INT(16)      NOT NULL AUTO_INCREMENT PRIMARY KEY
    , `domain`  VARCHAR(255) NOT NULL UNIQUE
    , `comment` VARCHAR(200) DEFAULT NULL
);

CREATE TABLE `whitelist` LIKE `blacklist`;

INSERT INTO `blacklist` (`domain`) VALUES
      ('%facebook.com')
    , ('%twitter.com')
    , ('%pintrest.com')
    , ('%youtube.com')
    ;
