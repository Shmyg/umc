CREATE	OR REPLACE
TYPE	BODY &owner..cashdetail_t
AS

MEMBER	PROCEDURE init
	(
	i_pt_tx_id	IN NUMBER,
	i_ord_tx_id	IN NUMBER
	)
AS
BEGIN
	NULL;
END	init;

MEMBER	PROCEDURE insert_me
AS
	c_sysdate		CONSTANT DATE := TRUNC( SYSDATE );
	v_payment_currency	currency_version.fc_id%TYPE;
	-- Date of invoice to be closed by this payment
	v_closed_inv_date	DATE;

	CURSOR	order_cur
		(
		p_ohxact	NUMBER
		)
	IS
	SELECT	ohentdate
	FROM	orderhdr_all
	WHERE	ohxact = p_ohxact;

BEGIN

	SELECT	fc_id
	INTO	v_payment_currency
	FROM	currency_version	outer
	WHERE	gl_curr = 'X'
	AND	version =
		(
		SELECT	MAX( version )
		FROM	currency_version
		WHERE	gl_curr = 'X'
		AND	fc_id = outer.fc_id
		);

	OPEN	order_cur
		(
		SELF.ord_tx_id
		);

		FETCH	order_cur
		INTO	v_closed_inv_date;

	CLOSE	order_cur;
	
	INSERT	INTO cashdetail
		(
		cadxact,
		cadoxact,
		cadglar,
		cadassocxact,
		cadglar_exchange,
		cadjcid_exchange,
		cadexpconvdate_exchange,
		glacode_diff,
		jobcost_id_diff,
		payment_currency,
		document_currency,
		gl_currency,
		cadamt_doc,
		caddisamt_doc,
		cadamt_gl,
		caddisamt_gl,
		cadcuramt_gl,
		cadamt_exchange_gl,
		taxamt_diff_gl,
		cadamt_pay,
		caddisamt_pay,
		cadcuramt_pay,
		cadconvdate_exchange_gl,
		cadconvdate_exchange_doc,
		cadcuramt_doc,
		rec_version
		)
	VALUES	(
		SELF.pt_tx_id,	-- cadxact
		SELF.ord_tx_id,	-- cadoxact
		SELF.gl_code,	-- cadglar
		SELF.ass_pt_tx_id,	-- cadassocxact
		NULL,		-- cadglar_exchange
		NULL,		-- cadjcid_exchange
		v_closed_inv_date,	-- cadexpconvdate_exchange
		NULL,		-- glacode_diff
		NULL,		-- jobcost_id_diff
		v_payment_currency,	-- payment_currency
		v_payment_currency,	-- document_currency
		v_payment_currency,	-- gl_currency
		SELF.amount,	-- cadamt_doc
		NULL,		-- caddisamt_doc
		SELF.amount,	-- cadamt_gl
		NULL,		-- caddisamt_gl
		SELF.amount,	-- cadcuramt_gl
		NULL,		-- cadamt_exchange_gl
		NULL,		-- taxamt_diff_gl
		SELF.amount,	-- cadamt_pay
		NULL,		-- caddisamt_pay
		SELF.amount,	-- cadcuramt_pay
		v_closed_inv_date,	-- cadconvdate_exchange_gl
		v_closed_inv_date,	-- cadconvdate_exchange_doc
		SELF.amount,	-- cadcuramt_doc
		1		-- rec_version
		);
END	insert_me;
END;
/
SHOW ERROR