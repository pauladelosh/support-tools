/* =======
Update RA List:
====== */
TRUNCATE TABLE import_uuids;
/* Clean out Bad RA Rows */ 
DELETE FROM ;

SELECT *
FROM `import_uuids` 
WHERE sitename ="" 
AND (`sub` LIKE '%solr%' 
OR `sub` LIKE '%Stag%'
OR `sub` LIKE '%(Clone)%'
OR `sub` LIKE '%Dev%'
OR `sub` LIKE '%search%'
OR `sub` LIKE 'Selection:%'
OR `sub` LIKE '%(Load Test%')
AND `sub` NOT LIKE '%research%';
SELECT *
FROM `import_uuids` 
WHERE sitename !="" 
AND (`sub` LIKE '%solr%' 
OR `sub` LIKE '%Stag%'
OR `sub` LIKE '%(Clone)%'
OR `sub` LIKE '%search%'
OR `sub` LIKE '%(Load Test%'
OR `sub` LIKE '%child sub%'
OR `sub` LIKE '%(Load Test%')
AND `sub` NOT LIKE '%research%';

/* Select from UUID table.  This checks to see if clients listings are still RA, or no longer according to cci uuid */
SELECT c.sitename, c.uuid, c.sub, c.ra, uu.uuid, uu.sub, uu.sitename
FROM clients c
LEFT JOIN import_uuids uu ON c.uuid = uu.uuid
WHERE CHAR_LENGTH(c.uuid) < 37
ORDER BY uu.uuid;

/* Make sure current Clients list is reflected in UUID import */
/* Select from clients table */
SELECT c.sitename, c.uuid, c.sub, uu.uuid, uu.sub, uu.sitename
FROM import_uuids uu
LEFT JOIN clients c ON c.uuid = uu.uuid
ORDER BY c.uuid;

/* Clients present in CCI import, not Clients list */
INSERT into clients (sub, nid, uuid, sitename)
SELECT uu.sub, uu.subtype, uu.uuid, uu.sitename
    FROM import_uuids as uu
        LEFT OUTER JOIN clients as c on uu.uuid = c.uuid
    WHERE c.uuid is null;

SELECT * FROM clients WHERE updated >= "2014-01-26";
/* Update RA information in clients table */
UPDATE clients c, import_uuids uu
SET c.ra = 1, c.site_live = 1, c.host = "AH"
WHERE c.uuid = uu.uuid AND c.sitename !="" AND c.updated >= "2014-01-26";

/* Update RA information in clients table */
UPDATE clients c, import_uuids uu
SET c.ra = 1, c.site_live = 1, c.host = "SH"
WHERE c.uuid = uu.uuid AND c.sitename ="" AND c.updated >= "2014-01-23 22:51:39";

/* Update sub/site name by UUID */
UPDATE clients c, import_uuids uu
SET c.sitename_import = uu.sitename, c.sub = uu.sub, c.subtype = uu.subtype
WHERE c.uuid = uu.uuid;
SELECT *
FROM clients
WHERE sitename != sitename_import;
/* Check for odd dups */
SELECT sub, sitename, COUNT(*) c FROM clients WHERE primesite = 1 GROUP BY sitename HAVING c > 1;

/* Find duplicate primesites */
SELECT c.sitename, c.sub, c.primesite, c.multisite, j.primesite
FROM clients c
INNER JOIN clients j ON c.sitename = j.sitename
WHERE c.uuid <> j.uuid
AND c.primesite = 1
AND j.primesite = 1
AND c.sitename != '';
/* =======
Get Current Sites list
====== */
/* Select from clients table */
SELECT c.sitename, c.env, c.uri, c.cloud_command, c.uuid
FROM clients c
WHERE c.sitename !=""
AND c.ra = 1
AND c.primesite = 1
ORDER BY sitename;

/* Select from clients table - WMG*/
SELECT c.sitename, c.env, c.uri, c.cloud_command, c.uuid
FROM clients c
WHERE c.sitename !=""
AND c.ra = 1
AND sitename LIKE "wmg%"
ORDER BY sitename;

/* === Update Data === */


/* Module Updates */
/* Find/replace for Module DB import:
,Update-available, ,Mise-à-jour-disponible, ,Aktualisierung-verfügbar, ,Actualización-disponible, ,Nieuwe-versie-beschikbaar, ,Доступно-обновление, ,Güncelleme-mevcut, ,Uppdatering-tillgänglig, ,Aggiornamento-disponibile, ,Uppdatering-tillgänglig, ,يوجد-تحديث, ,可用的更新, ,Opdatering-tilgængelig, ,Atualização-disponível, ,Aktualisierung-verfügbar, ,2,
,Installed-version-not-supported, ,3,
,SECURITY-UPDATE-available, ,1,
,Installed-version-REVOKED, ,4,

/* Update clients with recent modules check */
UPDATE clients c, mods_secup ms
SET c.modules_check = ms.modules_check
WHERE c.uuid = ms.uuid;

UPDATE clients c, mods_sec_variable msv
SET c.modules_check = msv.modules_check
WHERE c.uuid = msv.uuid;

/* Update monthly core_ver */
UPDATE clients
SET core_ver_monthly = core_ver, core_check_monthly = core_check;

/* Core Updates */
/*
1.  Import table, add core_check date.
2.  Clean out extras
 */

/* Truncate the Core Import tables */
TRUNCATE TABLE corev_imp;
TRUNCATE TABLE corev_imp_test;

/* Clean up Core Version numbers */
UPDATE corev_imp SET core_ver = CASE
WHEN core_ver = "7.7" THEN "7.07"
WHEN core_ver = "7.8" THEN "7.08"
WHEN core_ver = "7.9" THEN "7.09"
WHEN core_ver = "6.28.21" THEN "6.28"
WHEN core_ver = "6.3" THEN "6.03"
ELSE core_ver
END;

/* Clean out Bad Core Rows */ 
DELETE FROM `corev_imp` 
WHERE `core_ver` LIKE '%Acquia%' 
OR `core_ver` LIKE 'Please sele%'
OR `core_ver` LIKE 'login requi%'
OR `core_ver` LIKE 'ini_set%'
OR `core_ver` LIKE 'Selection:%';

/* Update clients.core_ver with recent core check */
UPDATE clients c, corev_imp cv
SET c.core_ver = cv.core_ver,
c.core_check = cv.core_check
WHERE c.uuid = cv.uuid;

/* Core on TEST */
/* Clean up Core Version numbers */
UPDATE corev_imp_test SET core_ver = CASE
WHEN core_ver = "7.7" THEN "7.07"
WHEN core_ver = "7.8" THEN "7.08"
WHEN core_ver = "7.9" THEN "7.09"
WHEN core_ver = "6.28.21" THEN "6.28"
WHEN core_ver = "6.3" THEN "6.03"
ELSE core_ver
END;

/* Clean out Bad Core Rows */ 
DELETE FROM `corev_imp_test` 
WHERE `core_ver` LIKE '%Acquia%' 
OR `core_ver` LIKE 'Please sele%'
OR `core_ver` LIKE 'login requi%'
OR `core_ver` LIKE 'ini_set%'
OR `core_ver` LIKE 'Selection:%';

UPDATE clients c, corev_imp_test cvt
SET c.core_ver_test = cvt.core_ver,
c.core_check_test = cvt.core_check
WHERE c.uuid = cvt.uuid;

UPDATE clients c, corev_imp cv
SET c.core_ver = cv.core_ver, c.core_check = cv.core_check
WHERE c.sitename = cv.sitename;

UPDATE clients c, corev_imp_test cvt
SET c.core_ver_test = cvt.core_ver, c.core_check_test = cvt.core_check
WHERE c.sitename = cvt.sitename;


/* === Counts === */
/* Sites Scanned/Total RA */
SELECT c.host, c.core_ver,
COUNT(c.uuid)
FROM clients c
WHERE c.ra = 1
GROUP BY host;

select updated, sub, sitename, site_live, core_ver, core_check FROM clients WHERE site_live = 0 AND core_check > '2014-01-26';

/* Count RA sites NOT live */
SELECT host, site_live,
COUNT(site_live)
FROM clients c
WHERE ra = 1
AND c.site_live = 0
AND c.primesite = 1
GROUP BY host;

/* Count primesite RA sites, by hosting, note: use sub or uuid for distinct */
SELECT host, COUNT(DISTINCT(uuid)) FROM clients c
WHERE ra = 1
AND c.primesite = 1
AND c.site_live = 1
GROUP BY host;
/* Count MULTISITE RA sites, by hosting, note: use sub or uuid for distinct */
SELECT host, COUNT(DISTINCT(uuid)) FROM clients c
WHERE ra = 1
AND c.multisite = 1
AND c.site_live = 1
GROUP BY host;
/* Count ALL RA sites, by hosting, note: use sub or uuid for distinct */
SELECT host, COUNT(DISTINCT(uuid)) FROM clients c
WHERE ra = 1
AND c.site_live = 1
AND (c.primesite = 1 OR c.multisite = 1)
GROUP BY host;

/* =======
Core Status
====== */

/* Count primesite number Checked this Week */
SELECT host, core_ver, core_check,
COUNT(core_check)
FROM clients c
WHERE ra = 1
AND core_check > '2014-01-15'
AND c.primesite = 1
AND c.site_live = 1
GROUP BY host
ORDER BY host, core_ver;
/* Count MULTISITE number Checked this Week */
SELECT host, core_ver, core_check,
COUNT(core_check)
FROM clients c
WHERE ra = 1
AND core_check > '2014-01-15'
AND c.multisite = 1
AND c.site_live = 1
GROUP BY host
ORDER BY host, core_ver;
/* Count ALL number Checked this Week */
SELECT host, core_ver, core_check,
COUNT(core_check)
FROM clients c
WHERE ra = 1
AND core_check > '2014-01-15'
AND (c.primesite = 1 OR c.multisite = 1)
AND c.site_live = 1
GROUP BY host
ORDER BY host, core_ver;

/* Count primesite cores we know */
SELECT host, core_ver,
COUNT(core_ver)
FROM clients c
WHERE ra = 1
AND core_ver > 1
AND c.primesite = 1
AND c.site_live = 1
GROUP BY host;
/* Count MULTISITE cores we know */
SELECT host, core_ver,
COUNT(core_ver)
FROM clients c
WHERE ra = 1
AND core_ver > 1
AND c.multisite = 1
AND c.site_live = 1
GROUP BY host;
/* Count ALL cores we know */
SELECT host, core_ver,
COUNT(core_ver)
FROM clients c
WHERE ra = 1
AND core_ver > 1
AND c.site_live = 1
AND (c.primesite = 1 OR c.multisite = 1)
GROUP BY host;

/* Count: CORE, Insecure 6x, ALL */
SELECT host, core_ver,
COUNT(core_ver)
FROM clients c
WHERE ra = 1
AND c.site_live = 1
AND (c.primesite = 1 OR c.multisite = 1)
AND core_ver BETWEEN 6.00 AND 6.29
GROUP BY host;
/* Count: CORE, Insecure 6x, Primaries */
SELECT host, core_ver,
COUNT(core_ver)
FROM clients c
WHERE ra = 1
AND c.primesite = 1
AND c.site_live = 1
AND core_ver BETWEEN 6.00 AND 6.29
GROUP BY host;

/* Count: CORE, Secure 6x, ALL */
SELECT host, core_ver,
COUNT(core_ver)
FROM clients c
WHERE ra = 1
AND c.site_live = 1
AND (c.primesite = 1 OR c.multisite = 1)
AND core_ver BETWEEN 6.30 AND 6.99
GROUP BY host;
/* Count: CORE, Secure 6x, Primaries */
SELECT host, core_ver,
COUNT(core_ver)
FROM clients c
WHERE ra = 1
AND c.primesite = 1
AND c.site_live = 1
AND core_ver BETWEEN 6.30 AND 6.99
GROUP BY host;

/* Count: CORE, Insecure 7x, ALL */
SELECT host, core_ver,
COUNT(core_ver)
FROM clients c
WHERE ra = 1
AND c.site_live = 1
AND (c.primesite = 1 OR c.multisite = 1)
AND core_ver BETWEEN 7.00 AND 7.25
GROUP BY host;
/* Count: CORE, Secure 7x, Primaries */
SELECT host, core_ver,
COUNT(core_ver)
FROM clients c
WHERE ra = 1
AND c.primesite = 1
AND c.site_live = 1
AND core_ver BETWEEN 7.00 AND 7.25
GROUP BY host;

/* Count: CORE, Secure 7x, ALL */
SELECT host, core_ver,
COUNT(core_ver)
FROM clients c
WHERE ra = 1
AND c.site_live = 1
AND (c.primesite = 1 OR c.multisite = 1)
AND core_ver BETWEEN 7.26 AND 7.99
GROUP BY host;
/* Count: CORE, Secure 7x, Primaries */
SELECT host, core_ver,
COUNT(core_ver)
FROM clients c
WHERE ra = 1
AND c.primesite = 1
AND c.site_live = 1
AND core_ver BETWEEN 7.26 AND 7.99
GROUP BY host;

/* Count: CORE, 5x, ALL */
SELECT host, core_ver,
COUNT(core_ver)
FROM clients c
WHERE ra = 1
AND c.site_live = 1
AND (c.primesite = 1 OR c.multisite = 1)
AND core_ver BETWEEN 5.00 AND 5.99
GROUP BY host;
/* Count: CORE, Unknown, ALL */
SELECT host, core_ver,
COUNT(core_ver)
FROM clients c
WHERE ra = 1
AND (c.primesite = 1 OR c.multisite = 1)
AND c.site_live = 1
AND core_ver = 0
GROUP BY host;
/* Count: CORE, Unknown, Docroots */
SELECT host, core_ver,
COUNT(core_ver)
FROM clients c
WHERE ra = 1
AND c.primesite = 1
AND c.site_live = 1
AND core_ver = 0
GROUP BY host;

/* List by Core Version */
SELECT host, core_ver,
COUNT(core_ver)
FROM clients c
WHERE c.sitename !=""
AND c.ra = 1
AND site_live = 1
AND (core_ver BETWEEN 6.00 AND 6.29
OR core_ver BETWEEN 7.00 AND 7.25 OR core_ver = 0)
AND c.primesite = 1
AND sitename NOT LIKE "wmg%"
AND sitename NOT LIKE "pf%"
AND sitename NOT LIKE "cb%";


/* Updates deployed to Stage but not Prod */
SELECT host, core_ver,
COUNT(core_ver)
FROM clients c
WHERE ra = 1
AND c.site_live = 1
AND (c.primesite = 1 OR c.multisite = 1)
AND (core_ver_test BETWEEN 7.26 AND 7.99
OR core_ver_test BETWEEN 6.30 AND 6.99)
AND (core_ver BETWEEN 7.00 AND 7.25 OR core_ver BETWEEN 6.00 AND 6.29)
GROUP BY host;


/* Count Task Status */
SELECT stage, 
COUNT(stage)
FROM tasks t
WHERE t.updated >= '2014-01-31'
GROUP BY stage;

SELECT reason_close, 
COUNT(reason_close)
FROM tasks t
WHERE t.updated >= '2014-01-31'
GROUP BY reason_close;

/**** OBSOLETE ****/
/* count ALL current versions */
SELECT host, core_ver,
COUNT(core_ver)
FROM clients c
WHERE ra = 1
AND c.site_live = 1
AND (c.primesite = 1 OR c.multisite = 1)
GROUP BY host, core_ver
ORDER BY host, core_ver;

/* count primesite current versions */
SELECT host, core_ver,
COUNT(core_ver)
FROM clients c
WHERE ra = 1
AND c.primesite = 1
AND c.site_live = 1
GROUP BY host, core_ver
ORDER BY host, core_ver;

/* count TEST current versions */
SELECT host, core_ver_test,
COUNT(core_ver_test)
FROM clients
WHERE ra = 1
AND c.site_live = 1
GROUP BY host, core_ver_test
ORDER BY host, core_ver_test;

/* Counts number of sites on which checks attempted */
SELECT c.host,
COUNT(DISTINCT(uuid))
FROM clients c
WHERE c.sitename !=""
AND c.ra = 1
AND c.site_live = 1
ORDER BY c.host;

/* Counts number of sites, live or not live */
SELECT c.host,
COUNT(DISTINCT(uuid))
FROM clients c
WHERE c.sitename !=""
AND c.ra = 1
AND c.primesite = 1
ORDER BY c.host;

/* Counts number of sites where modules were successfully checked */
SELECT sitename, sec,
COUNT(DISTINCT(uuid))
FROM mods_secup;

/* Counts number of sites that insecure */
SELECT sitename, sec, COUNT(DISTINCT(uuid)) FROM mods_secup WHERE sec = 1;

/* Lists number of sites per insecure module */
SELECT module, upd_ver, COUNT(module) FROM mods_secup WHERE sec= 1 GROUP BY module, upd_ver;

/* Lists number of insecure modules per site */
SELECT sitename, uri, COUNT(module) FROM mods_secup WHERE sec= 1 GROUP BY sitename, uri;

/* =======
Comparing Prod/Test
====== */

DELETE FROM mods_secup_test
WHERE env = 'dev'

/*Compare Core on Prod and Test */
SELECT ci.core_ver, ci.env, cit.core_ver, cit.env, ci.`sitename`, ci.uri
FROM corev_imp ci, corev_imp_test cit
WHERE ci.uuid = cit.uuid;

/*Compare Core on Prod and Test */
SELECT ci.core_ver, ci.env, cit.core_ver, cit.env, ci.`sitename`, ci.uri
FROM corev_imp ci, corev_imp_test cit
WHERE ci.uuid = cit.uuid
AND ci.core_ver != '7.15'
AND cit.core_ver = '7.15';

/* count current versions */
SELECT core_ver,
COUNT(core_ver)
FROM corev_imp_test
GROUP BY core_ver
ORDER BY core_ver

/* Duplicate UUIDs */
SELECT uuid, COUNT(*) c FROM clients GROUP BY uuid HAVING c > 1;


