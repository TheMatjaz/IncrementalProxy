-- Mysql setup for Squid authentication
-- Docs: http://wiki.squid-cache.org/ConfigExamples/Authenticate/Mysql

create database squid;
grant select on squid.* to squid@localhost identified by 'squidpwtomysql';
use squid;
CREATE TABLE `passwd` (
    `user`     varchar(32) NOT NULL default '',
    `password` varchar(35) NOT NULL default '',
    `enabled`  tinyint(1)  NOT NULL default '1',
    `fullname` varchar(60)          default NULL,
    `comment`  varchar(60)          default NULL,
    
    PRIMARY KEY  (`user`)
    );
insert into passwd values
    ('testuser','test',1,'Test User','for testing purpose');

CREATE TABLE `blacklist` (
    `id`      INT(16)      NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `url`     TEXT         NOT NULL,
    `comment` VARCHAR(200) DEFAULT NULL
);
CREATE INDEX idx_url ON `blacklist`(`url`) USING HASH;
INSERT INTO `blacklist` VALUES
    ('.facebook.com')
    , ('.twitter.com')
    , ('.pintrest.com')
    , ('.youtube.com')
    ;
CREATE TABLE `whitelist` LIKE `blacklist`;
