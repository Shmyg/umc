/*
|| Suspension/reactivation schema creation
|| Created by Shmyg
|| Last modified by Shmyg 23.11.2001
*/

ACCEPT owner  DEFAULT reactor PROMPT "Enter new user name [reactor]: "
ACCEPT deftsp PROMPT "Enter Default tablespace name: "
ACCEPT tmptsp PROMPT "Enter Temp tablespace name: "
ACCEPT indtsp PROMPT "Enter Index tablespace name: "
ACCEPT dbname PROMPT "Enter database name: "

-- Preparing connect scripts

SET ECHO OFF
SET FEEDBACK  OFF
SET HEADING  OFF
SET VERIFY  OFF

SPOOL /tmp/ReConnect.sql

SELECT	'connect '||user||'@'||name||';'
FROM	v$database;

SPOOL OFF

SPOOL /tmp/ConnSYSADM.sql

SELECT	'connect SYSADM@'||name||';'
FROM	v$database;

SPOOL OFF

SPOOL /tmp/ConnREPMAN.sql

SELECT	'connect REPMAN@'||name||';'
FROM	v$database;

SPOOL OFF

SPOOL /tmp/Conn&owner..sql

SELECT	'connect &owner.@'||name||';'
FROM	v$database;

SPOOL OFF

SET ECHO ON
SET TIME ON
SET FEEDBACK ON
SET HEADING ON
SET LINESIZE 400
SET PAGESIZE 400
SET TRIMSPOOL ON

SPOOL &owner..log

CREATE USER &owner.
IDENTIFIED BY &owner
DEFAULT TABLESPACE &deftsp
TEMPORARY TABLESPACE &tmptsp
QUOTA 400M ON &deftsp
/

CREATE ROLE &owner._role
/

GRANT CREATE SESSION TO &owner.
/
GRANT SELECT ON common.ibu_pos_messages TO &owner.
/
GRANT SELECT ON common.ibu_pos_messages TO &owner._role
/
GRANT EXECUTE ON common.ibu_pos_api_gmd TO &owner.
/
GRANT EXECUTE ON common.ibu_pos_api_gmd TO &owner._role
/
GRANT EXECUTE ON common.ibu_pos_message TO &owner.
/
GRANT EXECUTE ON common.ibu_pos_message TO &owner._role
/
GRANT EXECUTE ON common.umc_util TO &owner.
/
GRANT SELECT ON common.customer_address TO &owner.
/

-- Creating tables

-- UMC_debtors
CREATE TABLE &owner..umc_debtors
	(
	customer_id	NUMBER NOT NULL,
	cscurbalance	NUMBER NOT NULL,
	csclimit	NUMBER NOT NULL,
	unbilled_amount	NUMBER NOT NULL,
	total_amount	NUMBER NOT NULL,
	dn_num		VARCHAR2(20) NOT NULL,
	co_id		NUMBER NOT NULL,
	username	VARCHAR2(20) NOT NULL,
	entdate		DATE NOT NULL,
	processed	VARCHAR2(1)
	)
PCTFREE    10
PCTUSED    40
INITRANS   1
MAXTRANS   255
/
COMMENT ON TABLE &owner..umc_debtors IS 'Table for suspension of customers'
/
COMMENT ON COLUMN &owner..umc_debtors.entdate IS 'Date of insertion'
/
COMMENT ON COLUMN &owner..umc_debtors.processed IS 'Is customer suspended (''X'') or no (NULL)'
/
COMMENT ON COLUMN &owner..umc_debtors.username IS 'User who marked customer for suspension'
/
COMMENT ON COLUMN umc_debtors.action IS 'Action to perform: W - send SMS, S - suspend'
/
COMMENT ON COLUMN umc_debtors.show_amount IS 'Flag if we should show sum of debth in SMS: X - show'
/

-- Reactivated customers
CREATE TABLE &owner..reactivated_customers
	(
	customer_id	NUMBER NOT NULL,
	cscurbalance	NUMBER NOT NULL,
	csclimit	NUMBER NOT NULL,
	unbilled_amount	NUMBER NOT NULL,
	co_id		NUMBER NOT NULL,
	entdate		DATE NOT NULL
	)
PCTFREE    10
PCTUSED    40
INITRANS   1
MAXTRANS   255
/
COMMENT ON TABLE &owner..reactivated_customers IS 'Table for customers reactivation logging'
/
COMMENT ON COLUMN &owner..reactivated_customers.customer_id IS 'Paymentresponsible for the contract'
/

-- Added 09.01.2003
CREATE	TABLE &owner..customers_paid
	(
	entdate		DATE NOT NULL,
	customer_id	NUMBER,
	custcode	VARCHAR2(24),
	dn_num		VARCHAR2(63),
	amount		NUMBER
	)
PCTFREE    10
PCTUSED    40
INITRANS   1
MAXTRANS   255
/

@/tmp/ConnSYSADM.sql

GRANT SELECT ON sysadm.customer_all TO &owner.
/
GRANT SELECT ON sysadm.costcenter TO &owner.
/
GRANT SELECT ON sysadm.contract_all TO &owner.
/
GRANT SELECT ON sysadm.ccontact_all TO &owner
/
GRANT SELECT ON sysadm.contr_services_cap TO &owner.
/
GRANT SELECT ON sysadm.contract_history TO &owner.
/
GRANT SELECT ON sysadm.directory_number TO &owner.
/
GRANT SELECT ON sysadm.cashreceipts_all TO &owner.
/
GRANT SELECT ON sysadm.mdsrrtab TO &owner.
/
GRANT SELECT ON sysadm.mpulktmb TO &owner.
/
GRANT SELECT ON sysadm.pricegroup_all TO &owner.
/
GRANT SELECT ON sysadm.glaccount_all TO &owner.
/
GRANT SELECT ON sysadm.costcenter TO &owner._role
/
GRANT SELECT ON sysadm.pricegroup_all TO &owner._role
/


@/tmp/ConnREPMAN.sql

GRANT SELECT ON repman.rep_config TO &owner.
/

@/tmp/ReConnect.sql

ALTER	TABLE &owner..umc_debtors
ADD	CONSTRAINT pkumc_debtors
PRIMARY	KEY
	(
	co_id,
	entdate
	)
USING	INDEX
TABLESPACE &indtsp
PCTFREE		10
INITRANS	2
MAXTRANS	255
/

CREATE	INDEX &owner..react_cust_co_id
ON	&owner..reactivated_customers
	(
	co_id
	)
TABLESPACE &indtsp
PCTFREE    10
INITRANS   2
MAXTRANS   255
/

CREATE	INDEX &owner..umc_debtors_entdate
ON	&owner..umc_debtors
	(
	entdate
	)
TABLESPACE &indtsp
PCTFREE    10
INITRANS   2
MAXTRANS   255
/

-- Added 21.01.2003
CREATE	INDEX &owner..cust_paid_entdate
ON	&owner..customers_paid
	(
	entdate
	)
TABLESPACE &indtsp
PCTFREE    10
INITRANS   2
MAXTRANS   255
/


@debtors.pks
@debtors.pkb

@/tmp/Conn&owner..sql

GRANT EXECUTE ON &owner..debtors TO &owner._role
/
GRANT SELECT, UPDATE, DELETE ON &owner..umc_debtors TO &owner._role
/

SPOOL OFF
SET ECHO OFF
SET TIME OFF

!rm -f /tmp/ReConnect.sql
!rm -f /tmp/ConnSYSADM.sql
!rm -f /tmp/ConnREPMAN.sql
!rm -f /tmp/Conn&owner..sql


UNDEFINE dbname
UNDEFINE owner
UNDEFINE deftsp
UNDEFINE tmptsp
UNDEFINE indtsp
