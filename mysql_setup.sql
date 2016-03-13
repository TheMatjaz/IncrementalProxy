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
