CREATE OR REPLACE
PACKAGE	BODY &owner..debtors1
AS

	g_username	CONSTANT VARCHAR2(20) := USER;
	g_entdate	CONSTANT DATE := TRUNC( SYSDATE );

PROCEDURE	create_debtors_file
	(
	i_debtor_tab	IN OUT debtor_tab_type
	)
IS

	v_file_handler	UTL_FILE.FILE_TYPE;
	v_path		repman.rep_config.file_dir%TYPE;
	v_filename	VARCHAR2(20);
	v_string	VARCHAR2(100);
	i		BINARY_INTEGER;
	v_count		NUMBER;
	v_total		NUMBER;
BEGIN
	
	-- Looking for configuration data
	SELECT	file_dir
	INTO	v_path
	FROM	repman.rep_config;

	v_filename := TO_CHAR( SYSDATE, 'YYYYMMDDhh24mi' ) || '.txt';

	v_count := i_debtor_tab.COUNT;

	IF	v_count > 0
	THEN

		-- Writing data to the file
		-- Opening
		v_file_handler := UTL_FILE.FOPEN (v_path, v_filename, 'w');
		-- Writing data
		FOR	i IN i_debtor_tab.FIRST..i_debtor_tab.LAST
		LOOP
			v_total := i_debtor_tab(i).csclimit +
				i_debtor_tab(i).cscurbalance +
				i_debtor_tab(i).unbilled_amount;
			v_string := i_debtor_tab(i).dn_num || ',' || TRUNC( v_total, 0 ) ;
			UTL_FILE.PUT_LINE(v_file_handler, v_string);
		END	LOOP;
		-- Closing
		UTL_FILE.FCLOSE(v_file_handler);
	END	IF;

END	create_debtors_file;

PROCEDURE	delete_debtors
	(
	i_debtor_tab	IN OUT NOCOPY debtor_tab_type,
	o_result	OUT NUMBER
	)
IS
	i	BINARY_INTEGER;
BEGIN
	FOR i IN i_debtor_tab.FIRST..i_debtor_tab.COUNT
	LOOP
		DELETE	FROM reactor.umc_debtors
		WHERE	co_id = i_debtor_tab(i).co_id
		AND	entdate = g_entdate;
	END	LOOP;
	o_result := 0;
EXCEPTION
	WHEN	OTHERS
	THEN	
		o_result := -1;
		RETURN;
END	delete_debtors;

PROCEDURE	find_debtors
	(
	i_prgcode	IN customer_all.prgcode%TYPE,
	i_cost_desc	IN CHAR := NULL,
	i_calls		IN CHAR,
	i_market	IN NUMBER := NULL,
	i_treshold	IN NUMBER := 0,
	i_custcode_low	IN customer_all.custcode%TYPE := NULL,
	i_custcode_high	IN customer_all.custcode%TYPE := NULL,
	o_debtor_tab	IN OUT NOCOPY debtor_tab_type
	)
IS
	
	-- Phones array
	TYPE	chars_tab_type
	IS	TABLE
	OF	VARCHAR2(63)
	INDEX	BY BINARY_INTEGER;

	phones_tab	chars_tab_type;
	custcodes	chars_tab_type;
	costcenters	chars_tab_type;
	names		chars_tab_type;

	-- Contracts array
	TYPE	numbers_tab_type
	IS	TABLE
	OF	NUMBER
	INDEX	BY BINARY_INTEGER;

	contracts_tab	numbers_tab_type;
	customers	numbers_tab_type;
	balances	numbers_tab_type;
	limits		numbers_tab_type;

	v_unbilled_amount	NUMBER;
	v_market		INTEGER;
	v_total		NUMBER := 0;
	v_cost_id	NUMBER;
	v_money_paid	NUMBER;		-- total amount of money paid by customer
	v_rowcount	NUMBER := 0;	-- counter for active contracts for one customer
	v_count		NUMBER := 0;	-- counter for processed customers
	v_contr_number	NUMBER := 0;	-- numbers of contracts for paymntresponsible
	v_debth		NUMBER := 0;	-- debth for customer. If i_calls = 'Y', equal to cscurbalance,
					-- else equal to total debth (incl. calls and csclimit)
	v_cost_desc	VARCHAR2(40);

	i		BINARY_INTEGER := 1;
	j		BINARY_INTEGER := 1;
	k		BINARY_INTEGER := 1;

	v_name		VARCHAR2(40);

	-- Cursor for all paymentresponsible customers of certain pricegroup
	CURSOR	customer_cur
		(
		p_prgcode	VARCHAR2
		)
	IS
	SELECT	/*+ PARALLEL( ca, 8) PARALLEL (cc, 8) */ ca.customer_id,
		ca.custcode,
		cc.cclname,
		ce.cost_desc,
		NVL( ca.cscurbalance, 0 ) cscurbalance,
		NVL( ca.csclimit, 0 ) csclimit
	FROM	customer_all	ca,
		costcenter	ce,
		ccontact_all	cc
	WHERE	ce.cost_id = ca.costcenter_id
	AND	cc.customer_id = ca.customer_id
	AND	cc.cccontract = 'X'
	AND	cc.ccseq =
		(
		SELECT	MAX( ccseq )
		FROM	ccontact_all
		WHERE	customer_id = cc.customer_id
		AND	cccontract = 'X'
		)
	AND	ca.paymntresp = 'X'
	AND	ca.cstype = 'a'
	AND	ca.prgcode = p_prgcode
	ORDER	BY ce.cost_desc,
		ca.customer_id;

	-- Cursor for customer payments
	CURSOR	payment_cur
		(
		p_customer_id	NUMBER
		)
	IS
	SELECT	NVL( SUM( cachkamt_gl ), 0 )
	FROM	cashreceipts_all
	WHERE	customer_id = p_customer_id;

	contracts	creator.global_vars.number_tab_type;
	sccodes		creator.global_vars.number_tab_type;
	dn_nums		common.umc_util.char_tab_type;

BEGIN


	dbms_application_info.set_module( 'Find_debtors', 'Opening customer cursor' );

	OPEN	customer_cur
		(
		i_prgcode
		);

		FETCH	customer_cur
		BULK	COLLECT
		INTO	customers,
			custcodes,
			names,
			costcenters,
			balances,
			limits;
	
	CLOSE	customer_cur;

	IF	i_cost_desc IS NOT NULL
	THEN

		FOR	i IN costcenters.FIRST..costcenters.LAST
		LOOP
			IF	costcenters(i) != i_cost_desc
			THEN
				customers.DELETE(i);
				custcodes.DELETE(i);
				names.DELETE(i);
				costcenters.DELETE(i);
				balances.DELETE(i);
				limits.DELETE(i);
			END	IF;
		END	LOOP;
	END	IF;

	i := customers.FIRST;

	IF	i_custcode_low IS NOT NULL
	THEN
		WHILE	i IS NOT NULL
		LOOP
			IF	custcodes(i) < i_custcode_low
			THEN
				customers.DELETE(i);
				custcodes.DELETE(i);
				names.DELETE(i);
				costcenters.DELETE(i);
				balances.DELETE(i);
				limits.DELETE(i);
			END	IF;

			i := customers.NEXT(i);

		END	LOOP;
	END	IF;

	i := customers.FIRST;

	IF	i_custcode_high IS NOT NULL
	THEN
		WHILE	i IS NOT NULL
		LOOP
			IF	custcodes(i) > i_custcode_high
			THEN
				customers.DELETE(i);
				custcodes.DELETE(i);
				names.DELETE(i);
				costcenters.DELETE(i);
				balances.DELETE(i);
				limits.DELETE(i);
			END	IF;

			i := customers.NEXT(i);

		END	LOOP;
	END	IF;

	i := customers.FIRST;

	IF	i_calls = 'Y'
	THEN
		WHILE	i IS NOT NULL
		LOOP
			IF	balances(i) <= 0
			THEN
				customers.DELETE(i);
				custcodes.DELETE(i);
				names.DELETE(i);
				costcenters.DELETE(i);
				balances.DELETE(i);
				limits.DELETE(i);
			END	IF;

			i := customers.NEXT(i);

		END	LOOP;
	END	IF;

	k := customers.FIRST;
	v_count := 1;

	WHILE	 k IS NOT NULL
	LOOP
		
		v_unbilled_amount := 0;

		dbms_application_info.set_module( 'Find_debtors',
			'Processing customer #' || v_count );

		-- Looking for number of customer's contracts
		common.umc_util.find_customer_contracts
			(
			customers(k),
			contracts,
			sccodes,
			dn_nums
			);

		v_contr_number := contracts.COUNT;

		IF	v_contr_number > 0	-- Number of active contracts > 0
		THEN

			-- Looking for unbilled amount for customer
			v_unbilled_amount := common.umc_util.get_unbilled_amount
				(
				customers(k)
				);

			-- Calculating total debth per contract
			v_total := ROUND( ( v_unbilled_amount +
				balances(k) - limits(k) ) / v_contr_number, 2 );

			IF	i_calls = 'Y'
			THEN
				v_debth := balances(k) - limits(k);
			ELSE
				v_debth := v_total;
			END	IF;

			-- Checking if total debth per contract exceeds treshold passed
			IF	v_debth >= i_treshold
			THEN
				-- Check if we should look for both markets or only one
				IF	i_market IS NOT NULL
				THEN
					IF	i_market = 12
					THEN
						v_market := 1;
					ELSE
						v_market := 5;
					END	IF;
				END	IF;
				
				-- Calculating total sum of money paid for customer
				OPEN	payment_cur( customers(k) );
					
					FETCH	payment_cur
					INTO	v_money_paid;

					IF	payment_cur%NOTFOUND	-- Customer hasn't paid yet
					THEN
						v_money_paid := 0;
					END	IF;

				CLOSE	payment_cur;

				FOR	i IN contracts.FIRST..contracts.COUNT
				LOOP
					IF	sccodes(i) = v_market
					THEN
						o_debtor_tab(j).customer_id := customers(k);
						o_debtor_tab(j).custcode := custcodes(k);
						o_debtor_tab(j).name := names(k);
						o_debtor_tab(j).prgcode := i_prgcode;
						o_debtor_tab(j).cost_desc := costcenters(k);
						o_debtor_tab(j).cscurbalance := balances(k);
						o_debtor_tab(j).csclimit := limits(k);
						o_debtor_tab(j).unbilled_amount := v_unbilled_amount;
						o_debtor_tab(j).total_amount := v_total;
						o_debtor_tab(j).money_paid := v_money_paid;
						o_debtor_tab(j).dn_num := dn_nums(i);
						o_debtor_tab(j).co_id := contracts(i);
						j := j + 1;
					END	IF;

				END	LOOP;

			END	IF;

		END	IF;

		k := customers.NEXT(k);
		v_count := v_count + 1;

	END	LOOP;
END	find_debtors;

PROCEDURE	insert_debtors
	(
	i_debtor_tab	IN OUT debtor_tab_type
	)
IS
	i	BINARY_INTEGER := 1 ;
	v_count	NUMBER;

BEGIN
	v_count := i_debtor_tab.COUNT;

	IF	v_count > 0
	THEN
		FOR	i IN i_debtor_tab.FIRST..i_debtor_tab.LAST
		LOOP
			BEGIN
				dbms_application_info.set_module( 'Insert_debtors',
					'Inserting customer #' || i || ' of ' || v_count);
				INSERT	INTO umc_debtors
					(
					customer_id,
					cscurbalance,
					csclimit,
					unbilled_amount,
					total_amount,
					dn_num,
					co_id,
					entdate,
					username
					)
				VALUES	(
					i_debtor_tab(i).customer_id,
					i_debtor_tab(i).cscurbalance,
					i_debtor_tab(i).csclimit,
					i_debtor_tab(i).unbilled_amount,
					i_debtor_tab(i).total_amount,
					i_debtor_tab(i).dn_num,
					i_debtor_tab(i).co_id,
					g_entdate,
					g_username
					);
			EXCEPTION
				WHEN	DUP_VAL_ON_INDEX
				THEN
					NULL;
			END;
		END	LOOP;
	END	IF;
END	insert_debtors;

PROCEDURE	lock_debtors
	(
	i_debtor_tab	IN OUT NOCOPY debtor_tab_type,
	o_result	OUT NUMBER
	)
IS
	i	BINARY_INTEGER;
	v_co_id	NUMBER;
BEGIN
	FOR	i IN i_debtor_tab.FIRST..i_debtor_tab.COUNT
	LOOP
		SELECT	co_id
		INTO	v_co_id
		FROM	reactor.umc_debtors
		WHERE	co_id = i_debtor_tab(i).co_id
		AND	entdate = g_entdate
		FOR	UPDATE;
	END	LOOP;

	o_result := 0;
EXCEPTION
	WHEN	OTHERS
	THEN
		o_result := 1;
		RETURN;
END	lock_debtors;

PROCEDURE	view_debtors
	(
	o_debtor_cur IN OUT debtor_cur_type
	)
IS
BEGIN
	OPEN	o_debtor_cur
	FOR
	SELECT	ub.customer_id,
		ca.custcode,
		SUBSTR( cc.cclname, 1, 40 ),
		ca.prgcode,
		ce.cost_desc,
		ub.cscurbalance,
		ub.csclimit,
		ub.unbilled_amount,
		ub.total_amount,
		0,
		ub.dn_num,
		ub.co_id
	FROM	reactor.umc_debtors	ub,
		customer_all		ca,
		common.customer_address	cc,
		costcenter		ce
	WHERE	ub.customer_id = ca.customer_id
	AND	ca.customer_id = cc.customer_id
	AND	ce.cost_id = ca.costcenter_id
	AND	cc.cccontract = 'X'
	AND	ub.entdate = g_entdate
	AND	ub.processed IS NULL;
END	view_debtors;

PROCEDURE	fill_customer_payments
IS
	-- Cursor for all the customers who hasn't customer_id yet
	CURSOR	customer_cur
	IS
	SELECT	customer_id,
		custcode,
		dn_num
	FROM	reactor.customers_paid
	WHERE	customer_id IS NULL
	FOR	UPDATE OF customer_id;

	-- Cursor for searching customer_id by custcode
	CURSOR	custcode_cur
		(
		p_custcode	VARCHAR
		)
	IS
	SELECT	customer_id
	FROM	customer_all
	WHERE	custcode = p_custcode;

	-- Cursor for searching customer_id by dn_num
	CURSOR	dn_num_cur
		(
		p_dn_num	VARCHAR
		)
	IS
	SELECT	ca.customer_id
	FROM	contract_all		ca,
		contr_services_cap	cs,
		directory_number	dn
	WHERE	dn.dn_id = cs.dn_id
	AND	cs.co_id = ca.co_id
	AND	dn.dn_num = p_dn_num
	AND	cs.cs_deactiv_date IS NULL;

	v_customer_id		customer_all.customer_id%TYPE;
	v_custcode		customer_all.custcode%TYPE;
	v_dn_num		customers_paid.dn_num%TYPE;

BEGIN

	OPEN	customer_cur;
	LOOP
		FETCH	customer_cur
		INTO	v_customer_id,
			v_custcode,
			v_dn_num;
		EXIT	WHEN customer_cur%NOTFOUND;

		IF	v_custcode IS NOT NULL
		THEN
			-- Trying to find customer_id by custcode
			OPEN	custcode_cur( v_custcode );
				FETCH	custcode_cur
				INTO	v_customer_id;
			CLOSE	custcode_cur;

			IF	v_customer_id IS NULL -- We didn't find customer_id
			THEN
				-- Maybe we can use dn_num
				IF	v_dn_num IS NOT NULL
				THEN
					-- Trying to find id by phone					
					OPEN	dn_num_cur( v_dn_num );
						FETCH	dn_num_cur
						INTO	v_customer_id;
					CLOSE	dn_num_cur;
				END	IF;
			END	IF;
		-- Custcode is not null - trying dn_num
		ELSIF	v_dn_num IS NOT NULL
		THEN
			OPEN	dn_num_cur( v_dn_num );
				FETCH	dn_num_cur
				INTO	v_customer_id;
			CLOSE	dn_num_cur;
		END	IF;
		
		UPDATE	customers_paid
		SET	customer_id = v_customer_id
		WHERE	CURRENT OF customer_cur;

	END	LOOP;
END	fill_customer_payments;

END	debtors1;
/
SHOW ERRORS
