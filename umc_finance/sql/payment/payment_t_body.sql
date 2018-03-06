CREATE	OR REPLACE
TYPE	BODY &owner..payment_t
AS

MEMBER	PROCEDURE init
	(
	i_caxact	IN NUMBER
	)
AS

	-- Main cursor for payment data
	CURSOR	caxact_cur
		(
		p_caxact	NUMBER
		)
	IS
	SELECT	customer_id,
		caentdate,
		cachknum,
		cachkamt_gl,
		caglcash,
		catype,
		carem,
		causername,
		careasoncode
	FROM	cashreceipts_all
	WHERE	caxact = p_caxact;

	-- Exceptions
	caxact_not_found	EXCEPTION;

BEGIN

	-- Filling object with data
	OPEN	caxact_cur( i_caxact );

		FETCH	caxact_cur
		INTO	SELF.customer_id,
			SELF.entdate,
			SELF.check_number,
			SELF.amount,
			SELF.gl_code,
			SELF.pt_type,
			SELF.remark,
			SELF.username,
			SELF.reason;

		IF	caxact_cur%NOTFOUND
		THEN
			CLOSE	caxact_cur;
			RAISE	caxact_not_found;
		END	IF;

	CLOSE	caxact_cur;

	SELF.tx_id := i_caxact;

EXCEPTION
	WHEN	caxact_not_found
	THEN
		RAISE_APPLICATION_ERROR( -20001, 'No such payment!' );
END	init;

MEMBER	PROCEDURE insert_me
	(
	i_customer_id	NUMBER,
	i_amount	NUMBER,
	i_check_number	VARCHAR2,
	i_remark	VARCHAR2,
	i_pt_type	NUMBER := 3,
	i_reason	NUMBER := 19,
	i_gl_code	VARCHAR2 := '2013050',
	i_disc_gl_code	VARCHAR2 := '9999984',
	i_entdate	DATE := SYSDATE,
	i_close_orders	VARCHAR2 := 'N'
	)
IS

	v_ppperiod		postperiod_all.ppperiod%TYPE;
	v_payment_currency	currency_version.fc_id%TYPE;
	v_convratetype_gl	convratetypes.convratetype_id%TYPE;
	v_cacostcent		cashreceipts_all.cacostcent%TYPE;
	v_ohxact		orderhdr_all.ohxact%TYPE;
	v_short_description	tickler_records.short_description%TYPE;
	v_long_description	tickler_records.long_description%TYPE;

	-- Transaction number for payment
	caxact			creator.parameter_t :=
					creator.parameter_t( 'MAX_CAXACT' );


	cashdetail		donor.cashdetail_t;
							
	my_details		donor.cashdetail_tab;

	v_caxact		PLS_INTEGER;
	v_result		PLS_INTEGER;

	check_passed		BOOLEAN;

	wrong_pmt_parameters		EXCEPTION;
	order_insertion_failure		EXCEPTION;
	tickler_creation_failure	EXCEPTION;

BEGIN

	SELF.customer_id := i_customer_id;
	SELF.amount := i_amount;
	SELF.gl_code := i_gl_code;
	SELF.pt_type := i_pt_type;

	check_passed := SELF.check_me;

	-- Looking for financial data
	SELECT	ppperiod
	INTO	v_ppperiod
	FROM	postperiod_all
	WHERE	ppglcurmth = 'C';

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

	SELECT	convratetype_id
	INTO	v_convratetype_gl
	FROM	convratetypes
	WHERE	def = 'X';

	-- Looking for customer costcenter
	SELECT	costcenter_id
	INTO	v_cacostcent
	FROM	customer_all
	WHERE	customer_id = i_customer_id;

	v_caxact := caxact.next_value;

	INSERT	INTO cashreceipts_all
		(
		caxact,
		customer_id,
		caentdate,
		carecdate,
		cachknum,
		cachkdate,
		cachkamt,
		caglcash,
		cagldis,
		catype,
		cabatch,
		carem,
		capostgl,
		capp,
		cabankname,
		cabankacc,
		cabanksubacc,
		causername,
		caapplication,
		catransfer,
		cajobcost,
		cadebit_info1,
		cadebit_date,
		cadebit_info2,
		camod,
		camicrofiche,
		capaym_place,
		caglexact,
		cacostcent,
		careasoncode,
		cadocrefnum,
		caprinted,
		caprintedby,
		caglexact_tax,
		caxact_related_transfer,
		payment_currency,
		gl_currency,
		convratetype_gl,
		convratetype_doc,
		cachkamt_gl,
		cadisamt_gl,
		cacuramt_gl,
		cachkamt_pay,
		cadisamt_pay,
		cacuramt_pay,
		balance_exch_diff_gl,
		balance_exch_diff_glacode,
		balance_exch_diff_jcid,
		cabalance_home,
		currency,
		rec_version
		)
	VALUES
		(
		v_caxact,		-- caxact
		i_customer_id,		-- customer_id
		i_entdate,		-- caentdate
		i_entdate,		-- carecdate
		i_check_number,		-- cachknum
		TRUNC( i_entdate ),	-- cachkdate
		i_amount,		-- cachkamt
		i_gl_code,		-- caglcash
		i_disc_gl_code,		-- cagldis
		i_pt_type,		-- catype
		NULL,			-- cabatch
		i_remark,		-- carem
		TRUNC( i_entdate ),	-- capostgl
		v_ppperiod,		-- capp
		NULL,			-- cabankname
		NULL,			-- cabankacc
		NULL,			-- cabanksubacc
		USER,			-- causername
		NULL,			-- caapplication
		NULL,			-- catransfer
		NULL,			-- cajobcost
		NULL,			-- cadebit_info1
		NULL,			-- cadebit_date
		NULL,			-- cadebit_info2
		'X',			-- camod
		NULL,			-- camicrofiche
		NULL,			-- capaym_place
		NULL,			-- caglexact
		v_cacostcent,		-- cacostcent
		i_reason,		-- careasoncode
		LPAD ( TO_CHAR (v_caxact), 10, 0),	-- cadocrefnum
		NULL,			-- caprinted
		NULL,			-- caprintedby
		NULL,			-- caglexact_tax
		NULL,			-- caxact_related_transfer
		v_payment_currency,	-- payment_currency
		v_payment_currency,	-- gl_currency
		v_convratetype_gl,	-- convratetype_gl
		v_convratetype_gl,	-- convratetype_doc
		i_amount,		-- cachkamt_gl
		0,			-- cadisamt_gl
		i_amount,		-- cacuramt_gl
		i_amount,		-- cachkamt_pay
		0,			-- cadisamt_pay
		i_amount,		-- cacuramt_pay
		NULL,			-- balance_exch_diff_gl
		NULL,			-- balance_exch_diff_glacode
		NULL,			-- balance_exch_diff_jcid
		i_amount,		-- cabalance_home
		v_payment_currency,	-- currency
		1			-- rec_version
		);

	init( v_caxact );

	my_details := SELF.details;

	-- If this is real payment (not balancing), we need to do some
	-- extra work...
	IF	SELF.pt_type IN ( 1, 3, 4, 13, 9)
	THEN

		-- changing balance...
		UPDATE	customer_all
		SET	cscurbalance = NVL( cscurbalance, 0 ) - i_amount
		WHERE	customer_id = i_customer_id;
		
		-- check if we need to close orders...
		IF	i_close_orders = 'Y'
		THEN
			-- if we do - close them...
			SELF.close_orders;
		-- If this is an advance, we need to insert advance
		ELSIF	SELF.pt_type IN ( 1, 3 )
		THEN
			v_ohxact := common.umc_finance.insert_order
				(
				SELF.customer_id,
				SELF.check_number,
				-SELF.amount,
				'9999994',
				'CO',
				NULL,
				1,
				i_entdate
				);

			IF	v_ohxact < 0
			THEN
				RAISE	order_insertion_failure;
			ELSE
				-- If order have been inserted correctly,
				-- we need to insert advance in cashetail
				cashdetail := donor.cashdetail_t
						(
						SELF.tx_id,
						v_ohxact,
						'9999994',
						SELF.tx_id,
						SELF.amount
						);

				cashdetail.insert_me;
			END	IF;
		END	IF;

		IF	SELF.pt_type IN ( 1, 3 )
		THEN
			v_short_description := 'AR OVERPAYMENT';
		ELSIF	SELF.pt_type = 13
		THEN
			v_short_description := 'AR CREDIT NOTE';
		ELSIF	SELF.pt_type = 9
		THEN
			v_short_description := 'AR ADJUSTMENTCREDIT NOTE';
		ELSE
			v_short_description := 'AR WRITE OFF';
		END	IF;

		v_long_description := 'IT ' ||
			TO_CHAR( SYSDATE, 'YYYY-MM-DD-hh24.mi.ss' ) ||
			' GRV ' || SELF.amount;

		-- Creating tickler
		common.ibu_pos_api_tickler.setpackageparameter
			(
			'COMMIT_ON_SUCCESS',
			'N'
			);

		common.ibu_pos_api_tickler.setpackageparameter
			(
			'AUTOCOMMIT',
			'N'
			);

		common.ibu_pos_api_tickler.createtickler
			(
			SELF.customer_id,	-- Customer_id
			NULL,	-- Contract_id
			4,	-- Priority
			'SYSTEM',	-- Tickler_code
			'NOTE',		-- Tickler_status
			v_short_description,	-- Short description
			v_long_description,	-- Long_description
			NULL,	-- action ID
			NULL,	-- equipment ID
			NULL,	-- market ID
			NULL,	-- message ID
			NULL,	-- date when the last message was sent
			NULL,	-- user who sent the last message
			NULL,	-- source code ID
			NULL,	-- problem tracking ID
			NULL,	-- type ID
			NULL,	-- usage ID
			'IT',	-- follow up user
			NULL,	-- follow up action ID
			SYSDATE,	-- follow up date
			NULL,	-- X co-ordinate
			NULL,	-- Y co-ordinate
			NULL,	-- distibution list user 1
			NULL,	-- distibution list user 2
			NULL,	-- distibution list user 3
			NULL,	-- user who closed the tickler
			SYSDATE,	-- date when the tickler was sent
			'IT',	-- user who created the tickler
			v_result
			);

	IF	v_result != 0
	THEN
		RAISE	tickler_creation_failure;
	END	IF;

	ELSIF	i_close_orders = 'Y'
	THEN
		-- if we do - close them...
		SELF.close_orders;
	END	IF;
EXCEPTION
	WHEN	wrong_pmt_parameters
	THEN
		RAISE_APPLICATION_ERROR ( -20002, 'Incorrect payment parameters!' );
	WHEN	order_insertion_failure
	THEN
		RAISE_APPLICATION_ERROR ( -20003, 'Cannot insert order!' );
	WHEN	tickler_creation_failure
	THEN
		RAISE_APPLICATION_ERROR ( -20004, 'Cannot create tickler!' );
END	insert_me;

MEMBER	PROCEDURE close_orders
AS

	-- Cursor for total open amount
	CURSOR	order_cur
		(
		p_customer_id	NUMBER
		)
	IS
	SELECT	SUM( ohopnamt_gl )
	FROM	orderhdr_all
	WHERE	customer_id = p_customer_id
	AND	ohstatus = 'IN'
	AND	ohinvtype IN ( 2, 5, 8 )
	AND	ohopnamt_gl > 0;

	-- Cursor for customer's orders
	CURSOR	ohxact_cur
		(
		p_customer_id	NUMBER
		)
	IS
	SELECT	ohxact,
		ohopnamt_gl,
		ohopnamt_doc,
		ohglar
	FROM	orderhdr_all
	WHERE	customer_id = p_customer_id
	AND	ohstatus = 'IN'
	AND	ohinvtype IN ( 2, 5, 8 )
	AND	ohopnamt_gl > 0
	ORDER	BY ohentdate
	FOR	UPDATE OF ohopnamt_gl,
		ohopnamt_doc;

	-- Cursor for Credit Memos
	CURSOR	cm_cur
	
	ohxact_rec		ohxact_cur%ROWTYPE;

	v_open_amount		NUMBER := 0;
	v_amount		NUMBER := SELF.amount;

	my_order		donor.order_t := donor.order_t
							(
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL
							);

	v_ppperiod		postperiod_all.ppperiod%TYPE;
	v_payment_currency	currency_version.fc_id%TYPE := 1;
	v_convratetype_gl	convratetypes.convratetype_id%TYPE := 1;

	v_ohxact		INTEGER;

	c_entdate		CONSTANT DATE := SYSDATE;

	balancing		donor.payment_t := donor.payment_t
							(
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,	
							NULL	
							);

	cashdetail		donor.cashdetail_t;

	my_details		donor.cashdetail_tab :=
					donor.cashdetail_tab();

	order_insertion_failure		EXCEPTION;
	payment_already_assigned	EXCEPTION;
	payment_balanced		EXCEPTION;

BEGIN

	my_details := SELF.details;
	
	-- We need to check if this payments has been partly assigned
	IF	my_details.COUNT = 0
	THEN
		-- This is a new payment which has just been created (it 
		-- doesn't have any details in CASHDETAIL) and thus
		-- we have a whole amount to close orders
		v_amount := SELF.amount;
	ELSE
		-- This payment has already been assigned to some orders (maybe
		-- just created CO transaction in ORDERHDR_ALL - doesn't matter)
		-- For such a payment we need to create new transaction -
		-- balancing 'cause we cannot change details of this payment
		-- We need to find CO created by this payment - there can be
		-- only one (not more) CO transaction for any payment
		my_order := SELF.amount_left;

		-- Looking for this CO's open amount
		IF	my_order.open_amount < 0
		THEN
			-- We have some money and must check total amount
			-- of open orders on customer
			OPEN	order_cur( SELF.customer_id );

				FETCH	order_cur
				INTO	v_open_amount;

			CLOSE	order_cur;

			-- Creating balancing with amount equal to smaller
			-- amount. Here we need recursion for orders closing
			balancing.insert_me
				(
				SELF.customer_id,
				LEAST( v_open_amount, -my_order.open_amount ),
				'Autobalancing',
				'Autobalancing',
				2,
				21,
				SELF.gl_code,
				'9999984',
				SELF.entdate,
				'Y'
				);

			-- Creating record in CASHDETAIL
			cashdetail := donor.cashdetail_t
				(
				balancing.tx_id,
				my_order.tx_id,
				'9999994',
				balancing.tx_id,
				-LEAST( v_open_amount, my_order.open_amount )
				);

			cashdetail.insert_me;

			-- For balancings we need to set amout equal to 0
			UPDATE	cashreceipts_all
			SET	cachkamt = 0,
				catransfer = 'X',
				cachkamt_gl = 0,
				cacuramt_gl = 0,
				cachkamt_pay = 0,
				cacuramt_pay = 0,
				cabalance_home = 0
			WHERE	caxact = balancing.tx_id;

			-- Decreasing open amount of the order
			my_order.set_open_amount( my_order.open_amount +
					LEAST( v_open_amount, -my_order.open_amount ));

		END	IF;

		-- We are here when we've created balancing and closed orders
		-- by it after recursive call or there are not open orders at
		-- all thus we don't have work anymore
		RAISE	payment_balanced;

	END	IF;

	-- Looking for customer's orders
	OPEN	ohxact_cur
		(
		SELF.customer_id
		);
	
	LOOP
		FETCH	ohxact_cur
		INTO	ohxact_rec;
		EXIT	WHEN ohxact_cur%NOTFOUND;

		-- Closing invoice
		-- Checking if invoice can be fully closed
		IF	ohxact_rec.ohopnamt_gl <= v_amount
		THEN

			-- It can be
			UPDATE	orderhdr_all
			SET	ohopnamt_gl = 0,
				ohopnamt_doc = 0
			WHERE	CURRENT OF ohxact_cur;

			v_amount := v_amount - ohxact_rec.ohopnamt_gl;

			cashdetail := donor.cashdetail_t
					(
					SELF.tx_id,
					ohxact_rec.ohxact,
					ohxact_rec.ohglar,
					SELF.tx_id,
					ohxact_rec.ohopnamt_gl
					);

			cashdetail.insert_me;

		ELSE
			-- Invoice is partially closed
			UPDATE	orderhdr_all
			SET	ohopnamt_gl = ohxact_rec.ohopnamt_gl - v_amount,
				ohopnamt_doc = ohxact_rec.ohopnamt_gl - v_amount
			WHERE	CURRENT	OF ohxact_cur;

			-- Here we create payment line with amount of money
			-- rest - not the amount of the order
			cashdetail := donor.cashdetail_t
					(
					SELF.tx_id,
					ohxact_rec.ohxact,
					ohxact_rec.ohglar,
					SELF.tx_id,
					v_amount
					);

			cashdetail.insert_me;

			v_amount := 0;

		END	IF;

		-- Checking if we have some money
		IF	v_amount = 0
		THEN
			-- We don't have money anymore and must quit
			EXIT;
		END	IF;

	END	LOOP;

	CLOSE	ohxact_cur;
	
	-- Checking if there is some money left and this is real payment
	-- If it is - inserting advance
	IF	(
		v_amount > 0
		AND
		SELF.pt_type IN ( 1, 3 )
		)
	THEN
		-- We need to insert order with 'CO' (cash-on) status
		v_ohxact := common.umc_finance.insert_order
			(
			SELF.customer_id,
			SELF.check_number,
			-v_amount,
			'9999994',
			'CO',
			NULL,
			1,
			c_entdate
			);

		IF	v_ohxact < 0
		THEN
			RAISE	order_insertion_failure;
		ELSE
			-- If order have been inserted correctly,
			-- we need to insert advance in cashetail
			cashdetail := donor.cashdetail_t
					(
					SELF.tx_id,
					v_ohxact,
					'9999994',
					SELF.tx_id,
					v_amount
					);

			cashdetail.insert_me;

		END	IF;
	END	IF;

EXCEPTION
	WHEN	payment_already_assigned
	THEN
		NULL;
	WHEN	order_insertion_failure
	THEN
		RAISE_APPLICATION_ERROR( -20003, 'Cannot insert order!' );
	WHEN	payment_balanced
	THEN
		NULL;
END	close_orders;

MEMBER	FUNCTION check_me
RETURN	BOOLEAN
AS

	passed		BOOLEAN := TRUE;
	v_count		NUMBER;
	v_orders_sum	NUMBER;
	v_result	NUMBER;
	v_message	VARCHAR2(200);

	not_passed	EXCEPTION;

BEGIN

	-- Payment amount cannot be negative
	IF	SELF.amount <= 0
	THEN
		v_result := -1;
		v_message := 'Amount is negative!';
		RAISE	not_passed;
	END	IF;

	-- Payment amount should be in format 999999.99
	IF	SELF.amount != ROUND( SELF.amount, 2 )
	THEN
		v_result := -2;
		v_message := 'Amount has more than 2 digits after decimal dot!';
		RAISE	not_passed;
	END	IF;

	-- GL-code must exist in GLACCOUNT_ALL
	IF	SELF.gl_code IS NOT NULL
	THEN
		SELECT	COUNT(*)
		INTO	v_count
		FROM	glaccount_all
		WHERE	glacode = SELF.gl_code;
		
		IF	v_count = 0
		THEN
			v_result := -3;
			v_message := 'Wrong GL-code!';
			RAISE	not_passed;
		END	IF;

	END	IF;

	-- If the payment is write-off, then customer must have open orders
	IF	SELF.pt_type = 4
	THEN

		SELECT	SUM( ohopnamt_gl )
		INTO	v_orders_sum
		FROM	orderhdr_all
		WHERE	customer_id = SELF.customer_id
		AND	ohstatus = 'IN'
		AND	ohinvtype IN ( 2, 5, 8 );

		IF	SELF.amount > v_orders_sum
		THEN
			v_result := -4;
			v_message := 'Write-off amount exceeds total sum of open orders!';
			RAISE	not_passed;
		END	IF;

	END	IF;

	RETURN	passed;

EXCEPTION
	WHEN	not_passed
	THEN
		RAISE_APPLICATION_ERROR ( '-2000' || -v_result, v_message );
END	check_me;

MEMBER	FUNCTION details
RETURN	donor.cashdetail_tab
IS

	-- Cursor for payment details
	CURSOR	cashdetail_cur
		(
		p_cadxact	NUMBER
		)
	IS
	SELECT	cadxact,
		cadoxact,
		cadglar,
		cadassocxact,
		amount
	FROM	cashdetail
	WHERE	cadxact = p_cadxact;

	cashdetail_rec		cashdetail_cur%ROWTYPE;

	-- Variables
	i			PLS_INTEGER := 1;

	-- Objects
	cashdetail		donor.cashdetail_t;

	-- Table with payment details
	my_details		donor.cashdetail_tab :=
					donor.cashdetail_tab();

BEGIN

	-- Looking for payment details
	OPEN	cashdetail_cur( SELF.tx_id );
	LOOP
		FETCH	cashdetail_cur
		INTO	cashdetail_rec;
		EXIT	WHEN cashdetail_cur%NOTFOUND;

		-- Adding one row to the object table
		cashdetail := donor.cashdetail_t
				(
				cashdetail_rec.cadxact,
				cashdetail_rec.cadoxact,
				cashdetail_rec.cadglar,
				cashdetail_rec.cadassocxact,
				cashdetail_rec.amount
				);

		my_details.EXTEND;
		my_details(i) := cashdetail;
		i := i + 1;
	END	LOOP;
	CLOSE	cashdetail_cur;
	RETURN	my_details;
END;

MEMBER	FUNCTION orders_related
RETURN	donor.order_tab
IS

	my_order	order_t := donor.order_t
					(
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL,
					NULL
					);

	-- Table with payment details
	my_details	donor.cashdetail_tab :=
				SELF.details;

	-- Table with orders related to payment
	orders		donor.order_tab :=
				donor.order_tab();

BEGIN

	-- K.I.S.S.
	FOR	i IN my_details.FIRST..my_details.COUNT
	LOOP
		my_order.init ( my_details(i).ord_tx_id );
		orders.EXTEND;
		orders(i) := my_order;
	END	LOOP;
	RETURN	orders;
END	orders_related;

MEMBER	FUNCTION amount_left
RETURN	donor.order_t
IS

	my_order		donor.order_t := donor.order_t
							(
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL
							);

	orders			donor.order_tab :=
					donor.order_tab();

	order_insertion_failure		EXCEPTION;
	payment_already_assigned	EXCEPTION;

BEGIN

	orders := SELF.orders_related;

	IF	orders.COUNT > 0
	THEN
		-- Payment already have been assigned
		FOR	i IN orders.FIRST..orders.COUNT
		LOOP
			-- Looking for advance created by this payment
			-- There can be one and only one such transaction
			IF	orders(i).order_type = 'CO'
			THEN
				my_order := orders(i);
				EXIT;
			END	IF;
		END	LOOP;
	END	IF;
	RETURN	my_order;

END	amount_left;

END;
/

SHOW ERROR