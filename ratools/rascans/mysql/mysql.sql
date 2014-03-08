/* COMPAREs */

/* Compare sites that reported drush upc to existing hosting sites.
These are sites that are either updates, or that we cannot access via drush,
or do not have update.php enable.*/
SELECT c.sitename, c.env, c.uri, c.cloud_command, c.site_live
FROM clients c LEFT JOIN mods_secup m
ON c.sitename = m.sitename
WHERE c.sitename !=""
AND c.ra = 1
AND c.site_live = 1
AND c.env = 'prod'
AND c.sitename NOT LIKE "wmg%"
AND m.sitename IS NULL
GROUP BY c.sitename

/* Find sites that did not return DB information (aht_dbs.sh) */
SELECT c.sitename, c.uuid, c.sub, c.ra, db.uuid, db.dbsize, db.dbname, db.sitename
FROM clients c
LEFT JOIN site_database db ON c.uuid = db.uuid
WHERE c.sitename != ""
AND c.primesite = 1
AND c.ra = 1
AND c.sitename NOT LIKE "wmg%"
AND c.sitename NOT LIKE "pf%"
AND db.dbname IS NULL
ORDER BY c.sitename;

/* Show site, repo sizes, db sizes */
SELECT c.sitename, c.sub, sr.reposize, sr.prodsize, db.dbsize, db.dbname, sr.sitename, c.uuid
FROM clients c
LEFT JOIN site_repo sr ON c.uuid = sr.uuid
LEFT JOIN site_database db ON c.uuid = db.uuid
WHERE c.sitename != ""
AND c.primesite = 1
AND c.ra = 1
ORDER BY c.sitename, db.dbname;

/* Find sites that did not return DB information (aht_dbs.sh) */
SELECT c.sitename, c.sub, db.dbsize, db.dbname, c.uuid
FROM clients c
LEFT JOIN site_database db ON c.uuid = db.uuid
WHERE c.sitename != ""
AND c.primesite = 1
AND c.ra = 1
AND c.sitename NOT LIKE "wmg%"
ORDER BY c.sitename;

SELECT c.sitename, c.sub, db.dbsize, db.dbname, c.uuid,
COUNT(DISTINCT(c.sitename))
FROM clients c
LEFT JOIN site_database db ON c.uuid = db.uuid
WHERE c.sitename != ""
AND c.primesite = 1
AND c.ra = 1
AND c.sitename NOT LIKE "wmg%"
AND db.dbsize !=""
ORDER BY c.sitename;

/* Concat sites, multisites, add UUID */
SELECT CONCAT(c.uuid, '-', (@cnt := @cnt + 1)) AS super_uuid, c.sitename, c.core_ver, CONCAT(c.sub, ' - ', z.random), z.random, (1) AS multisite, (0) AS prime, ('AH') AS host
FROM zz_random z
CROSS JOIN (SELECT @cnt := 100) AS dummy
LEFT JOIN clients c ON c.uuid = z.uuid
ORDER BY c.sub, z.random;

/* List by Core Distribution and Version */
SELECT c.sitename, c.env, c.uri, c.cloud_command,c.core_ver, c.core_ver_test, c.distribution, c.uuid
FROM clients c
WHERE c.sitename !=""
AND c.ra = 1
AND c.site_live = 1
AND sitename NOT LIKE "wmg%"
AND sitename NOT LIKE "pf%"
AND core_ver BETWEEN 6.00 AND 6.28
AND c.primesite = 1
AND c.distribution != "Pressflow"
ORDER BY core_ver;

UPDATE insight_cci ic
SET ic.ignore = 1
WHERE site LIKE "%stg.prod.acquia-sites.com"
OR site LIKE "%stg2.prod.acquia-sites.com"
OR site LIKE "%dev.prod.acquia-sites.com"
OR site LIKE "%dev2.prod.acquia-sites.com"
OR site LIKE "%local%"
OR site LIKE '%:%'
OR site LIKE '%.abm'
OR site LIKE '%.amazonaws%'
OR site LIKE '127.0.0.1'
OR site LIKE 'dev%'
OR site LIKE '%dev'
OR site LIKE '%dev.%'
OR site LIKE '%dev1.%'
OR site LIKE '%dev2.%'
OR site LIKE '%dev3.%'
OR site LIKE '%dev4.%'
OR site LIKE '%dev5.%'
OR site LIKE '%test.devcloud%'
OR site LIKE '%tdev.devcloud%'
OR site LIKE '%-dev%'
OR site LIKE 'qa.%'
OR site LIKE 'qa-%'
OR site LIKE '%.loc'
OR site LIKE '%staging%'
OR site LIKE "%stage%"
OR site LIKE "stg.%"
OR site LIKE "%sandbox%"
OR site LIKE "192.168%"
OR site REGEXP '^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$';


SELECT * FROM clients c
WHERE c.site_live = 0;
/* Update clients from random, WELCOME */
UPDATE clients c, zz_random zr
SET c.site_live = 0
WHERE c.uuid = zr.uuid;

SELECT c.sub, c.sitename, zr.random, zr.sitename
FROM clients c, zz_random zr
WHERE c.uuid = zr.uuid;


