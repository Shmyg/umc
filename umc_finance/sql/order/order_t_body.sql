CREATE	OR REPLACE
TYPE	BODY &owner..order_t

/*
|| Object describing BSCS order
|| Created by Shmyg
|| Last modified by Shmyg 17.03.2003
*/

AS
MEMBER	PROCEDURE init
	(
	i_ohxact	IN NUMBER
	)
AS
	-- Main cursor for order data
	CURSOR	order_cur
		(
		p_ohxact	NUMBER
		)
	IS
	SELECT	ohxact,
		ohentdate,
		ohinvamt_gl,
		ohopnamt_gl,
		customer_id,
		ohglar,
		ohrefnum,
		ohstatus,
		ohinvtype,
		1,
		ohuserid,
		co_id
	FROM	orderhdr_all
	WHERE	ohxact = p_ohxact;

BEGIN
	OPEN	order_cur( i_ohxact );

		FETCH	order_cur
		INTO	SELF.tx_id,
			SELF.entdate,
			SELF.inv_amount,
			SELF.open_amount,
			SELF.customer_id,
			SELF.gl_code,
			SELF.ref_number,
			SELF.order_type,
			SELF.invoice_type,
			SELF.tax_category,
			SELF.username,
			SELF.co_id;

	CLOSE	order_cur;

END	init;

MEMBER	FUNCTION check_me
RETURN	BOOLEAN
AS
BEGIN
	NULL;
END	check_me;

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
	)
AS
BEGIN
	NULL;
END	insert_me;


-- Balances current order instance with payments
MEMBER	PROCEDURE balance_payments
AS
BEGIN
	NULL;
END	balance_payments;

MEMBER	FUNCTION vat_amount
RETURN	NUMBER
AS
	v_amount	NUMBER := 0;
BEGIN
	

	SELECT	SELF.inv_amount - SUM( otmerch_gl )
	INTO	v_amount
	FROM	ordertrailer
	WHERE	otxact = SELF.tx_id;

	RETURN	v_amount;

END	vat_amount;

MEMBER	FUNCTION roaming_amount
RETURN	NUMBER
AS
	v_amount	NUMBER := 0;
BEGIN


	SELECT	SUM( otmerch_gl )
	INTO	v_amount
	FROM	ordertrailer
	WHERE	otxact = SELF.tx_id
	AND	otglsale IN
		(
		5700002,
		5700004,
		5700006,
		5700008
		);

	RETURN	v_amount;

END	roaming_amount;

MEMBER	PROCEDURE set_open_amount
	(
	i_amount	IN NUMBER
	)
IS
BEGIN
	SELF.open_amount := i_amount;

	UPDATE	orderhdr_all
	SET	ohopnamt_gl = i_amount,
		ohopnamt_doc = i_amount
	WHERE	ohxact = SELF.tx_id;
END	set_open_amount;
END;

/

SHOW ERROR