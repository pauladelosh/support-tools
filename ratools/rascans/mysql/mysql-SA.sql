/* Select clients for Contact Scan */
SELECT c.uuid
FROM clients c
WHERE c.ra = 1
AND c.primesite = 1
ORDER BY sitename;

/* Concatenate Technical Emails */
SELECT co.email, c.uuid, co.first_name, co.last_name, group_concat(t.email), c.sub, c.core_ver, c.sitename, c.update_inform, c.update_auto, c.deploy_auto, c.update_source, c.deploy_testenv, c.deploy_testdb, c.deploy_cptestdb, c.host
FROM contacts_uuid co
inner join contacts_uuid t on co.uuid = t.uuid and t.type='technical'
join clients c on c.uuid = co.uuid
WHERE co.type='primary'
AND c.primesite = 1
AND c.ra = 1
AND c.site_live = 1
AND c.update_inform = 1
AND c.update_auto = 0
GROUP BY c.uuid
ORDER BY c.sitename;


AND c.sitename NOT LIKE 'wmg%'
AND c.sitename NOT LIKE 'pf%'
AND c.update_inform = 1
AND c.update_auto = 0
AND c.deploy_auto = 0
AND c.core_ver >= '7'
;

/* Missing Tickets */
SELECT c.sitename, c.uuid, c.sub, c.ra, c.update_inform, cu.sub, cu.sitename, cu.type
FROM clients c
LEFT JOIN contacts_uuid cu ON c.uuid = cu.uuid
WHERE c.ra = 1
AND c.primesite = 1
AND c.update_inform = 1
AND cu.type IS NULL
GROUP BY c.uuid
ORDER BY cu.type, c.sitename, c.sub;
/* Find clients that DID NOT get a ticket */
SELECT c.sub, c.sitename, c.uuid, c.update_inform, c.update_auto, ts.primary, ts.ticket, ts.batch
FROM clients c
LEFT JOIN tickets_sun ts ON c.uuid = ts.uuid
WHERE c.primesite = 1
AND c.ra = 1
AND c.primesite = 1
AND update_inform = 1
AND (ts.batch LIKE 'SA-CORE-2014-001%' OR ts.batch IS NULL);

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

/* Concatenate Module Updates by UUID */
select uuid, sitename, uri,
  group_concat(concat(module , ': ' , curr_ver , ' to ' , upd_ver) SEPARATOR '<br />')
  AS modu
FROM mods_secup
WHERE sec = 1
GROUP BY uuid;

/* Check: Select from clients table */
SELECT c.sitename, c.uuid, c.sub, cc.uuid, cc.sub, cc.sitename
FROM contacts_concat cc
LEFT JOIN clients c ON c.uuid = cc.uuid
ORDER BY c.uuid;

/* List for Mass Ticket Module with Module Information */
SELECT cc.email, c.uuid, cc.first_name, cc.last_name, cc.concat_tech, c.sub, c.core_ver, m.modu, c.modules_check,c.sitename, c.update_source, c.deploy_testenv, c.deploy_testdb, c.deploy_cptestdb, c.update_inform, c.update_auto, c.deploy_auto
FROM clients c
INNER JOIN contacts_concat cc
    on c.uuid = cc.uuid
INNER JOIN mods_concat m
  on c.uuid = m.uuid
WHERE c.uuid=cc.uuid
AND c.ra=1
AND c.ka != 1
AND c.primesite=1
AND c.host="AH"
AND c.update_inform = 1
AND c.update_auto = 1
AND c.deploy_auto = 1
AND c.sitename NOT LIKE 'wmg%'
AND c.sitename NOT LIKE 'pf%';

/* List for Mass Ticket Module */
SELECT cc.email, c.uuid, cc.first_name, cc.last_name, cc.concat_tech, c.sub, c.core_ver, c.sitename, c.update_source, c.deploy_testenv, c.deploy_testdb, c.deploy_cptestdb
FROM clients c, contacts_concat cc
WHERE c.uuid = cc.uuid
AND c.ra = 1
AND c.primesite=1
AND c.sitename NOT LIKE 'wmg%'
AND c.sitename NOT LIKE 'pf%'
AND c.core_ver >= '7'
AND c.update_inform
AND c.update_auto = 0
AND c.deploy_auto = 0;

/* Count clients by length of uuid */
SELECT sub, uuid as var
FROM clients
WHERE ra='1'
AND CHAR_LENGTH(uuid) < 37;

/* List by Core Version */
SELECT c.sitename, c.env, c.uri, c.cloud_command,c.core_ver, c.core_ver_test, c.host, c.uuid
FROM clients c
WHERE c.sitename !=""
AND c.ra = 1
AND sitename NOT LIKE "wmg%"
AND sitename NOT LIKE "pf%"
AND sitename NOT LIKE "cb%"
AND site_live = 1
AND (core_ver BETWEEN 6.00 AND 6.27
OR core_ver BETWEEN 7.00 AND 7.19 OR core_ver = 0)
AND (core_ver_test != 6.28 AND core_ver_test != 7.23 AND core_ver_test != 7.22 AND core_ver_test != 7.21 AND core_ver_test != 7.20)
AND c.primesite = 1
AND update_auto = 1
AND update_inform = 1
ORDER BY core_ver_test;

SELECT c.sitename, c.env, c.uri, c.cloud_command,c.core_ver, c.core_ver_test, c.host, c.uuid
FROM clients c
WHERE c.sitename !=""
AND c.ra = 1
AND sitename NOT LIKE "wmg%"
AND sitename NOT LIKE "pf%"
AND sitename NOT LIKE "cb%"
AND site_live = 1
AND (core_ver BETWEEN 6.00 AND 6.27
OR core_ver BETWEEN 7.00 AND 7.19 OR core_ver = 0)
AND c.primesite = 1
AND update_auto = 1
AND update_inform = 1
ORDER BY core_ver_test;


/***********
Client Preferences
************/
/* Lists Subs not in clients_prefs */
SELECT c.sub, c.sitename, c.uuid, cp.sub, cp.sitename
FROM clients c
LEFT JOIN clients_prefs cp ON c.uuid = cp.uuid
ORDER BY cp.uuid;
/* Inserts subs into clients_pref */
INSERT INTO clients_prefs (sub, sitename, uuid)
SELECT c.sub, c.sitename, c.uuid
  FROM clients as c
    LEFT OUTER JOIN clients_prefs as cp on c.uuid = cp.uuid
  WHERE cp.uuid IS NULL;

/* Update clients with prefs */
UPDATE clients_prefs cp, clients c
SET c.update_inform = cp.update_inform,
c.update_auto = cp.update_auto,
c.update_do = cp.update_do,
c.update_source = cp.update_source,
c.update_core = cp.update_core,
c.patched_core = cp.patched_core,
c.update_modules = cp.update_modules,
c.patched_modules = cp.patched_modules,
c.deploy_auto = cp.deploy_auto,
c.deploy_testenv = cp.deploy_testenv,
c.deploy_testdb = cp.deploy_testdb,
c.deploy_cptestdb = cp.deploy_cptestdb
WHERE c.uuid = cp.uuid;

UPDATE clients_prefs
SET update_do = 0, update_auto = 0, deploy_auto = 0
WHERE update_inform = 0

UPDATE clients_prefs
SET update_do = 0, deploy_auto = 0
WHERE update_auto = 0;


/* Update PREFS with CLIENTS */
UPDATE clients_prefs cp, clients c
SET cp.update_inform = c.update_inform,
cp.update_auto = c.update_auto,
cp.update_do= c.update_do,
cp.update_source = c.update_source,
cp.update_core = c.update_core,
cp.patched_core = c.patched_core,
cp.update_modules = c.update_modules,
cp.patched_modules = c.patched_modules,
cp.deploy_auto = c.deploy_auto,
cp.deploy_testenv = c.deploy_testenv,
cp.deploy_testdb = c.deploy_testdb,
cp.deploy_cptestdb = c.deploy_cptestdb
WHERE c.uuid = cp.uuid


/* List modules updates by site */
SELECT sitename, module, curr_ver, upd_ver, uri
FROM mods_secup
WHERE sec = 1
AND sitename = 'georgiata'

/* ============================================== */

/* Contact List for SA update */
SELECT c.par_id, cu.email, cu.type, c.sub, c.sitename, cu.uuid
FROM clients c
LEFT JOIN contacts_uuid cu ON c.uuid = cu.uuid
WHERE CHAR_LENGTH(c.uuid) < 37
AND c.ra = 1
AND c.par_id > 1
AND c.ka = 0
ORDER BY cu.sub, cu.type

/* Contact List for SA update - KA accounts */
SELECT c.par_id, c.ra, cu.email, cu.type, c.sub, c.sitename, cu.uuid
FROM clients c
LEFT JOIN contacts_uuid cu ON c.uuid = cu.uuid
WHERE CHAR_LENGTH(c.uuid) < 37
AND c.ra = 1
AND c.par_id > 1
AND c.ka = 1
AND c.update_inform = 1
ORDER BY cu.sub, cu.type

UPDATE clients
SET update_do = 0
WHERE sub LIKE 'Advantage Media %'

/* Show KA list */
SELECT ka, sub, sitename, update_do, update_inform
FROM clients
WHERE ka=1
AND sitename NOT LIKE "wmg%"
AND sitename NOT LIKE "pf%"
AND sitename NOT LIKE "rr%"
ORDER BY sub
