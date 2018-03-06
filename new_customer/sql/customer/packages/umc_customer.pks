CREATE	OR REPLACE
PACKAGE	&owner..umc_customer
AS

/*
|| Package for customer creation
|| Created by Shmyg
|| Last modified by Shmyg 14.11.2002
*/

/*
Contents:

check_address - procedure to check mandatory address parameters
Access no database objects

check_customer - procedure to check mandatory customer parameters
Access no database objects, but calls check_passport

check_passport - check if customer with specified passport/zkpo number
exists in database and also validity of passportno/zkpo number
CRUD Matrix for check_passport
--+---------------------------------+---+---+---+---+---+----------------------+
--| OBJECT                          |SEL|INS|UPD|DEL|CRE|OTHER                 |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CUSTOMER_ALL                    | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+

check_payment - check ofmandatory financial parameters
Access no database objects

All the check_* procedures return 0 in case of success
In case of failure they return negative number corresponding to err_id
in repman.repman_errors

create_address - procedure for address creation
Inserts address record in ccontact_all
CRUD Matrix for create_address
--+---------------------------------+---+---+---+---+---+----------------------+
--| OBJECT                          |SEL|INS|UPD|DEL|CRE|OTHER                 |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CCONTACT_ALL                    | X | X | X |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CUSTOMER_ALL                    | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| COUNTRY                         | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| LANGUAGE                        | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+

create_customer - procedure for customer's creation
Creates customer in 'interested' status with all default values
Inserts record in customer_all, mpuubtab, tickler_records
Updates app_sequence_value, billcycles
CRUD Matrix for create_customer
--+---------------------------------+---+---+---+---+---+----------------------+
--| OBJECT                          |SEL|INS|UPD|DEL|CRE|OTHER                 |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CUSTOMER_ALL                    | X | X |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| APP_SEQUENCE_VALUE              | X |   | X |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| APP_SEQUENCE                    | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| PRICEGROUP_ALL                  | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| REASONSTATUS_ALL                | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| LANGUAGE                        | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| COUNTRY                         | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| WELCOME_PROC                    | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CURRENCY_VERSION                | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CONVRATETYPES                   | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| BILLCYCLES                      | X |   | X |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MPUUBTAB                        |   | X |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| COMMON.IBU_POS_API_TICKLER      |   |   |   |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+

insert_payment - procedure for financial data insertion of the customer
Inserts record in payment_all
CRUD Matrix for insert_payment
--+---------------------------------+---+---+---+---+---+----------------------+
--| OBJECT                          |SEL|INS|UPD|DEL|CRE|OTHER                 |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CURRENCY_VERSION                | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| PAYMENT_ALL                     | X | X |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+

view_address - procedure for address selection
CRUD Matrix for view_address
--+---------------------------------+---+---+---+---+---+----------------------+
--| OBJECT                          |SEL|INS|UPD|DEL|CRE|OTHER                 |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CCONTACT_ALL                    | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+

view_customer - procedure for customer data selection
CRUD Matrix for view_customer
--+---------------------------------+---+---+---+---+---+----------------------+
--| OBJECT                          |SEL|INS|UPD|DEL|CRE|OTHER                 |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CUSTOMER_ALL                    | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+

view_payment - procedure for viewing financial data of customer
CRUD Matrix for view_payment
--+---------------------------------+---+---+---+---+---+----------------------+
--| OBJECT                          |SEL|INS|UPD|DEL|CRE|OTHER                 |
--+---------------------------------+---+---+---+---+---+----------------------+
--| PAYMENT_ALL                     | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+

create_customer_wrapper - actually doesn't do anything. Simply uses plain
parameters instead of Oracle types to call create_customer
*/

-- Address data record
TYPE	address_rec_type
IS	RECORD
	(
	ccname		ccontact_all.ccname%TYPE,	-- Surname (for persons)
	cclname		ccontact_all.cclname%TYPE,	-- Last name (for persons)
	ccfname		ccontact_all.ccfname%TYPE,	-- Name - MANDATORY
	cccity		ccontact_all.cccity%TYPE,	-- City - MANDATORY
	ccstreet	ccontact_all.ccstreet%TYPE,	-- Street - MANDATORY
	ccstreetno	ccontact_all.ccstreetno%TYPE,	-- Street number - MANDATORY
	ccaddr1		ccontact_all.ccaddr1%TYPE,	-- Region (oblast)
	ccaddr2		ccontact_all.ccaddr2%TYPE,	-- Area (rayon)
	ccaddr3		ccontact_all.ccaddr3%TYPE,	-- Appt. number
	cczip		ccontact_all.cczip%TYPE,	-- Zip - MANDATORY
	cctn		ccontact_all.cctn%TYPE,		-- Phone number - MANDATORY
	cctn_area	ccontact_all.cctn_area%TYPE,	-- Phone code - MANDATORY
	cctn2		ccontact_all.cctn2%TYPE,
	cctn2_area	ccontact_all.cctn2_area%TYPE,
	ccfax		ccontact_all.ccfax%TYPE,
	ccfax_area	ccontact_all.ccfax%TYPE,
	ccemail		ccontact_all.ccemail%TYPE,
	ccjobdesc	ccontact_all.ccjobdesc%TYPE
	);

TYPE	address_cur_type
IS	REF CURSOR
RETURN	address_rec_type;

TYPE	address_tab_type
IS	TABLE
OF	address_rec_type
INDEX	BY BINARY_INTEGER;

-- Main customer data record
TYPE	customer_rec_type
IS	RECORD
	(
	custcode	customer_all.custcode%TYPE,	-- Custcode
	passportno	customer_all.passportno%TYPE,	-- Passportno - MANDATORY
	cscusttype	customer_all.cscusttype%TYPE,	-- Customer type - MANDATORY
	id_type		customer_all.id_type%TYPE,	-- Type of document - MANDATORY
	cssex		customer_all.cssex%TYPE,	-- Sex of the customer - only for persons
	birthdate	DATE,				-- Birthdate - only for persons
	cscomptaxno	customer_all.cscomptaxno%TYPE,	-- Registration number - only for companies
	cscompregno	customer_all.cscompregno%TYPE,	-- Registration number - only for companies
	costcenter_id	customer_all.costcenter_id%TYPE,	-- Costcenter - MANDATORY
	area_id		customer_all.area_id%TYPE,	-- Area - MANDATORY
	csremark_1	customer_all.csremark_1%TYPE,	-- When and where passport issued - for persons
	cstaxable	customer_all.cstaxable%TYPE,	-- Flag if customer should pay taxes
	cspassword	customer_all.cspassword%TYPE	-- Customer password
	);

TYPE	customer_cur_type
IS	REF CURSOR
RETURN	customer_rec_type;

TYPE	customer_tab_type
IS	TABLE
OF	customer_rec_type
INDEX	BY BINARY_INTEGER;

-- Payment data record
TYPE	payment_rec_type
IS	RECORD
	(
	payment_type	payment_all.payment_type%TYPE,	-- Payment type - MANDATORY
	accountowner	payment_all.accountowner%TYPE,
	bankaccno	payment_all.bankaccno%TYPE,
	banksubaccount	payment_all.banksubaccount%TYPE,
	valid_thru_date	payment_all.valid_thru_date%TYPE
	);

TYPE	payment_cur_type
IS	REF CURSOR
RETURN	payment_rec_type;

TYPE	payment_tab_type
IS	TABLE
OF	payment_rec_type
INDEX	BY BINARY_INTEGER;

PROCEDURE	check_address
	(
	i_address_tab	IN address_tab_type,
	o_result	OUT NUMBER
	);
PRAGMA	RESTRICT_REFERENCES( check_address, WNDS, RNDS, RNPS, WNPS );

PROCEDURE	check_customer
	(
	i_customer_tab	IN customer_tab_type,
	o_result	OUT NUMBER
	);
PRAGMA	RESTRICT_REFERENCES( check_customer, WNDS, RNPS, WNPS );

PROCEDURE	check_passport
	(
	i_cscusttype	IN customer_all.cscusttype%TYPE,
	i_passportno	IN customer_all.passportno%TYPE,
	o_result	OUT NUMBER
	);
PRAGMA	RESTRICT_REFERENCES( check_passport, WNDS, RNPS, WNPS );

PROCEDURE	check_payment
	(
	i_payment_tab	IN payment_tab_type,
	o_result	OUT NUMBER
	);
PRAGMA	RESTRICT_REFERENCES( check_payment, WNDS, RNDS, RNPS, WNPS );

PROCEDURE	create_address
	(
	i_customer_id	IN NUMBER,
	i_address_tab	IN address_tab_type,
	i_address_type	IN VARCHAR,
	o_result	OUT NUMBER
	);

PROCEDURE	create_customer
	(
	i_customer_tab	IN OUT customer_tab_type,
	o_customer_id	OUT NUMBER,
	o_result	OUT NUMBER,
	i_tickler	IN VARCHAR DEFAULT 'Y'	-- flag if we should create tickler
	);

PROCEDURE	insert_payment
	(
	i_customer_id	IN NUMBER,
	i_payment_tab	IN payment_tab_type,
	o_result	OUT NUMBER
	);

PROCEDURE	view_address
	(
	i_customer_id	IN customer_all.customer_id%TYPE,
	i_address_type	IN VARCHAR,
	o_address_cur	IN OUT address_cur_type
	);
PRAGMA	RESTRICT_REFERENCES( view_address, WNDS, RNPS, WNPS );

PROCEDURE	view_customer
	(
	i_passportno	IN customer_all.passportno%TYPE,
	o_customer_cur	IN OUT customer_cur_type
	);
PRAGMA	RESTRICT_REFERENCES( view_customer, WNDS, RNPS, WNPS );

PROCEDURE	view_payment
	(
	i_customer_id	IN customer_all.customer_id%TYPE,
	o_payment_cur	IN OUT payment_cur_type
	);
PRAGMA	RESTRICT_REFERENCES( view_payment, WNDS, RNPS, WNPS );



-- convert create_customer for jdbc call
procedure create_customer_wrapper
                  (o_customer_id IN OUT customer_all.customer_id%TYPE,  -- Customer_id
                   passportno    IN customer_all.passportno%TYPE,   -- Passportno - MANDATORY
                   cscusttype    IN customer_all.cscusttype%TYPE,   -- Customer type - MANDATORY
                   id_type       IN customer_all.id_type%TYPE,      -- Type of document - MANDATORY
                   cssex         IN customer_all.cssex%TYPE,        -- Sex of the customer - only for persons
                   birthdate     IN DATE,                           -- Birthdate - only for persons
                   cscomptaxno   IN customer_all.cscomptaxno%TYPE,  -- Registration number - only for companies
                   cscompregno   IN customer_all.cscompregno%TYPE,  -- Registration number - only for companies
                   costcenter_id IN customer_all.costcenter_id%TYPE,    -- Costcenter - MANDATORY
                   area_id       IN customer_all.area_id%TYPE,      -- Area - MANDATORY
                   csremark_1    IN customer_all.csremark_1%TYPE,   -- When and where passport issued - for persons       
                   cstaxable     IN customer_all.cstaxable%TYPE,
                   o_result    OUT NUMBER);

-- convert create_address for jdbc call
procedure create_address_wrapper
                  (v_customer_id IN customer_all.customer_id%TYPE,  -- Customer_id
		   -- ADDRESS
		   ccname        IN ccontact_all.ccname%TYPE,       -- Surname (for persons)
		   cclname       IN ccontact_all.cclname%TYPE,      -- Last name (for persons)
		   ccfname       IN ccontact_all.ccfname%TYPE,      -- Name - MANDATORY
		   cccity        IN ccontact_all.cccity%TYPE,       -- City - MANDATORY
		   ccstreet      IN ccontact_all.ccstreet%TYPE,     -- Street - MANDATORY
		   ccstreetno    IN ccontact_all.ccstreetno%TYPE,   -- Street number - MANDATORY
		   ccaddr1       IN ccontact_all.ccaddr1%TYPE,      -- Region (oblast)
		   ccaddr2       IN ccontact_all.ccaddr2%TYPE,      -- Area (rayon)
		   ccaddr3       IN ccontact_all.ccaddr3%TYPE,      -- Appt. number
		   cczip         IN ccontact_all.cczip%TYPE,        -- Zip - MANDATORY
		   cctn          IN ccontact_all.cctn%TYPE,         -- Phone number - MANDATORY
		   cctn_area     IN ccontact_all.cctn_area%TYPE,    -- Phone code - MANDATORY
		   cctn2         IN ccontact_all.cctn2%TYPE,
		   cctn2_area    IN ccontact_all.cctn2_area%TYPE,
		   ccfax         IN ccontact_all.ccfax%TYPE,
		   ccfax_area    IN ccontact_all.ccfax%TYPE,
		   ccemail       IN ccontact_all.ccemail%TYPE,
		   i_address_type IN VARCHAR,
		   o_result      OUT NUMBER);

-- convert create_bank for jdbc call
procedure create_bank_wrapper
                  (v_customer_id IN customer_all.customer_id%TYPE,  -- Customer_id
                   -- BANK
                   payment_type IN payment_all.payment_type%TYPE,  -- Payment type - MANDATORY
                   accountowner IN payment_all.accountowner%TYPE,
                   bankaccno IN payment_all.bankaccno%TYPE,
                   banksubaccount IN payment_all.banksubaccount%TYPE,
                   valid_thru_date payment_all.valid_thru_date%TYPE,
                   o_result      OUT NUMBER);

-- convert create_tickler for jdbc call
procedure create_tickler_wrapper 
                  (v_customer_id IN customer_all.customer_id%TYPE,  -- Customer_id
                   v_desc IN tickler_records.long_description%TYPE, -- Long description
                   v_user IN tickler_records.created_by%TYPE, -- Name of the user who created the record
                   o_result OUT NUMBER);

END	umc_customer;
/

SHOW ERRORS
