-- Mysql setup for Squid authentication
-- Docs: http://wiki.squid-cache.org/ConfigExamples/Authenticate/Mysql

create database squid;
grant select on squid.* to root@localhost identified by 'root';
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
