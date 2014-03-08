# ************************************************************
# Sequel Pro SQL dump
# Version 4096
#
# http://www.sequelpro.com/
# http://code.google.com/p/sequel-pro/
#
# Host: ded-2301.prod.hosting.acquia.com (MySQL 5.5.24-55-log)
# Database: radashstgdb8142
# Generation Time: 2014-03-08 00:45:16 +0000
# ************************************************************


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


# Dump of table clients
# ------------------------------------------------------------

DROP TABLE IF EXISTS `clients`;

CREATE TABLE `clients` (
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `sub` varchar(255) DEFAULT NULL,
  `sitename` varchar(50) DEFAULT NULL,
  `ra` tinyint(1) DEFAULT '0',
  `site_live` tinyint(1) DEFAULT '0',
  `uri` varchar(100) DEFAULT 'default',
  `primesite` tinyint(1) DEFAULT '1',
  `multisite` tinyint(1) DEFAULT '0',
  `core_ver` varchar(11) DEFAULT '0',
  `tam` tinyint(1) DEFAULT '0',
  `ka` tinyint(1) DEFAULT '0',
  `distribution` varchar(100) DEFAULT NULL,
  `upd_en` tinyint(1) DEFAULT NULL,
  `env` varchar(10) DEFAULT 'prod',
  `env_user` varchar(50) DEFAULT 'root',
  `host` varchar(6) DEFAULT NULL,
  `update_inform` tinyint(1) DEFAULT '1',
  `update_auto` tinyint(1) DEFAULT '1',
  `update_source` varchar(50) DEFAULT 'tag_prod',
  `update_core` tinyint(1) DEFAULT '1',
  `patched_core` tinyint(1) DEFAULT '0',
  `update_modules` tinyint(1) DEFAULT '1',
  `patched_modules` tinyint(1) DEFAULT '0',
  `deploy_auto` tinyint(1) DEFAULT '1',
  `deploy_testenv` varchar(11) DEFAULT 'test',
  `deploy_testdb` varchar(11) DEFAULT 'prod',
  `deploy_cptestdb` tinyint(1) DEFAULT '1',
  `core_check` datetime DEFAULT NULL,
  `modules_check` datetime DEFAULT NULL,
  `site_address` varchar(255) DEFAULT NULL,
  `gov` tinyint(1) DEFAULT '0',
  `subtype` varchar(255) DEFAULT NULL,
  `uuid` varchar(100) DEFAULT NULL,
  `sitename_import` varchar(50) DEFAULT NULL,
  `acq_conn` tinyint(1) DEFAULT '0' COMMENT 'Is Acquia Connector enabled?',
  `cloud_command` varchar(10) DEFAULT 'mc',
  `nid` int(11) unsigned NOT NULL,
  `par_id` int(11) DEFAULT NULL,
  `priority` tinyint(1) DEFAULT '0',
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `core_ver_test` varchar(11) DEFAULT '0',
  `core_check_test` datetime DEFAULT NULL,
  `core_ver_monthly` varchar(11) DEFAULT '0',
  `core_check_monthly` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table clients_prefs
# ------------------------------------------------------------

DROP TABLE IF EXISTS `clients_prefs`;

CREATE TABLE `clients_prefs` (
  `sub` varchar(255) DEFAULT NULL,
  `sitename` varchar(50) DEFAULT NULL,
  `update_inform` tinyint(1) DEFAULT '1',
  `update_auto` tinyint(1) DEFAULT '1',
  `update_do` tinyint(1) DEFAULT '1',
  `update_source` varchar(11) DEFAULT 'tag_prod',
  `update_core` tinyint(1) DEFAULT '1',
  `patched_core` tinyint(1) DEFAULT '0',
  `update_modules` tinyint(1) DEFAULT '1',
  `patched_modules` tinyint(1) DEFAULT '0',
  `deploy_auto` tinyint(1) DEFAULT '1',
  `deploy_testenv` varchar(11) DEFAULT 'test',
  `deploy_testdb` varchar(11) DEFAULT 'prod',
  `deploy_cptestdb` tinyint(1) DEFAULT '1',
  `uuid` varchar(100) DEFAULT NULL,
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table contacts_concat
# ------------------------------------------------------------

DROP TABLE IF EXISTS `contacts_concat`;

CREATE TABLE `contacts_concat` (
  `last_name` varchar(60) DEFAULT NULL,
  `first_name` varchar(100) DEFAULT NULL,
  `email` varchar(60) DEFAULT NULL,
  `sub` varchar(60) DEFAULT NULL,
  `type` varchar(60) DEFAULT NULL,
  `sitename` varchar(50) DEFAULT NULL,
  `concat_tech` text,
  `RA` tinyint(1) DEFAULT NULL,
  `UUID` varchar(100) DEFAULT NULL,
  `legacy_nid` varchar(10) DEFAULT NULL,
  `updated` date DEFAULT NULL,
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



# Dump of table contacts_uuid
# ------------------------------------------------------------

DROP TABLE IF EXISTS `contacts_uuid`;

CREATE TABLE `contacts_uuid` (
  `last_name` varchar(60) DEFAULT NULL,
  `first_name` varchar(100) DEFAULT NULL,
  `email` varchar(60) DEFAULT NULL,
  `username` varchar(10) DEFAULT NULL,
  `phone` varchar(60) DEFAULT NULL,
  `type` varchar(60) DEFAULT NULL,
  `sub` varchar(255) DEFAULT NULL,
  `sitename` varchar(20) DEFAULT NULL,
  `UUID` varchar(100) DEFAULT NULL,
  `updated` date DEFAULT NULL,
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



# Dump of table corev_imp
# ------------------------------------------------------------

DROP TABLE IF EXISTS `corev_imp`;

CREATE TABLE `corev_imp` (
  `core_ver` varchar(11) DEFAULT NULL,
  `sitename` varchar(50) DEFAULT '',
  `env` varchar(11) DEFAULT 'prod',
  `uri` varchar(11) DEFAULT NULL,
  `uuid` varchar(100) DEFAULT NULL,
  `core_check` datetime DEFAULT NULL,
  `Notes` longtext,
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



# Dump of table corev_imp_test
# ------------------------------------------------------------

DROP TABLE IF EXISTS `corev_imp_test`;

CREATE TABLE `corev_imp_test` (
  `core_ver` varchar(11) DEFAULT NULL,
  `sitename` varchar(50) DEFAULT '',
  `env` varchar(11) DEFAULT 'prod',
  `uri` varchar(11) DEFAULT NULL,
  `uuid` varchar(100) DEFAULT NULL,
  `core_check` datetime DEFAULT NULL,
  `Notes` longtext,
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



# Dump of table import_uuids
# ------------------------------------------------------------

DROP TABLE IF EXISTS `import_uuids`;

CREATE TABLE `import_uuids` (
  `sub` varchar(255) DEFAULT NULL,
  `uuid` varchar(100) DEFAULT NULL,
  `sitename` varchar(50) DEFAULT '',
  `subtype` varchar(255) DEFAULT NULL,
  `uri` varchar(11) DEFAULT NULL,
  `check` datetime DEFAULT NULL,
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



# Dump of table insight_cci
# ------------------------------------------------------------

DROP TABLE IF EXISTS `insight_cci`;

CREATE TABLE `insight_cci` (
  `uuid_site` varchar(100) DEFAULT NULL,
  `uuid_sub` varchar(100) DEFAULT NULL,
  `sub` varchar(255) DEFAULT NULL,
  `site` varchar(50) DEFAULT NULL,
  `mods_enabled` int(11) DEFAULT NULL,
  `mods_forked` int(11) DEFAULT NULL,
  `mods_insecure` int(11) DEFAULT NULL,
  `mods_outdated` int(11) DEFAULT NULL,
  `core_ver` varchar(11) DEFAULT '0',
  `manage_sites` varchar(100) DEFAULT NULL,
  `sitename` varchar(50) DEFAULT NULL,
  `imported` datetime DEFAULT NULL,
  `ignore` tinyint(1) DEFAULT NULL,
  `env` varchar(10) DEFAULT 'prod',
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table insight_cci_core
# ------------------------------------------------------------

DROP TABLE IF EXISTS `insight_cci_core`;

CREATE TABLE `insight_cci_core` (
  `core_ver` varchar(11) DEFAULT '0',
  `sitename` varchar(50) DEFAULT NULL,
  `env` varchar(10) DEFAULT 'prod',
  `site` varchar(50) DEFAULT NULL,
  `uuid_site` varchar(100) DEFAULT NULL,
  `uuid_sub` varchar(100) DEFAULT NULL,
  `sub` varchar(255) DEFAULT NULL,
  `imported` datetime DEFAULT NULL,
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table modcheck_imp
# ------------------------------------------------------------

DROP TABLE IF EXISTS `modcheck_imp`;

CREATE TABLE `modcheck_imp` (
  `module` varchar(11) DEFAULT NULL,
  `enabled` varchar(11) DEFAULT NULL,
  `sitename` varchar(50) DEFAULT '',
  `env` varchar(11) DEFAULT 'prod',
  `uuid` varchar(100) DEFAULT NULL,
  `check` datetime DEFAULT NULL,
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



# Dump of table mods_concat
# ------------------------------------------------------------

DROP TABLE IF EXISTS `mods_concat`;

CREATE TABLE `mods_concat` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `UUID` varchar(100) DEFAULT NULL,
  `sitename` varchar(60) DEFAULT NULL,
  `uri` varchar(60) DEFAULT NULL,
  `modu` varchar(1000) DEFAULT NULL,
  `modules_check` datetime DEFAULT NULL,
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table mods_sec_variable
# ------------------------------------------------------------

DROP TABLE IF EXISTS `mods_sec_variable`;

CREATE TABLE `mods_sec_variable` (
  `module` varchar(60) DEFAULT NULL,
  `curr_ver` varchar(60) DEFAULT NULL,
  `upd_ver` varchar(60) DEFAULT NULL,
  `sec` tinyint(1) DEFAULT NULL,
  `sec_text` varchar(100) DEFAULT NULL,
  `sitename` varchar(50) DEFAULT '',
  `env` varchar(11) DEFAULT 'prod',
  `uri` varchar(60) DEFAULT 'default',
  `uuid` varchar(100) DEFAULT NULL,
  `core_ver` varchar(11) DEFAULT NULL,
  `modules_check` datetime DEFAULT NULL,
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `timestamp` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



# Dump of table mods_secup
# ------------------------------------------------------------

DROP TABLE IF EXISTS `mods_secup`;

CREATE TABLE `mods_secup` (
  `module` varchar(60) DEFAULT NULL,
  `curr_ver` varchar(60) DEFAULT NULL,
  `upd_ver` varchar(60) DEFAULT NULL,
  `sec` tinyint(1) DEFAULT NULL,
  `sitename` varchar(50) DEFAULT '',
  `env` varchar(11) DEFAULT 'prod',
  `uri` varchar(60) DEFAULT 'default',
  `uuid` varchar(100) DEFAULT NULL,
  `core_ver` varchar(11) DEFAULT NULL,
  `cloud_command` varchar(11) DEFAULT 'ahmc',
  `modules_check` datetime DEFAULT NULL,
  `Notes` longtext,
  `nid` int(11) DEFAULT NULL,
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `timestamp` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



# Dump of table mods_secup_only
# ------------------------------------------------------------

DROP TABLE IF EXISTS `mods_secup_only`;

CREATE TABLE `mods_secup_only` (
  `module` varchar(60) DEFAULT NULL,
  `curr_ver` varchar(60) DEFAULT NULL,
  `upd_ver` varchar(60) DEFAULT NULL,
  `sec` tinyint(1) DEFAULT NULL,
  `sitename` varchar(50) DEFAULT '',
  `env` varchar(11) DEFAULT 'prod',
  `uri` varchar(60) DEFAULT 'default',
  `uuid` varchar(100) DEFAULT NULL,
  `core_ver` varchar(11) DEFAULT NULL,
  `cloud_command` varchar(11) DEFAULT 'ahmc',
  `modules_check` datetime DEFAULT NULL,
  `Notes` longtext,
  `nid` int(11) DEFAULT NULL,
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `timestamp` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



# Dump of table mods_secup_test
# ------------------------------------------------------------

DROP TABLE IF EXISTS `mods_secup_test`;

CREATE TABLE `mods_secup_test` (
  `module` varchar(60) DEFAULT NULL,
  `curr_ver` varchar(60) DEFAULT NULL,
  `upd_ver` varchar(60) DEFAULT NULL,
  `sec` tinyint(1) DEFAULT NULL,
  `sitename` varchar(50) DEFAULT '',
  `env` varchar(11) DEFAULT 'prod',
  `uri` varchar(60) DEFAULT 'default',
  `uuid` varchar(100) DEFAULT NULL,
  `core_ver` varchar(11) DEFAULT NULL,
  `cloud_command` varchar(11) DEFAULT 'ahmc',
  `modules_check` datetime DEFAULT NULL,
  `Notes` longtext,
  `nid` int(11) DEFAULT NULL,
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `timestamp` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



# Dump of table rapref_imp
# ------------------------------------------------------------

DROP TABLE IF EXISTS `rapref_imp`;

CREATE TABLE `rapref_imp` (
  `sub` varchar(255) DEFAULT NULL,
  `ticket` varchar(11) DEFAULT NULL,
  `update_inform` tinyint(1) DEFAULT '1',
  `update_auto` tinyint(1) DEFAULT '1',
  `update_source` varchar(11) DEFAULT 'tag_prod',
  `update_core` tinyint(1) DEFAULT '1',
  `update_modules` tinyint(1) DEFAULT '1',
  `patched_core` tinyint(1) DEFAULT '0',
  `patched_modules` tinyint(1) DEFAULT '0',
  `deploy_auto` tinyint(1) DEFAULT '1',
  `deploy_testenv` varchar(11) DEFAULT 'test',
  `deploy_testdb` varchar(11) DEFAULT 'prod',
  `deploy_cptestdb` tinyint(1) DEFAULT '1',
  `sitename` varchar(50) DEFAULT NULL,
  `update_do` tinyint(1) DEFAULT '1',
  `ka` tinyint(1) DEFAULT '0',
  `uuid` varchar(100) DEFAULT NULL,
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table site_database
# ------------------------------------------------------------

DROP TABLE IF EXISTS `site_database`;

CREATE TABLE `site_database` (
  `dbname` varchar(100) DEFAULT NULL,
  `dbsize` decimal(20,10) DEFAULT NULL,
  `sitename` varchar(50) DEFAULT '',
  `env` varchar(11) DEFAULT NULL,
  `uuid` varchar(100) DEFAULT NULL,
  `check` datetime DEFAULT NULL,
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



# Dump of table site_php
# ------------------------------------------------------------

DROP TABLE IF EXISTS `site_php`;

CREATE TABLE `site_php` (
  `php` varchar(100) DEFAULT NULL,
  `sitename` varchar(50) DEFAULT '',
  `env` varchar(11) DEFAULT NULL,
  `uuid` varchar(100) DEFAULT NULL,
  `check` datetime DEFAULT NULL,
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



# Dump of table site_repo
# ------------------------------------------------------------

DROP TABLE IF EXISTS `site_repo`;

CREATE TABLE `site_repo` (
  `reposize` int(10) DEFAULT NULL,
  `prodsize` int(10) DEFAULT NULL,
  `sitename` varchar(50) DEFAULT '',
  `env` varchar(11) DEFAULT NULL,
  `uuid` varchar(100) DEFAULT NULL,
  `check` datetime DEFAULT NULL,
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



# Dump of table tasks
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tasks`;

CREATE TABLE `tasks` (
  `stage` varchar(255) DEFAULT NULL,
  `initials` varchar(11) DEFAULT NULL,
  `ticket` int(11) DEFAULT NULL,
  `update_type` varchar(255) DEFAULT NULL,
  `subscription` varchar(255) DEFAULT NULL,
  `hosting` varchar(255) DEFAULT NULL,
  `sitename` varchar(11) DEFAULT NULL,
  `date_post` datetime DEFAULT NULL,
  `date_update` datetime DEFAULT NULL,
  `reason_close` varchar(255) DEFAULT NULL,
  `updated` datetime DEFAULT NULL,
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table tasks_copy
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tasks_copy`;

CREATE TABLE `tasks_copy` (
  `stage` varchar(255) DEFAULT NULL,
  `initials` varchar(11) DEFAULT NULL,
  `ticket` int(11) DEFAULT NULL,
  `update_type` varchar(255) DEFAULT NULL,
  `subscription` varchar(255) DEFAULT NULL,
  `hosting` varchar(255) DEFAULT NULL,
  `sitename` varchar(11) DEFAULT NULL,
  `date_post` datetime DEFAULT NULL,
  `date_update` datetime DEFAULT NULL,
  `reason_close` varchar(255) DEFAULT NULL,
  `updated` date DEFAULT NULL,
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table tickets_sun
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tickets_sun`;

CREATE TABLE `tickets_sun` (
  `queue_id` int(11) DEFAULT NULL,
  `status` varchar(100) DEFAULT NULL,
  `uuid` varchar(100) DEFAULT NULL,
  `nid` int(11) DEFAULT NULL,
  `primary` varchar(60) DEFAULT NULL,
  `ticket` int(11) DEFAULT NULL,
  `error` text,
  `batch` varchar(100) DEFAULT NULL,
  `batch_nid` int(11) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table zz_random
# ------------------------------------------------------------

DROP TABLE IF EXISTS `zz_random`;

CREATE TABLE `zz_random` (
  `random` varchar(100) DEFAULT NULL,
  `random2` int(1) DEFAULT '1',
  `sitename` varchar(50) DEFAULT '',
  `env` varchar(11) DEFAULT NULL,
  `uuid` varchar(100) DEFAULT NULL,
  `check` datetime DEFAULT NULL,
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



# Dump of table zz_random_2
# ------------------------------------------------------------

DROP TABLE IF EXISTS `zz_random_2`;

CREATE TABLE `zz_random_2` (
  `random` varchar(100) DEFAULT NULL,
  `sitename` varchar(50) DEFAULT '',
  `env` varchar(11) DEFAULT NULL,
  `uuid` varchar(100) DEFAULT NULL,
  `check` datetime DEFAULT NULL,
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;




/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
