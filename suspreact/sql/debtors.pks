CREATE OR REPLACE
PACKAGE	&owner..debtors1
AS

/*
|| Package for debtors management
|| Created by Shmyg
|| Last modified by Shmyg 14.03.2002
*/

/*
Contents:

create_debtors_file - procedure for debtors' file creation for future
SMS warning
-- CRUD Matrix for create_debtors_file
--+---------------------------------+---+---+---+---+---+----------------------+
--| OBJECT                          |SEL|INS|UPD|DEL|CRE|OTHER                 |
--+---------------------------------+---+---+---+---+---+----------------------+
--| UTL_FILE                        |   |   |   |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| REP_CONFIG                      | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+

delete_debtors - procedure for debtors deletion from reactor.umc_debtors
-- CRUD Matrix for find_debtors
--+---------------------------------+---+---+---+---+---+----------------------+
--| OBJECT                          |SEL|INS|UPD|DEL|CRE|OTHER                 |
--+---------------------------------+---+---+---+---+---+----------------------+
--| UMC_DEBTORS                     |   |   |   | X |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+

find_debtors - procedure for debtor's search. Looks for customers that have
debth per contract greated than treshold passed
-- CRUD Matrix for find_debtors
--+---------------------------------+---+---+---+---+---+----------------------+
--| OBJECT                          |SEL|INS|UPD|DEL|CRE|OTHER                 |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CUSTOMER_ALL                    | X |   |   |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| COSTCENTER                      | X |   |   |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CCONTACT_ALL                    | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CASHRECEIPTS_ALL                | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+

insert_debtors - Procedure for debtors' data insertion into table umc_debtors
for future suspension
-- CRUD Matrix for find_debtors
--+---------------------------------+---+---+---+---+---+----------------------+
--| OBJECT                          |SEL|INS|UPD|DEL|CRE|OTHER                 |
--+---------------------------------+---+---+---+---+---+----------------------+
--| UMC_DEBTORS                     |   | X |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+

lock_debtors - procedure for debtors locking for future deletion

view_debtors - procedure for viewing customers inserted in umc_debtors during
current day and not suspended yet
-- CRUD Matrix for view_debtors
--+---------------------------------+---+---+---+---+---+----------------------+
--| OBJECT                          |SEL|INS|UPD|DEL|CRE|OTHER                 |
--+---------------------------------+---+---+---+---+---+----------------------+
--| UMC_DEBTORS                     | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CUSTOMER_ALL                    | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CCONTACT_ALL                    | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| COSTCENTER                      | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+

fill_customer_payments - procedure called from trigger after insert on
customers_paid. Looks for data inserted in customers_paid (custcode and dn_num)
and tries to find corresponding customer_id for every record
*/

-- Record describing debtor
TYPE	debtor_rec_type
IS	RECORD
	(
	customer_id	NUMBER,
	custcode	customer_all.custcode%TYPE,
	name		VARCHAR2(40),
	prgcode		customer_all.prgcode%TYPE,
	cost_desc	costcenter.cost_desc%TYPE,
	cscurbalance	NUMBER,
	csclimit	NUMBER,
	unbilled_amount	NUMBER,
	total_amount	NUMBER,
	money_paid	NUMBER,
	dn_num		directory_number.dn_num%TYPE,
	co_id		NUMBER
	);

TYPE	debtor_cur_type
IS	REF CURSOR
RETURN	debtor_rec_type;

-- Table of debtors to return data to form
TYPE	debtor_tab_type
IS	TABLE
OF	debtor_rec_type
INDEX	BY BINARY_INTEGER;

PROCEDURE	create_debtors_file
	(
	i_debtor_tab	IN OUT debtor_tab_type
	);
PRAGMA	RESTRICT_REFERENCES ( create_debtors_file, WNDS );

PROCEDURE	delete_debtors
	(
	i_debtor_tab	IN OUT NOCOPY debtor_tab_type,
	o_result	OUT NUMBER
	);
PRAGMA	RESTRICT_REFERENCES ( delete_debtors, WNPS, RNPS );

PROCEDURE	find_debtors
	(
	i_prgcode	IN customer_all.prgcode%TYPE,	-- Price group - mandatory
	i_cost_desc	IN CHAR := NULL,	-- Costcenter
	i_calls		IN CHAR,	-- Flag if we should look only for customers with positive balance
					-- (debth). Name moved here from earlier version and has no relation to real calls
	i_market	IN NUMBER := NULL,	-- Market (12 - NMT, 140 - GSM)
	i_treshold	IN NUMBER := 0,	-- Treshold
	i_custcode_low	IN customer_all.custcode%TYPE := NULL,	-- Lower bound of custcodes
	i_custcode_high	IN customer_all.custcode%TYPE := NULL,	-- Upper bound of custcodes
	o_debtor_tab	IN OUT NOCOPY debtor_tab_type
	);
PRAGMA	RESTRICT_REFERENCES ( find_debtors, WNDS, WNPS, TRUST );

PROCEDURE	insert_debtors
	(
	i_debtor_tab	IN OUT debtor_tab_type
	);

PROCEDURE	lock_debtors
	(
	i_debtor_tab	IN OUT NOCOPY debtor_tab_type,
	o_result	OUT NUMBER
	);

PROCEDURE	view_debtors
	(
	o_debtor_cur	IN OUT debtor_cur_type
	);
PRAGMA	RESTRICT_REFERENCES ( view_debtors, WNPS, RNPS, WNDS );


PROCEDURE	fill_customer_payments;

END	debtors1;
/

SHOW ERRORS