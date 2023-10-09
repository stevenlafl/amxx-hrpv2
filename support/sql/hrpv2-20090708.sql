/*
SQLyog Community Edition- MySQL GUI v7.01
MySQL - 5.0.41-community-nt : Database - hrpv2
*********************************************************************
*/


/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;

CREATE DATABASE /*!32312 IF NOT EXISTS*/`hrpv2` /*!40100 DEFAULT CHARACTER SET latin1 */;

USE `hrpv2`;

/*Table structure for table `accounts` */

DROP TABLE IF EXISTS `accounts`;

CREATE TABLE `accounts` (
  `steamid` varchar(32) default NULL,
  `wallet` varchar(14) default NULL,
  `bank` varchar(14) default NULL,
  `job` int(4) default NULL,
  `flags` varchar(8) default NULL,
  `health` int(4) default '100',
  `armor` int(4) default '0',
  `origin` varchar(32) default NULL,
  `phone` varchar(7) default NULL
) DEFAULT CHARSET=latin1;

/*Data for the table `accounts` */

/*Table structure for table `atms` */

DROP TABLE IF EXISTS `atms`;

CREATE TABLE `atms` (
  `map` varchar(32) default NULL,
  `x` int(4) default NULL,
  `y` int(4) default NULL,
  `z` int(4) default NULL
) DEFAULT CHARSET=latin1;

/*Data for the table `atms` */

/*Table structure for table `furniature` */

DROP TABLE IF EXISTS `furniature`;

CREATE TABLE `furniature` (
  `steamid` varchar(32) default NULL,
  `model` varchar(64) default NULL,
  `origin` varchar(32) default NULL,
  `angle` varchar(32) default NULL,
  `itemid` int(4) default NULL
) DEFAULT CHARSET=latin1;

/*Data for the table `furniature` */

/*Table structure for table `items` */

DROP TABLE IF EXISTS `items`;

CREATE TABLE `items` (
  `id` int(4) default NULL,
  `title` varchar(32) default NULL,
  `function` varchar(32) default NULL,
  `parameter` varchar(64) default NULL,
  `description` varchar(64) default NULL,
  `internal` int(4) default NULL,
  `give` int(4) default NULL,
  `drop` int(4) default NULL
) DEFAULT CHARSET=latin1;

/*Data for the table `items` */

/*Table structure for table `jail` */

DROP TABLE IF EXISTS `jail`;

CREATE TABLE `jail` (
  `x` int(4) default NULL,
  `y` int(4) default NULL,
  `z` int(4) default NULL
) DEFAULT CHARSET=latin1;

/*Data for the table `jail` */

/*Table structure for table `jobs` */

DROP TABLE IF EXISTS `jobs`;

CREATE TABLE `jobs` (
  `id` int(4) default NULL,
  `organization` varchar(32) default NULL,
  `title` varchar(32) default NULL,
  `salary` varchar(14) default NULL,
  `flag` char(1) default NULL
) DEFAULT CHARSET=latin1;

/*Data for the table `jobs` */

/*Table structure for table `npc` */

DROP TABLE IF EXISTS `npc`;

CREATE TABLE `npc` (
  `map` varchar(64) default NULL,
  `name` text,
  `sell` text,
  `intern` text,
  `price` text,
  `x` int(6) default NULL,
  `y` int(6) default NULL,
  `z` int(6) default NULL
) DEFAULT CHARSET=latin1;

/*Data for the table `npc` */

/*Table structure for table `property` */

DROP TABLE IF EXISTS `property`;

CREATE TABLE `property` (
  `ent` varchar(255) NOT NULL default '',
  `parent` varchar(32) NOT NULL default '',
  `title` varchar(64) NOT NULL default '',
  `owner` varchar(32) NOT NULL default '',
  `price` varchar(14) NOT NULL default '0.00',
  `locked` int(4) NOT NULL default '0',
  `profit` int(4) NOT NULL default '0',
  `map` varchar(32) NOT NULL default '',
  `steamid` varchar(32) NOT NULL default '',
  `jobidkey` varchar(13) NOT NULL default '',
  `rent` int(4) NOT NULL default '0'
) DEFAULT CHARSET=latin1;

/*Data for the table `property` */

/*Table structure for table `test` */

DROP TABLE IF EXISTS `test`;

CREATE TABLE `test` (
  `example_value` varchar(255) default NULL
) DEFAULT CHARSET=latin1;

/*Data for the table `test` */

/*Table structure for table `timer` */

DROP TABLE IF EXISTS `timer`;

CREATE TABLE `timer` (
  `minute` int(4) default NULL,
  `hour` int(4) default NULL,
  `day` int(4) default NULL,
  `month` int(4) default NULL,
  `year` int(4) default NULL,
  `map` varchar(32) default NULL
) DEFAULT CHARSET=latin1;

/*Data for the table `timer` */

/*Table structure for table `user_items` */

DROP TABLE IF EXISTS `user_items`;

CREATE TABLE `user_items` (
  `steamid` varchar(32) default NULL,
  `items` text NOT NULL,
  `internals` text NOT NULL,
  `quantity` text NOT NULL
) DEFAULT CHARSET=latin1;

/*Data for the table `user_items` */

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
