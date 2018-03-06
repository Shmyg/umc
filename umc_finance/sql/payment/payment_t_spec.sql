CREATE	OR REPLACE
TYPE	&owner..payment_t

/*
|| Object describing BSCS payment
|| Created by Shmyg
|| Last modified by Shmyg 07.04.2003
*/

AS	OBJECT
	(
	-- TX id - primary key on CASHRECEIPTS
	tx_id		NUMBER,
	-- Payment entry date
	entdate		DATE,
	-- Total amount
	amount		NUMBER,
	-- Customer ID who owes this payment
	customer_id	NUMBER,
	-- GL-code to put a payment on
	gl_code		VARCHAR2(30),
	-- Check number - stores some data, e.g. bank file name
	check_number	VARCHAR2(30),
	-- Payment type (catype in cashereceipts_all)
	pt_type		NUMBER,
	-- Reason of payment
	reason		NUMBER,
	-- Remark - also stores some data
	remark		VARCHAR2(60),
	-- User who inserted payment
	username	VARCHAR2(30),

	-- Constructor - fills payment instance with data from BSCS DB
	MEMBER	PROCEDURE init
		(
		i_caxact	IN NUMBER
		),

	-- Function to check payment parameters before creation
	-- Checks miscellaneous parameters of payment
	-- Uses RAISE_APPLICATION_ERROR to signal error
	MEMBER	FUNCTION check_me
	RETURN	BOOLEAN,

	-- Procedure to add new payment to BSCS. Simply inserts payment
	-- in CASHRECEIPTS_ALL. No cashdetails are created. Upon successful
	-- insertion if i_close_orders is set to 'Y' calls close_orders
	-- procedure to balance open orders with this payment instance
	MEMBER	PROCEDURE insert_me
		(
		i_customer_id	NUMBER,
		i_amount	NUMBER,
		i_check_number	VARCHAR2,
		i_remark	VARCHAR2,
		-- Next four parameters defaults to simple advance payment
		-- in BSCS (customer hasn't open orders)
		i_pt_type	NUMBER := 3,
		i_reason	NUMBER := 19,
		i_gl_code	VARCHAR2 := '2013050',
		i_disc_gl_code	VARCHAR2 := '9999984',
		i_entdate	DATE := SYSDATE,
		i_close_orders	VARCHAR2 := 'N'
		),

	-- Closes open orders by current payment instance
	-- Closes orders of types 2, 5, 8 order by entry date
	-- If payment amount is greater than sum of open orders, creates
	-- advance (CO) in orderhdr_all
	MEMBER	PROCEDURE close_orders,

	-- Function returning payment details (CASHDETAILS table)
	MEMBER	FUNCTION details
	RETURN	donor.cashdetail_tab,

	-- Function returning orders related to this payment (orders
	-- corresponding to payment details from CASHDETAILS table)
	MEMBER	FUNCTION orders_related
	RETURN	donor.order_tab,

	-- Function returning part of payment which is free and can be
	-- assigned to orders
	MEMBER	FUNCTION amount_left
	RETURN	donor.order_t
	);

/

SHOW ERROR

