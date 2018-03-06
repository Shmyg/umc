/*
Script for umc_finance schema installation
Created by Shmyg
LMD by Shmyg 13.06.2003
*/

ACCEPT owner  DEFAULT donor PROMPT "Enter new user name [donor]: "
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

SPOOL /tmp/ConnCREATOR.sql

SELECT	'connect CREATOR@'||name||';'
FROM	v$database;

SPOOL OFF

SPOOL /tmp/ConnIFACE2SAP.sql

SELECT	'connect iface2sap@'||name||';'
FROM	v$database;

SPOOL OFF

SPOOL /tmp/ConnDEALER.sql

SELECT	'connect dealer@'||name||';'
FROM	v$database;

SPOOL OFF



SET VERIFY ON
SET ECHO ON
SET TIME ON
SET FEEDBACK ON
SET HEADING ON
SET LINESIZE 400
SET PAGESIZE 400
SET TRIMSPOOL ON

SPOOL &owner..log

-- Creating user and roles
CREATE USER &owner
IDENTIFIED BY &owner
DEFAULT TABLESPACE &deftsp
TEMPORARY TABLESPACE &tmptsp
QUOTA 1000M ON &&deftsp
QUOTA 512M ON &&indtsp
/

GRANT CREATE SESSION TO &owner.
/

@/tmp/ConnCREATOR

GRANT EXECUTE ON creator.parameter_t TO &owner.
/
GRANT EXECUTE ON creator.global_vars TO &owner.
/

@/tmp/ConnSYSADM

GRANT SELECT ON cashdetail TO &owner.
/
GRANT SELECT ON cashreceipts_all TO &owner.
/
GRANT SELECT ON convratetypes TO &owner.
/
GRANT SELECT ON currency_version TO &owner.
/
GRANT SELECT ON customer_all TO &owner.
/
GRANT SELECT ON glaccount_all TO &owner.
/
GRANT SELECT ON orderhdr_all TO &owner.
/
GRANT SELECT ON postperiod_all TO &owner.
/
GRANT SELECT ON ordertrailer TO &owner.
/
GRANT SELECT ON tickler_records TO &owner.
/

GRANT UPDATE ON customer_all TO &owner.
/
GRANT UPDATE ON cashreceipts_all TO &owner.
/
GRANT UPDATE ON orderhdr_all TO &owner.
/

GRANT INSERT ON cashreceipts_all TO &owner.
/
GRANT INSERT ON cashdetail TO &owner.
/

-- Added 19.06.2003
GRANT SELECT ON costcenter TO &owner.
/
GRANT SELECT ON pricegroup_all TO &owner.
/

@/tmp/ConnIFACE2SAP

-- Added 19.06.2003
GRANT SELECT ON iface2sap.orders TO &owner.
/

-- Added 09.07.2003
@/tmp/ConnDEALER

GRANT SELECT ON dealer.dealer_export TO &owner.
/

@/tmp/ReConnect

GRANT EXECUTE ON common.umc_finance TO &owner.
/
GRANT EXECUTE ON common.ibu_pos_api_tickler TO &owner.
/

GRANT SELECT ON common.customer_address TO &owner.
/

DROP TYPE &owner..payment_t
/
DROP TYPE &owner..cashdetail_tab
/
DROP TYPE &owner..cashdetail_t
/
DROP TYPE &owner..order_tab
/
DROP TYPE &owner..order_t
/
DROP TABLE &owner..closed_orders
/
DROP TABLE &owner..bad_debt_gl_codes
/

@order/order_t_spec
@order/order_t_body
@order/order_tab
@payment/cashdetail_t_spec
@payment/cashdetail_t_body
@payment/cashdetail_tab
@payment/payment_t_spec
@payment/payment_t_body

CREATE	TABLE &owner..closed_orders
	(
	entdate		DATE,
	customer_id	NUMBER,
	caxact		NUMBER,
	ohxact		NUMBER,
	ohentdate	DATE,
	ohduedate	DATE,
	prgcode		VARCHAR2(2),
	costcenter_id	NUMBER,
	closed_amount	NUMBER,
	inv_amount	NUMBER,
	roam_amount	NUMBER,
	ohinvtype	NUMBER,
	vat_amount	NUMBER
	)
PCTFREE		5
PCTUSED		40
INITRANS	1
MAXTRANS	255
/

COMMENT	ON TABLE &owner..closed_orders
IS 'Bad debt orders closed by automatic write-off'
/
COMMENT ON COLUMN &owner..closed_orders.entdate
IS 'Write-off date'
/
COMMENT ON COLUMN &owner..closed_orders.caxact
IS 'Transaction which closed the order (CASHDETAIL.CADXACT)'
/
COMMENT ON COLUMN &owner..closed_orders.ohxact
IS 'Order number from ORDERHDR_ALL'
/
COMMENT ON COLUMN &owner..closed_orders.ohentdate
IS 'Order entry date from ORDERHDR_ALL'
/
COMMENT ON COLUMN &owner..closed_orders.ohduedate
IS 'Order due date from ORDERHDR_ALL'
/
COMMENT ON COLUMN &owner..closed_orders.prgcode
IS 'Pricegroup of the customers'
/
COMMENT ON COLUMN &owner..closed_orders.closed_amount
IS 'Amount closed by the transaction (maybe less than invoice amount)'
/
COMMENT ON COLUMN &owner..closed_orders.inv_amount
IS 'Original invoice amount'
/
COMMENT ON COLUMN &owner..closed_orders.roam_amount
IS 'Roaming amount of the invoice'
/
COMMENT ON COLUMN &owner..closed_orders.ohinvtype
IS 'Invoice type'
/
COMMENT ON COLUMN &owner..closed_orders.vat_amount
IS 'VAT amount computed from CLOSED_AMOUNT but not from INV_AMOUNT'
/


CREATE	TABLE &owner..bad_debt_gl_codes
	(
	costcenter_id	NUMBER NOT NULL,
	gl_code		VARCHAR2(30) NOT NULL
	)
PCTFREE		5
PCTUSED		40
INITRANS	1
MAXTRANS	255
/

@data

CREATE	TYPE &owner..number_array_type
AS	VARRAY(5)
OF	NUMBER
/

CREATE	TABLE &owner..payment_config
	(
	tx_id		NUMBER NOT NULL,
	catype		NUMBER NOT NULL,
	careasoncode	NUMBER NOT NULL,
	open_orders	VARCHAR2(1),
	ohinvtype	VARCHAR2(1),
	ohstatuses	number_array_type,
	glatype		NUMBER NOT NULL,
	cagldis		VARCHAR2(24) NOT NULL,
	tickler_des	VARCHAR2(20),
	des		VARCHAR2(200) NOT NULL
	)
/

ALTER	TABLE &owner..payment_config
ADD	CONSTRAINT pk_pay_config
PRIMARY	KEY ( tx_id )
/

COMMENT ON COLUMN &owner..payment_config.catype IS 'Payment type'
/
COMMENT ON COLUMN &owner..payment_config.careasoncode IS 'Reason for payment'
/
COMMENT ON COLUMN &owner..payment_config.open_orders IS 'Flag if open orders should exist to assing payment'
/
COMMENT ON COLUMN &owner..payment_config.glatype IS 'GL-code type (for advance, for expences etc)'
/
COMMENT ON COLUMN &owner..payment_config.cagldis IS 'GL-code for discounts - not used in reality'
/
COMMENT ON COLUMN &owner..payment_config.des IS 'Description'
/

INSERT	INTO &owner..payment_config
	(
	tx_id,
	catype,
	careasoncode,
	open_orders,
	ohinvtype,
	ohstatuses,
	glatype,
	cagldis,
	des
	)
VALUES	(
	1,
	1,
	17,
	'X',
	'IN',
	number_array_type( 2, 5, 8 ),
	2,
	'9999994',
	'Payment on account having open orders'
	)
/
INSERT	INTO &owner..payment_config
	(
	tx_id,
	catype,
	careasoncode,
	open_orders,
	ohinvtype,
	ohstatus,
	glatype,
	cagldis,
	des
	)
VALUES	(
	2,
	1,
	18,
	NULL,
	NULL,
	NULL,
	NULL,
	'9999994',
	'Bounce - actually payment erasing - always negative amount'
	)
/
INSERT	INTO &owner..payment_config
	(
	tx_id,
	catype,
	careasoncode,
	open_orders,
	ohinvtype,
	ohstatuses,
	glatype,
	cagldis,
	des
	)
VALUES	(
	3,
	2,
	21,
	'X',
	'IN',
	number_array_type( 5 ),
	2,
	'9999994',
	'Balancing - transaction which is created when orders is balanced with existing advance'
	)
/

INSERT	INTO &owner..payment_config
	(
	tx_id,
	catype,
	careasoncode,
	open_orders,
	ohinvtype,
	ohstatuses,
	glatype,
	cagldis,
	des
	)
VALUES	(
	4,
	3,
	19,
	NULL,
	NULL,
	NULL,
	2,
	'9999984',
	'Pure advance'
	)
/

INSERT	INTO &owner..payment_config
	(
	tx_id,
	catype,
	careasoncode,
	open_orders,
	ohinvtype,
	ohstatuses,
	glatype,
	cagldis,
	des
	)
VALUES	(
	5,
	4,
	23,
	'X',
	'IN',
	number_array_type( 2, 5, 8 ),
	8,
	'9999984',
	'Write off'
	)
/

INSERT	INTO &owner..payment_config
	(
	tx_id,
	catype,
	careasoncode,
	open_orders,
	ohinvtype,
	ohstatuses,
	glatype,
	cagldis,
	des
	)
VALUES	(
	6,
	14,
	13,
	NULL,
	NULL,
	NULL,
	NULL,
	'9999984',
	'Payment refund - money is taken from customer - actually payment with negative amount'
	)
/

INSERT	INTO &owner..payment_config
	(
	tx_id,
	catype,
	careasoncode,
	open_orders,
	ohinvtype,
	ohstatuses,
	glatype,
	cagldis,
	tickler_des,
	des
	)
VALUES	(
	7,
	9,
	25,
	'X',
	'CM',
	number_array_type( 5 ),
	NULL,
	'9999984',
	'AR ADJUSTMENT',
	'Adjustment - should be assigned to close credit memo'
	)
/

COMMIT
/

SPOOL OFF

SET ECHO OFF
SET TIME OFF

!rm -f /tmp/ReConnect.sql
!rm -f /tmp/ConnSYSADM.sql
!rm -f /tmp/ConnCREATOR.sql