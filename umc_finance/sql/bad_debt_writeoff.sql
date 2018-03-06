/*
Script for bad debt write-off
Writes off all the orders older than 3 years for customers from commercial
pricegroups and UMC_dealer pricegroup
First we're selecting summary data for invoices to be closed (sum of open
invoices older than c_limitation_period (36 months)).
Then for every customer script assigns write-off with this sum and tries
to close invoices (by means of PAYMENT_T object). In case of any error
transaction for this customer is rolled back and error reported. After
successful closing info about closed orders is placed in CLOSED_ORDER table
Created by Shmyg
LMD 19.06.2003 by Shmyg
*/

SET SERVEROUTPUT ON SIZE 1000000

DECLARE
	
	TYPE	number_tab_type
	IS	TABLE
	OF	NUMBER
	INDEX	BY BINARY_INTEGER;

	TYPE	char_tab_type
	IS	TABLE
	OF	VARCHAR2(8)
	INDEX	BY BINARY_INTEGER;

	-- Arrays to store data
	customers		number_tab_type;
	pricegroups		number_tab_type;
	amounts			number_tab_type;
	payments		number_tab_type;
	costcenters		number_tab_type;

	gl_codes		char_tab_type;

	v_ohentdate		DATE;
	v_ohduedate		DATE;

	v_invoice_amount	NUMBER;
	v_closed_amount		NUMBER;
	v_roaming_amount	NUMBER;
	v_vat_amount		NUMBER;

	v_ohxact		PLS_INTEGER;
	v_ohinvtype		PLS_INTEGER;
	v_costcenter_id		PLS_INTEGER;
	i			PLS_INTEGER;
	j			PLS_INTEGER := 1;

	-- Constant holding period to look back for
	c_limitation_period	CONSTANT PLS_INTEGER := -36;

	v_gl_code		bad_debt_gl_codes.gl_code%TYPE;

	-- Payment object for write off transaction
	payment		donor.payment_t := donor.payment_t
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

	-- Cursor for gl_codes
	CURSOR	costcenter_cur
	IS
	SELECT	gl_code
	FROM	donor.bad_debt_gl_codes
	ORDER	BY costcenter_id;

	-- Cursor for general data for write-offs, e.g. customer_id,
	-- pricegroup, costcenter and amount. No detailed info about orders
	-- being closed
	CURSOR	order_cur
	IS
	SELECT	oh.customer_id,
		ca.prgcode,
		ca.costcenter_id,
		SUM( oh.ohopnamt_gl )
	FROM	orderhdr_all	oh,
		customer_all	ca,
		pricegroup_all	pg
	WHERE	ca.customer_id = oh.customer_id
	AND	oh.ohstatus = 'IN'
	AND	oh.ohinvtype IN ( 2, 5, 8 )
	AND	oh.ohopnamt_gl > 0
	AND	ca.prgcode = pg.prgcode
	AND	(
		pg.lettertype = 'COMMERCIAL'
		OR
		pg.prgname = 'UMC_dealer'
		)
	AND	oh.ohentdate < ADD_MONTHS ( TRUNC( SYSDATE, 'MM' ), c_limitation_period )
	AND	NOT EXISTS
		(
		SELECT	*
		FROM	orderhdr_all
		WHERE	customer_id = oh.customer_id
		AND	ohopnamt_gl < 0
		)
	GROUP	BY oh.customer_id,
		ca.costcenter_id,
		ca.prgcode;

	-- Cursor returning data related to closing transaction
	CURSOR	payment_det_cur
		(
		p_payment_id	NUMBER
		)
	IS
	SELECT	oa.ohxact,
		cd.cadamt_gl,
		oa.ohinvamt_gl,
		oa.ohinvtype,
		oa.ohentdate,
		oa.ohduedate
	FROM	orderhdr_all	oa,
		cashdetail	cd
	WHERE	cd.cadoxact = oa.ohxact
	AND	cd.cadxact = p_payment_id;

	/*
	Function computing VAT amount
	Work logics:
	for invoices of 2 and 8 types (not monthly invoices) VAT = 0
	for monhly invoices:
	if closed amount is equal to original invoice amount,
	then
	vat amount = ( closed amount - roaming amount)/6
	if closed amount is less than original invoice amount,
	then
	vat amount = ( closed amount - roaming amount)/6 also if closed amount
	is greater than roaming amount, else it is equal to 0
	*/
	FUNCTION	vat_amount
		(
		i_order_type		NUMBER,
		i_invoice_amount	NUMBER,
		i_closed_amount		NUMBER,
		i_roaming_amount	NUMBER
		)
	RETURN	NUMBER
	IS
		v_vat_amount	NUMBER := 0;
	BEGIN

	IF	i_order_type = 5
	THEN
		IF	i_closed_amount < i_invoice_amount
		THEN
			IF	i_closed_amount > i_roaming_amount
			THEN
				v_vat_amount := ROUND( ( ( i_closed_amount -
					i_roaming_amount ) / 6 ), 2 );
			END	IF;
		ELSE
			v_vat_amount := ROUND ( ( ( i_invoice_amount -
				i_roaming_amount) / 6), 2 );
		END	IF;
	END	IF;

		RETURN	v_vat_amount;
	END;

BEGIN

	-- Looking for GL-codes. We can simply fill the table because
	-- COSTCENTER_ID is equal to record number in PL/SQL table
	OPEN	costcenter_cur;

		FETCH	costcenter_cur
		BULK	COLLECT
		INTO	gl_codes;
	
	CLOSE	costcenter_cur;

	-- Looking for summary data
	OPEN	order_cur;

		FETCH	order_cur
		BULK	COLLECT
		INTO	customers,
			pricegroups,
			costcenters,
			amounts;

	CLOSE	order_cur;

	IF	customers.COUNT > 0
	THEN
		FOR	i IN customers.FIRST..customers.COUNT
		LOOP

			BEGIN
			
			-- Here we need savepoint to roll the TX back in
			-- case of any error
			SAVEPOINT	start_tx;

			-- Inserting write-off
			payment.insert_me
				(
				customers(i),
				amounts(i),
				'Automatic bad debt write off',
				'Automatic bad debt write off',
				4,
				23,
				gl_codes(costcenters(i))
				);

			-- Closing orders
			payment.close_orders;

			-- Looking for order closed by the TX
			OPEN	payment_det_cur( payment.tx_id );
			LOOP

				FETCH	payment_det_cur
				INTO	v_ohxact,
					v_closed_amount,
					v_invoice_amount,
					v_ohinvtype,
					v_ohentdate,
					v_ohduedate;

				EXIT	WHEN payment_det_cur%NOTFOUND;

				-- Looking for roaming amount
				SELECT	NVL( SUM ( otmerch_gl ), 0 )
				INTO	v_roaming_amount
				FROM	ordertrailer
				WHERE	otxact = v_ohxact
				AND	otglsale IN
					(
					5700002,
					5700004,
					5700006,
					5700008
					);

				-- Calculating VAT amount
				v_vat_amount := vat_amount
						(
						v_ohinvtype,
						v_invoice_amount,
						v_closed_amount,
						v_roaming_amount
						);

				-- Logging processed invoices
				INSERT	INTO donor.closed_orders
					(
					entdate,
					customer_id,
					caxact,
					ohxact,
					ohentdate,
					ohduedate,
					prgcode,
					costcenter_id,
					closed_amount,
					inv_amount,
					roam_amount,
					ohinvtype,
					vat_amount
					)
				VALUES	(
					TRUNC( SYSDATE ),
					customers(i),
					payment.tx_id,
					v_ohxact,
					v_ohentdate,
					v_ohduedate,
					pricegroups(i),
					costcenters(i),
					v_closed_amount,
					v_invoice_amount,
					v_roaming_amount,
					v_ohinvtype,
					v_vat_amount
					);
			END	LOOP;
			CLOSE	payment_det_cur;

		EXCEPTION

			-- Some error ocurred - rolling back and reporting
			WHEN	OTHERS
			THEN
				DBMS_OUTPUT.PUT_LINE( customers(i) || ' ' || SQLERRM );
				ROLLBACK TO start_tx;
		END;

			-- We need to do commit to avoid big rollback
			IF	MOD ( i, 1000 ) = 0
			THEN
				COMMIT;
			END	IF;

		END	LOOP;
	ELSE
		-- We don't have any customer for processing
		DBMS_OUTPUT.PUT_LINE ('No customers to process!' );
	END	IF;
	COMMIT;
END;
/