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

-- Added 15.05.2003
CREATE	TABLE &owner..contracts_to_deactivate
	(
	entdate		DATE NOT NULL,
	paymentresp_id	NUMBER NOT NULL,
	customer_id	NUMBER NOT NULL,
	co_id		NUMBER NOT NULL,
	ch_reason	NUMBER NOT NULL,
	action		VARCHAR2(1) NOT NULL,
	processed	VARCHAR2(1),
	procdate	DATE,
	errmessage	VARCHAR2(2000)
	)
PCTFREE    10
PCTUSED    40
INITRANS   1
MAXTRANS   255
/

COMMENT ON TABLE &owner..contracts_to_deactivate IS 'Contracts which must be deactivated'
/
COMMENT ON COLUMN &owner..contracts_to_deactivate.paymentresp_id IS 'Paymentresponsible for the contract'
/
COMMENT ON COLUMN &owner..contracts_to_deactivate.customer_id IS 'Contract owner'
/
COMMENT ON COLUMN &owner..contracts_to_deactivate.ch_reason IS 'Reason for suspension'
/
COMMENT ON COLUMN &owner..contracts_to_deactivate.action IS 'Action to do: D - deactivate, R - report but not deactivate'
/
COMMENT ON COLUMN &owner..contracts_to_deactivate.processed IS 'Flag if contract has been processed by deactivation script: X - processed successfully, E - error, NULL - not processed'
/
COMMENT ON COLUMN &owner..contracts_to_deactivate.procdate IS 'Date when contract was processed by deactivatio script'
/
COMMENT ON COLUMN &owner..contracts_to_deactivate.errmessage IS 'Message while deactivation (sucess or error)'
/

@/tmp/ConnSYSADM.sql

-- Added 15.05.2003
GRANT SELECT ON bch_history_table TO &owner.
/

INSERT	INTO reasonstatus_all
	(
	rs_id,
	rs_desc,
	rs_warning,
	rs_type,
	rs_status,
	rs_sdes,
	rec_version,
	rs_default
	)
VALUES	(
	53,
	'Involuntary - Autodeactivation',
	NULL,
	'S',
	'd',
	'AD',
	0,
	NULL
	)
/
COMMIT
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
