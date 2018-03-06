/*
|| Executor schema creation
|| Created by TSlobod
|| Last modified by Shmyg 17.07.2002
*/

ACCEPT owner  DEFAULT executor PROMPT "Enter new user name [executor]: "
ACCEPT deftsp PROMPT "Enter default tablespace name: "
ACCEPT tmptsp PROMPT "Enter temp tablespace name: "
ACCEPT indtsp PROMPT "Enter index tablespace name: "

-- Preparing connect scripts

SET ECHO OFF
SET FEEDBACK  OFF
SET HEADING  OFF
SET VERIFY  OFF

SPOOL /tmp/ReConnect.sql
SELECT	'connect ' || user || '@' || name || ';'
FROM	v$database
/
SPOOL OFF

SPOOL /tmp/ConnSYSADM.sql
SELECT	'connect SYSADM@' || name || ';'
FROM	v$database
/
SPOOL OFF

SPOOL /tmp/ConnREPMAN.sql
SELECT	'connect REPMAN@' || name || ';'
FROM	v$database
/
SPOOL OFF

SPOOL /tmp/ConnCREATOR.sql
SELECT	'connect CREATOR@' || name || ';'
FROM	v$database
/
SPOOL OFF

SPOOL /tmp/Conn&owner..sql
SELECT	'connect &owner.@' || name || ';'
FROM	v$database
/
SPOOL OFF

SET ECHO ON
SET TIME ON
SET FEEDBACK ON
SET HEADING ON
SET LINESIZE 400
SET PAGESIZE 400
SET TRIMSPOOL ON

SPOOL	&owner..log

CREATE USER &owner.
IDENTIFIED BY &owner.
DEFAULT	TABLESPACE &deftsp
TEMPORARY TABLESPACE &tmptsp
QUOTA 400M ON &deftsp
QUOTA 100M ON &indtsp
/

CREATE ROLE &owner._role
IDENTIFIED BY &owner._role
/

CREATE ROLE &owner._adm_role
IDENTIFIED BY &owner._adm_role
/

GRANT EXECUTE ON common.umc_util TO &owner.
/
GRANT EXECUTE ON common.umc_finance TO &owner.
/
GRANT SELECT ON common.customer_address TO &owner._role
/
GRANT SELECT ON common.customer_address TO &owner.
/
GRANT SELECT ON common.valid_tmcodes TO &owner.
/
GRANT EXECUTE ON common.ibu_pos_api_tickler TO &owner.
/
GRANT EXECUTE ON common.customer_name TO &owner.
/
GRANT EXECUTE ON common.umc_customer TO &owner.
/
GRANT CREATE SESSION TO &owner.
/

-- Tables
CREATE	TABLE &owner..agrtypes
	(
	atcode			NUMBER NOT NULL,
	shdes			VARCHAR2(10) NOT NULL,
	longdes			VARCHAR2(200) NOT NULL,
	expires			DATE,
	t_commit		NUMBER NOT NULL,
	active_period_only	VARCHAR2(1),
	excl_mode		VARCHAR2(1),
	validfrom		DATE NOT NULL,
	username		VARCHAR2(20) NOT NULL
	)
PCTFREE		5
PCTUSED		40
INITRANS	1
MAXTRANS	255
TABLESPACE	&deftsp
/
COMMENT ON TABLE &owner..agrtypes IS 'All possible additional agreements'
/
COMMENT ON COLUMN &owner..agrtypes.atcode IS 'AA code - PK'
/
COMMENT ON COLUMN &owner..agrtypes.shdes IS 'Short des to be inserted into INFO_CONTR_TEXT'
/
COMMENT ON COLUMN &owner..agrtypes.expires IS 'Expiry date'
/
COMMENT ON COLUMN &owner..agrtypes.t_commit IS 'Duration in days'
/
COMMENT ON COLUMN &owner..agrtypes.active_period_only IS 'Flag if only active period should be included'
/
COMMENT ON COLUMN &owner..agrtypes.excl_mode IS 'Flag if AA is exclusive for contract'
/

CREATE	TABLE &owner..agreement_all
	(
	aa_id		NUMBER NOT NULL,
	co_id		NUMBER NOT NULL,
	atcode		NUMBER NOT NULL,
	sign_date	DATE NOT NULL,
	cancel_date	DATE,
	status		VARCHAR2(1) NOT NULL,
	model_id	NUMBER,
	imei		VARCHAR2(15),
	username	VARCHAR2(20) NOT NULL,
	user_deactivated	VARCHAR2(20)
	)
PCTFREE		10
PCTUSED		40
INITRANS	1
MAXTRANS	255
TABLESPACE	&deftsp
/
COMMENT ON TABLE &owner..agreement_all IS 'All additional agreements'
/
COMMENT ON COLUMN &owner..agreement_all.aa_id IS 'AA ID - part of PK'
/
COMMENT ON COLUMN &owner..agreement_all.co_id IS 'Contract ID - part of PK, FK to CONTRACT_ALL'
/
COMMENT ON COLUMN &owner..agreement_all.atcode IS 'AA type - FK to AGRTYPES'
/
COMMENT ON COLUMN &owner..agreement_all.status IS 'Current AA status (''a'', ''d'')'
/
COMMENT ON COLUMN &owner..agreement_all.model_id IS 'Phone model ID corresponding to AA type, if any - FK to PHONE_MODELS'
/
COMMENT ON COLUMN &owner..agreement_all.imei IS 'IMEI of phone sold if any - FK to PHONE_NUMS'
/
COMMENT ON COLUMN &owner..agreement_all.user_deactivated IS 'User who deactivated AA'
/

CREATE	TABLE &owner..old_aa
	(
	co_id		NUMBER NOT NULL,
	text02		VARCHAR2(80) NOT NULL,
	text14		VARCHAR2(80),
	username	VARCHAR2(20) NOT NULL
	)
PCTFREE		0
PCTUSED		40
INITRANS	1
MAXTRANS	255
TABLESPACE	&deftsp
/

CREATE	TABLE &owner..phone_models
	(
	model_id	NUMBER NOT NULL,
	atcode		NUMBER NOT NULL,
	model_name	VARCHAR2(30) NOT NULL,
	entdate		DATE NOT NULL,
	entuser		VARCHAR2(20) NOT NULL
	)
PCTFREE		3
PCTUSED		40
INITRANS	1
MAXTRANS	255
TABLESPACE	&deftsp
/
COMMENT ON TABLE &owner..phone_models IS 'Phone models that can be attached to AA'
/
COMMENT ON COLUMN &owner..phone_models.model_id IS 'Model ID - PK'
/
COMMENT ON COLUMN &owner..phone_models.atcode IS 'AA code - FK to agrtypes'
/

CREATE TABLE &owner..phone_nums
	(
	imei		VARCHAR2(15) NOT NULL,
	model_id	NUMBER NOT NULL,
	phone_sold	VARCHAR2(1) CHECK( phone_sold = 'X' OR phone_sold IS NULL ),
	username	VARCHAR2(20) NOT NULL,
	entdate		DATE NOT NULL
	)
PCTFREE    3
PCTUSED    40
INITRANS   1
MAXTRANS   255
TABLESPACE &deftsp
/
COMMENT ON TABLE &owner..phone_nums IS 'Data about phones that can be sold for AA'
/
COMMENT ON COLUMN &owner..phone_nums.imei IS 'IMEI - PK'
/
COMMENT ON COLUMN &owner..phone_nums.model_id IS 'Phone model ID - FK to PHONE_MODELS'
/
COMMENT ON COLUMN &owner..phone_nums.phone_sold IS 'Flag if phone is sold'
/

CREATE TABLE &owner..check_criteria
	(
	check_criteria_id	NUMBER NOT NULL,
	shdes		VARCHAR2(5) NOT NULL,
	des		VARCHAR2(60),
	username	VARCHAR2(20) NOT NULL,
	entdate		DATE NOT NULL
	)
PCTFREE    10
PCTUSED    40
INITRANS   1
MAXTRANS   255
TABLESPACE &deftsp
/
COMMENT ON TABLE &owner..check_criteria IS 'Check criteria for penalties'
/

CREATE	TABLE &owner..contr_penalties
	(
	cp_id		NUMBER NOT NULL,
	pencode		NUMBER NOT NULL,
	co_id		NUMBER NOT NULL,
	aa_id		NUMBER NOT NULL,
	pen_amt_calc	NUMBER DEFAULT 0 NOT NULL,
	pen_amt		NUMBER DEFAULT 0 NOT NULL,
	status		VARCHAR2(1) NOT NULL,
	username	VARCHAR2(20) NOT NULL,
	entdate		DATE NOT NULL,
	pen_remark	VARCHAR2(300)
	)
PCTFREE    10
PCTUSED    40
INITRANS   1
MAXTRANS   255
TABLESPACE &deftsp
/
COMMENT ON TABLE &owner..contr_penalties IS 'All the penalties for the contracts'
/
COMMENT ON COLUMN &owner..contr_penalties.co_id IS 'Contract_id, FK to CONTRACT_ALL'
/
COMMENT ON COLUMN &owner..contr_penalties.entdate IS 'Date of penalty creation'
/
COMMENT ON COLUMN &owner..contr_penalties.cp_id IS 'Penalty ID - PK'
/
COMMENT ON COLUMN &owner..contr_penalties.pencode IS 'Penalty code, FK to PENALTIES_SETUP'
/
COMMENT ON COLUMN &owner..contr_penalties.pen_amt IS 'Actual penalty amount assigned'
/
COMMENT ON COLUMN &owner..contr_penalties.pen_amt_calc IS 'Penalty amount calculated'
/
COMMENT ON COLUMN &owner..contr_penalties.status IS '''W'' - wait for billing results, ''C'' - calculated'
/

CREATE TABLE &owner..penalties_setup
	(
	pencode		NUMBER NOT NULL,
	atcode		NUMBER NOT NULL,
	pentype_id	NUMBER NOT NULL,
	pen_des		VARCHAR2(200) NOT NULL,
	enabled		VARCHAR2(1) DEFAULT 'X' CHECK( enabled = 'X' OR enabled IS NULL ),
	calc_method_id	NUMBER NOT NULL,
	fx_amt		NUMBER DEFAULT 0 NOT NULL,
	c1		NUMBER DEFAULT 0 NOT NULL,
	c2		NUMBER DEFAULT 0 NOT NULL,
	c3		NUMBER DEFAULT 0 NOT NULL,
	service_param	NUMBER,
	username	VARCHAR2(20) NOT NULL,
	entdate		DATE NOT NULL
	)
PCTFREE    10
PCTUSED    40
INITRANS   1
MAXTRANS   255
TABLESPACE &deftsp
/
COMMENT ON TABLE &owner..penalties_setup IS 'Penalty calculation parametres'
/
COMMENT ON COLUMN &owner..penalties_setup.atcode IS 'Agreement type code, FK to AGREEMENTS_ALL'
/
COMMENT ON COLUMN &owner..penalties_setup.c1 IS 'Penalty calculation parameter: 1st summand coefficient'
/
COMMENT ON COLUMN &owner..penalties_setup.c2 IS 'Penalty calcualation parameter: 2nd summand coefficient'
/
COMMENT ON COLUMN &owner..penalties_setup.c3 IS 'Penalty calculation parameter: 3rd summand coefficient'
/
COMMENT ON COLUMN &owner..penalties_setup.enabled IS '''X'' - valid'
/
COMMENT ON COLUMN &owner..penalties_setup.fx_amt IS 'Penalty calculation parameter: fixed amount'
/
COMMENT ON COLUMN &owner..penalties_setup.pencode IS 'PK, penalty code'
/
COMMENT ON COLUMN &owner..penalties_setup.pen_des IS 'Penalty description'
/
COMMENT ON COLUMN &owner..penalties_setup.pentype_id IS 'Penalty type ID, FK to PENTYPES'
/

CREATE TABLE &owner..pentypes
	(
	pentype_id	NUMBER NOT NULL,
	pentype_des	VARCHAR2(200) NOT NULL,
	event_id	NUMBER NOT NULL,
	ohinvtype	NUMBER DEFAULT 2 NOT NULL,
	glacode		VARCHAR2(30) DEFAULT '3210070' NOT NULL,
	postbilling	VARCHAR2(1),
	check_criteria_id	NUMBER NOT NULL,
	once_per_agreement	VARCHAR2(1),
	username	VARCHAR2(20) NOT NULL,
	entdate		DATE NOT NULL
    	)
PCTFREE		10
PCTUSED		40
INITRANS	1
MAXTRANS	255
TABLESPACE	&deftsp
/
COMMENT ON TABLE &owner..pentypes IS 'Possible penalty types'
/
COMMENT ON COLUMN &owner..pentypes.check_criteria_id IS 'FK to CHECK_CRITERIA'
/
COMMENT ON COLUMN &owner..pentypes.glacode IS 'General Ledger account code'
/
COMMENT ON COLUMN &owner..pentypes.ohinvtype IS 'Invoice type corresponding to ORDERHDR_ALL'
/
COMMENT ON COLUMN &owner..pentypes.postbilling IS '''X'' if penalty can be imposed only after billing'
/
COMMENT ON COLUMN executor.pentypes.once_per_agreement IS '''X'' if penalty should be imposed only once per agreement or contract'
/
COMMENT ON COLUMN &owner..pentypes.pentype_id IS 'Penalty type ID - PK'
/
COMMENT ON COLUMN &owner..pentypes.event_id IS 'Event ID which penalty can be applied to - FK to PENEVENTS'
/

CREATE TABLE &owner..calc_methods
	(
        calc_method_id		NUMBER NOT NULL,
        calc_method_des		VARCHAR2(60) NOT NULL,
        calc_method_longdes	VARCHAR2(1000),
	entdate			DATE NOT NULL,
	username		VARCHAR2(20) NOT NULL
	)
PCTFREE    10
PCTUSED    40
INITRANS   1
MAXTRANS   255
TABLESPACE &deftsp
/

COMMENT ON TABLE &owner..calc_methods IS 'Penalty calculation methods'
/
COMMENT ON COLUMN &owner..calc_methods.calc_method_id IS 'Calculation method ID - PK'
/

CREATE TABLE &owner..penevents
	(
        event_id	NUMBER NOT NULL,
        event_des	VARCHAR2(60) NOT NULL,
	username	VARCHAR2(20) NOT NULL,
	entdate		DATE NOT NULL
	)
PCTFREE		3
PCTUSED		40
INITRANS	1
MAXTRANS	255
TABLESPACE	&deftsp
/

COMMENT ON TABLE &owner..penevents IS 'Events that cause penalties imposition'
/
COMMENT ON COLUMN &owner..penevents.event_id IS 'Event ID - PK'
/

-- Constraints

ALTER	TABLE &owner..calc_methods
ADD	CONSTRAINT pk_calc_methods
PRIMARY	KEY (calc_method_id)
USING	INDEX
PCTFREE    10
INITRANS   2
MAXTRANS   255
TABLESPACE &indtsp
/

ALTER	TABLE &owner..penevents
ADD	CONSTRAINT pk_penevents
PRIMARY	KEY (event_id)
USING	INDEX
PCTFREE    10
INITRANS   2
MAXTRANS   255
TABLESPACE &indtsp
/

ALTER	TABLE &owner..pentypes
ADD	CONSTRAINT pk_pentypes
PRIMARY	KEY ( pentype_id )
USING	INDEX
PCTFREE		10
INITRANS	2
MAXTRANS	255
TABLESPACE	&indtsp
/

ALTER	TABLE &owner..agrtypes
ADD	CONSTRAINT pk_agrtypes
PRIMARY	KEY ( atcode )
USING	INDEX
PCTFREE		10
INITRANS	2
MAXTRANS	255
TABLESPACE	&indtsp
/

ALTER	TABLE &owner..agreement_all
ADD	CONSTRAINT pkagreement_all
PRIMARY	KEY ( aa_id )
USING	INDEX
PCTFREE		10
INITRANS	2
MAXTRANS	255
TABLESPACE	&indtsp
/

ALTER	TABLE &owner..phone_models
ADD	CONSTRAINT pkphone_models
PRIMARY	KEY ( model_id )
USING	INDEX
PCTFREE		10
INITRANS	2
MAXTRANS	255
TABLESPACE	&indtsp
/

ALTER	TABLE &owner..phone_nums
ADD	CONSTRAINT pkphone_nums
PRIMARY	KEY (imei)
USING	INDEX
PCTFREE		10
INITRANS	2
MAXTRANS	255
TABLESPACE	&indtsp
/

ALTER	TABLE &owner..penalties_setup
ADD	CONSTRAINT pk_penalties_setup
PRIMARY	KEY ( pencode )
USING	INDEX
PCTFREE	10
INITRANS	2
MAXTRANS	255
TABLESPACE	&indtsp
/

ALTER	TABLE &owner..penalties_setup
ADD	CONSTRAINT fk_pen_setup_calc_methods
FOREIGN	KEY ( calc_method_id )
REFERENCES &owner..calc_methods( calc_method_id )
/


ALTER TABLE &owner..penalties_setup
 ADD CONSTRAINT UNIQUE_ATCODE_PENTYPE_ID
 UNIQUE
 ( ATCODE
  ,PENTYPE_ID
 )
/

ALTER	TABLE &owner..agreement_all
ADD	CONSTRAINT fkaa_agrtypes
FOREIGN	KEY ( atcode )
REFERENCES	&owner..agrtypes( atcode )
/

ALTER	TABLE &owner..phone_models
ADD	CONSTRAINT fk_pm_aa
FOREIGN	KEY ( atcode )
REFERENCES &owner..agrtypes( atcode )
/

ALTER	TABLE &owner..phone_nums
ADD	CONSTRAINT fk_pn_pm
FOREIGN	KEY ( model_id )
REFERENCES	&owner..phone_models( model_id )
/

ALTER	TABLE &owner..penalties_setup
ADD	CONSTRAINT fk_pen_setup_agrtypes
FOREIGN	KEY ( atcode )
REFERENCES &owner..agrtypes( atcode )
/

ALTER	TABLE &owner..penalties_setup
ADD	CONSTRAINT fk_pen_setup_pentypes
FOREIGN	KEY ( pentype_id )
REFERENCES &owner..pentypes( pentype_id )
/

-- Added 12.08.2002
CREATE	INDEX &owner..agr_all_co_idx
ON	&owner..agreement_all
	(
	co_id,
	status
	)
TABLESPACE &indtsp
PCTFREE    10
INITRANS   2
MAXTRANS   255
/

-- Added 13.08.2002
CREATE	OR REPLACE VIEW &owner..active_aa
AS
SELECT	*
FROM	&owner..agreement_all
WHERE	status = 'a'
/

@/tmp/ConnSYSADM.sql
GRANT SELECT, REFERENCES ON contract_all TO &owner.
/
GRANT SELECT, UPDATE ON customer_all TO &owner.
/
GRANT SELECT ON contract_history TO &owner.
/
GRANT SELECT ON rateplan_hist TO &owner.
/
GRANT SELECT ON bch_history_table TO &owner.
/
GRANT SELECT ON contract_all TO &owner._role
/
GRANT SELECT, INSERT, UPDATE ON info_contr_text TO &owner.
/
GRANT SELECT ON info_contr_text to &owner._role
/
GRANT SELECT ON mpulktmb TO &owner.
/


@/tmp/ConnREPMAN.sql
GRANT EXECUTE ON get_error_message TO &owner._role
/
GRANT EXECUTE ON get_error_message TO &owner._adm_role
/

INSERT	INTO repman.rep_roles
	(
	role_name,
	role_passwd,
	des,
	username,
	entdate
	)
VALUES	(
	'EXECUTOR_ROLE',
	'EXECUTOR_ROLE',
	'Role for penalties and additional agreements imposing'
	'SHMYG'
	SYSDATE
	)
/

INSERT	INTO repman.rep_roles
	(
	role_name,
	role_passwd,
	des,
	username,
	entdate
	)
VALUES	(
	'EXECUTOR_ADM_ROLE',
	'EXECUTOR_ADM_ROLE',
	'Role for penalties and additional agreements management'
	'SHMYG'
	SYSDATE
	)
/

@/tmp/ConnCREATOR.sql
GRANT EXECUTE ON contract TO &owner.
/

@/tmp/ReConnect.sql
ALTER	TABLE &owner..agreement_all
ADD	CONSTRAINT fkaa_co_id
FOREIGN	KEY (co_id)
REFERENCES	sysadm.contract_all( co_id )
ON DELETE CASCADE
/

@penadmin.pks
@penadmin.pkb
@penalty.pks
@penalty.pkb
@aa_management.pks
@aa_management.pkb
@contr_aa_mng.pks
@contr_aa_mng.pkb

@/tmp/Conn&owner..sql
GRANT EXECUTE ON &owner..penadmin TO &owner._adm_role
/
GRANT EXECUTE ON &owner..aa_management TO &owner._adm_role
/
GRANT EXECUTE ON &owner..penalty TO &owner._role
/
GRANT EXECUTE ON &owner..contr_aa_mng TO &owner._role
/
GRANT EXECUTE ON &owner..contr_aa_mng TO sysadm
/
-- Added 01.07.2002
GRANT SELECT ON &owner..agrtypes TO &owner._role
/
GRANT SELECT ON &owner..agrtypes TO &owner._adm_role
/
GRANT SELECT ON &owner..phone_models TO &owner._role
/
GRANT SELECT ON &owner..phone_models TO &owner._adm_role
/
GRANT SELECT ON &owner..phone_nums TO &owner._role
/
GRANT SELECT ON &owner..phone_nums TO &owner._adm_role
/
-- Added 12.07.2002
GRANT SELECT ON &owner..agreement_all TO dealer
/
GRANT SELECT ON &owner..agrtypes TO dealer_role
/
-- Added 13.08.2002
GRANT SELECT ON &owner..active_aa TO dealer
/

@/tmp/ConnSYSADM.sql

@deactivation_trigger.sql

@/tmp/ReConnect.sql
REVOKE CREATE SESSION FROM &owner.
/

SPOOL OFF

SET ECHO OFF
SET TIME OFF

!rm -f /tmp/ReConnect.sql
!rm -f /tmp/ConnSYSADM.sql
!rm -f /tmp/Conn&owner..sql
!rm -f /tmp/ConnREPMAN.sql

UNDEFINE DBNAME
UNDEFINE OWNER
UNDEFINE DEFTSP
UNDEFINE TMPTSP
UNDEFINE INDTSP
