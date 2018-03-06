CREATE	OR REPLACE
TYPE &owner..order_t

/*
|| Object describing BSCS order
|| Created by Shmyg
|| Last modified by Shmyg 07.04.2003
*/

AS	OBJECT
	(
	-- TX id - primary key on ORDERHDR_ALL
	tx_id		NUMBER,
	-- Payment entry date
	entdate		DATE,
	-- Total amount
	inv_amount	NUMBER,
	-- Open amount - sum to be paid
	open_amount	NUMBER,
	-- Customer ID who owes this order
	customer_id	NUMBER,
	-- GL-code to put an order on
	gl_code		VARCHAR2(30),
	-- Reference number - stores some data, e.g. bank file name
	ref_number	VARCHAR2(30),
	-- Order type, e.g. CO (cash-on), IN (invoice) etc
	order_type	VARCHAR2(2),
	-- Invoice type
	invoice_type	NUMBER,
	-- Tax category (valid values: NULL - no VAT, taxcat_id from tax_category table)
	tax_category	NUMBER,
	-- User who inserted payment
	username	VARCHAR2(30),
	-- Contract which order is assigned to
	co_id		NUMBER,

	-- Constructor - fills invoice instance with data from BSCS DB
	MEMBER	PROCEDURE init
		(
		i_ohxact	IN NUMBER
		),

	-- Function to check order parameters before creation
	-- Now is empty
	MEMBER	FUNCTION check_me
	RETURN	BOOLEAN,

	-- Procedure to add new order to BSCS
	MEMBER	PROCEDURE insert_me
		(
		i_customer_id	NUMBER,
		i_amount	NUMBER,
		i_check_number	VARCHAR2,
		i_remark	VARCHAR2,
		i_glcode	VARCHAR2 := '2013050',
		i_pt_type	VARCHAR2 := NULL,
		i_entdate	DATE := SYSDATE
		),

	-- Balances current order instance with payments
	MEMBER	PROCEDURE balance_payments,

	-- As it can be seen from the name, returns VAT amount for the order
	MEMBER	FUNCTION vat_amount
	RETURN	NUMBER,

	-- Returns roaming amount for the order
	MEMBER	FUNCTION roaming_amount
	RETURN	NUMBER,

	-- Procedure for changing open amount
	MEMBER	PROCEDURE set_open_amount
		(
		i_amount	IN NUMBER
		)
	);

/

SHOW ERROR