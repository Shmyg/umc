/*
|| Creator schema creation
|| Created by Shmyg
|| Last modified by Shmyg 28.02.2002
*/

ACCEPT owner  DEFAULT creator PROMPT "Enter new user name [creator]:"
ACCEPT deftsp PROMPT "Enter Default tablespace name: "
ACCEPT tmptsp PROMPT "Enter Temp tablespace name: "
ACCEPT indtsp PROMPT "Enter Index tablespace name: "

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

spool &owner..log

-- Creating user and roles
CREATE USER &owner
IDENTIFIED BY &owner
DEFAULT TABLESPACE &deftsp
TEMPORARY TABLESPACE &tmptsp
QUOTA 512M ON &&deftsp
QUOTA 128M ON &&indtsp
/

CREATE ROLE &owner._role
IDENTIFIED BY &owner._role
/

GRANT CREATE SESSION TO &owner.
/

GRANT creator_role TO repadmin_role WITH ADMIN OPTION
/

GRANT EXECUTE ON common.umc_util to &owner._role
/
GRANT EXECUTE ON common.umc_util TO &owner.
/
GRANT EXECUTE ON common.ibu_pos_api_tickler TO &owner.
/
GRANT SELECT ON common.city_info TO &owner.
/
GRANT SELECT ON common.valid_tmcodes TO &owner.
/
GRANT SELECT ON common.city_info TO &owner._role
/
GRANT SELECT ON common.valid_tmcodes TO &owner._role
/

-- Table phone_num
CREATE	TABLE &owner..phone_num
	(
	hmcode		NUMBER NOT NULL,
	hm_part_id	NUMBER NOT NULL,
	left_bound	NUMBER NOT NULL,
	right_bound	NUMBER NOT NULL,
	cost_id		NUMBER,
	phone_type	VARCHAR2(1),
	direct_num	VARCHAR2(1),
	entdate		DATE NOT NULL,
	entuser		VARCHAR2(20) NOT NULL
	)
PCTFREE		10
PCTUSED		40
INITRANS	1
MAXTRANS	255
TABLESPACE	&deftsp
/

COMMENT ON COLUMN &owner..phone_num.hmcode IS 'Logical HLR - part of PK'
/
COMMENT ON COLUMN &owner..phone_num.hm_part_id IS 'ID of part of the logical HLR - part of PK'
/
COMMENT ON COLUMN &owner..phone_num.left_bound IS 'Lower bound of phone numbers'
/
COMMENT ON COLUMN &owner..phone_num.right_bound IS 'Upper bound of phone numbers'
/
COMMENT ON COLUMN &owner..phone_num.direct_num IS 'X - if the phone number is direct'
/
COMMENT ON COLUMN &owner..phone_num.phone_type IS 'Type of number: N - normal, D - fax/data'
/

CREATE	TABLE &owner..stolen_passports
	(
	series		VARCHAR2(2) NOT NULL,
	passportno	NUMBER(6) NOT NULL,
	CONSTRAINT	pkstolen_pass
	PRIMARY KEY
		(
		series,
		passportno
		)
	)
ORGANIZATION	INDEX
TABLESPACE &deftsp;

-- Added 05.12.2002
CREATE	TABLE &owner..error_log
	(
	sql_code	NUMBER,
	sql_errm	VARCHAR2(100),
	sql_date	DATE,
	sql_user	VARCHAR2(30)
	)
PCTFREE		10
PCTUSED		40
INITRANS	1
MAXTRANS	255
TABLESPACE	&deftsp
/

@/tmp/ConnSYSADM

GRANT SELECT ON sysadm.adr_city TO &owner.
/
GRANT SELECT ON sysadm.adr_city_zip TO &owner.
/
GRANT SELECT ON sysadm.app_sequence TO &owner.
/
GRANT SELECT, UPDATE ON sysadm.app_sequence_value TO &owner.
/
GRANT SELECT ON sysadm.bank_all TO &owner.
/
GRANT SELECT, UPDATE ON sysadm.billcycles TO &owner.
/
GRANT SELECT ON sysadm.bill_medium TO &owner.
/
GRANT SELECT, INSERT, UPDATE ON sysadm.ccontact_all TO &owner.
/
GRANT SELECT ON sysadm.convratetypes TO &owner.
/
GRANT SELECT ON sysadm.country TO &owner.
/
GRANT SELECT ON sysadm.currency_version TO &owner.
/
GRANT SELECT, INSERT ON sysadm.customer_all TO &owner.
/
GRANT INSERT ON sysadm.customer_base TO &owner.
/
GRANT SELECT ON sysadm.id_type TO &owner.
/
GRANT INSERT ON sysadm.individual_taxation TO &owner.
/
GRANT SELECT ON sysadm.language TO &owner.
/
GRANT INSERT ON sysadm.mpuubtab TO &owner.
/
GRANT SELECT, INSERT ON sysadm.payment_all TO &owner.
/
GRANT SELECT ON sysadm.pricegroup_all TO &owner.
/
GRANT INSERT ON sysadm.rateplan_hist_occ TO &owner.
/
GRANT SELECT ON sysadm.reasonstatus_all TO &owner.
/
GRANT SELECT ON sysadm.welcome_proc TO &owner.
/
GRANT SELECT ON mputmtab TO &owner.
/
GRANT SELECT ON storage_medium TO &owner.
/
GRANT SELECT ON mpulkpxn TO &owner.
/
GRANT SELECT ON contr_services TO &owner.
/
GRANT SELECT ON mpulktmb TO &owner.
/
GRANT SELECT ON sysadm.port TO &owner.
/
GRANT SELECT ON mpdsctab TO &owner.
/
GRANT SELECT ON sub_market TO &owner.
/
GRANT SELECT ON mdsrrtab TO &owner.
/
GRANT SELECT ON mpusntab TO &owner.
/
GRANT SELECT ON gmd_mpdsctab TO &owner.
/
GRANT SELECT ON mpdpltab TO &owner.
/
GRANT INSERT, UPDATE ON contr_services TO &owner.
/
GRANT SELECT ON mpulknxg TO &owner.
/
GRANT INSERT ON contr_tariff_options TO &owner.
/
GRANT SELECT, INSERT, UPDATE ON contract_all TO &owner.
/
GRANT SELECT ON contr_devices TO &owner.
/
GRANT SELECT ON mpdhltab TO &owner.
/
GRANT INSERT ON gmd_request_base TO &owner.
/
GRANT INSERT ON mdsrrtab TO &owner.
/
GRANT SELECT, INSERT ON contract_history TO &owner.
/
GRANT INSERT ON mpufdtab TO &owner.
/
GRANT INSERT ON contr_devices TO &owner.
/
GRANT UPDATE ON port TO &owner.
/
GRANT UPDATE ON storage_medium TO &owner.
/
GRANT SELECT, UPDATE ON directory_number TO &owner.
/
GRANT SELECT, INSERT, UPDATE ON contr_services_cap TO &owner.
/
GRANT SELECT ON mpdhmtab TO &owner.
/
GRANT INSERT ON rateplan_hist TO &owner.
/
GRANT INSERT ON info_contr_text TO &owner.
/
GRANT REFERENCES ON mpdhltab TO &owner.
/
GRANT REFERENCES ON costcenter TO &owner.
/
GRANT SELECT ON bank_all TO &owner._role
/
GRANT SELECT ON adr_city_zip TO &owner._role
/
GRANT SELECT ON customer_all TO &owner._role
/
GRANT SELECT ON ccontact_all TO &owner._role
/
GRANT SELECT ON id_type TO &owner._role
/
GRANT INSERT ON contr_vas TO &owner.
/
GRANT SELECT, REFERENCES ON mpulknxv TO &owner.
/
GRANT SELECT, UPDATE, INSERT ON parameter_value TO &owner.
/
GRANT SELECT ON mkt_parameter_action TO &owner.
/
GRANT SELECT ON mkt_gmd_link_action TO &owner.
/
GRANT SELECT, INSERT ON contr_vas TO &owner.
/
GRANT SELECT ON mkt_parameter TO &owner.
/
GRANT SELECT ON service_parameter TO &owner.
/
GRANT SELECT ON parameter_area TO &owner.
/
GRANT SELECT ON mkt_parameter_domain TO &owner.
/
GRANT SELECT ON mkt_parameter_range TO &owner.
/
GRANT INSERT ON parameter_value_base TO &owner.
/
GRANT SELECT ON fu_pack TO &owner.
/
GRANT SELECT ON tickler_records TO &owner.
/

-- Added 20.11.2002
GRANT SELECT ON mpssvtab TO &owner.
/
GRANT SELECT ON data_type TO &owner.
/               
GRANT SELECT ON parameter_type TO &owner.
/

@/tmp/ReConnect

@umc_customer.pks
@umc_customer.pkb
@contract_type.sql

-- Added 20.11.2002
DROP TYPE &owner..contract_t;
DROP TYPE &owner..contr_services_tab;
DROP TYPE &owner..contr_service_t;
DROP TYPE &owner..service_t;
DROP TYPE &owner..mkt_parameters_tab;
DROP TYPE &owner..mkt_parameter_t;
DROP TYPE &owner..parameters_tab;
DROP TYPE &owner..parameter_t;
DROP TYPE &owner..fu_pack_t;
DROP TYPE &owner..dn_parameter_t;

@contract/packages/global_vars.pks
@contract/objects/dn_parameter_t_spec
@contract/objects/dn_parameter_t_body
@contract/objects/fu_pack_t_spec
@contract/objects/fu_pack_t_body
@contract/objects/parameter_t_spec
@contract/objects/parameter_t_body
@contract/objects/parameters_tab
@contract/objects/mkt_parameter_t_spec
@contract/objects/mkt_parameter_t_body
@contract/objects/mkt_parameters_tab
@contract/objects/service_t_spec
@contract/objects/service_t_body
@contract/objects/contr_service_t_spec
@contract/objects/contr_service_t_body
@contract/objects/contr_services_tab
@contract/objects/contract_t_spec
@contract/objects/contract_t_body
@contract/packages/umc_contract.pks
@contract/packages/umc_contract.pkb

-- Added 04.12.2002
DROP TYPE &owner..customer_t;
DROP TYPE &owner..address_t;
DROP TYPE &owner..mail_label_t;
DROP TYPE &owner..postal_address_t;
DROP TYPE &owner..customer_name_t;
DROP TYPE &owner..phones_tab;
DROP TYPE &owner..phone_t;

@customer/objects/phone_t_spec
@customer/objects/phones_tab_t_spec
@customer/objects/customer_name_t_spec
@customer/objects/customer_name_t_body
@customer/objects/postal_address_t_spec
@customer/objects/mail_label_t_spec
@customer/objects/mail_label_t_body
@customer/objects/address_t_spec
@customer/objects/address_t_body
@customer/objects/customer_t_spec
@customer/objects/customer_t_body


ALTER	TABLE &owner..phone_num
ADD	CONSTRAINT pk_phone_num
PRIMARY	KEY
	(
	hmcode,
	hm_part_id
	)
USING	INDEX
TABLESPACE &indtsp
PCTFREE    10
INITRANS   2
MAXTRANS   255
/

ALTER	TABLE &owner..phone_num
ADD	CONSTRAINT fk_phone_num_mpdhmtab
FOREIGN	KEY
	(
	hmcode
	)
REFERENCES sysadm.mpdhmtab
PCTFREE    10
INITRANS   2
MAXTRANS   255
/

ALTER	TABLE &owner..phone_num
ADD	CONSTRAINT fk_phone_num_costcenter
FOREIGN	KEY
	(
	cost_id
	)
REFERENCES sysadm.costcenter
PCTFREE    10
INITRANS   2
MAXTRANS   255
/

@/tmp/ConnREPMAN

GRANT SELECT ON rep_config TO &owner
/
GRANT EXECUTE ON get_error_message TO &owner.
/

INSERT	INTO rep_roles
	(
	role_name,
	role_passwd,
	des,
	username,
	entdate
	)
VALUES	(
	'CREATOR_ROLE',
	'CREATOR_ROLE',
	'Роль для створення нових абонентів в BSCS',
	USER,
	SYSDATE
	)
/

INSERT	INTO reports
	(
	report_id,
	report_name,
	report_type,
	report_module,
	report_role,
	entdate,
	entuser,
	des
	)
SELECT	MAX( report_id ) + 1,
	'BSCS - створення абонента',
	'FORM',
	'UMC_CUSTOMER',
	'CREATOR_ROLE',
	SYSDATE,
	USER,
	'Форма для занесення даних нових абонентів до BSCS'
FROM	reports
/

@errors.sql

COMMIT
/

@/tmp/Conn&owner

GRANT EXECUTE ON &owner..umc_customer TO &owner._role
/
GRANT SELECT ON &owner..phone_num TO &owner._role
/
GRANT EXECUTE ON &owner..contract TO dealer
/

@/tmp/ReConnect

REVOKE CREATE SESSION FROM &owner.
/

ALTER	TABLE &owner..phone_num
ADD	CONSTRAINT pk_phone_num
PRIMARY	KEY
	(
	hlr,
	digits
	)
USING	INDEX
TABLESPACE &indtsp
PCTFREE    10
INITRANS   2
MAXTRANS   255
/

SPOOL OFF

SET ECHO OFF
SET TIME OFF

!rm -f /tmp/ReConnect.sql
!rm -f /tmp/ConnSYSADM.sql
!rm -f /tmp/Conn&owner..sql
!rm -f /tmp/ConnREPMAN..sql

UNDEFINE DBNAME
UNDEFINE OWNER
UNDEFINE DEFTSP
UNDEFINE TMPTSP
UNDEFINE INDTSP