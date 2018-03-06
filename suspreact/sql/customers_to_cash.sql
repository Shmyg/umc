/*
|| Script for selecting contracts which should be deactivated
|| Selects all the contracts which are in 's' status more than 2 billings
|| and owner - paymentresponsible doesn't have any another (except deactive)
|| on his account. Customer also must not have credit limit
|| Uses: CUSTOMER_ALL, CONTRACT_ALL, CONTRACT_HISTORY
|| Usage: @deactivate_susp_contracts
|| Created by Shmyg
|| LMD by Shmyg 14.05.2003
*/

DECLARE

	-- Defining types for arrays to store data in
	TYPE	number_tab_type
	IS	TABLE
	OF	PLS_INTEGER
	INDEX	BY BINARY_INTEGER;

	TYPE	char_tab_type
	IS	TABLE
	OF	VARCHAR2(1)
	INDEX	BY BINARY_INTEGER;

	-- Defining arrays themselves
	customers	number_tab_type;
	paymentresps	number_tab_type;
	owners		number_tab_type;
	contracts	number_tab_type;
	add_agrs	number_tab_type;

	actions		char_tab_type;

	-- Defining reasons. Only contracts suspended due to these ones
	-- must be deactivated
	c_autosuspension_reason	CONSTANT PLS_INTEGER := 44;
	c_non_payment_reason	CONSTANT PLS_INTEGER := 25;

	-- Period to look back for
	c_period		CONSTANT PLS_INTEGER := -1;

	v_customer_id	PLS_INTEGER;
	v_co_id		PLS_INTEGER;
	v_ch_reason	PLS_INTEGER;
	i		PLS_INTEGER := 1;
	j		PLS_INTEGER := 1;
	v_date		DATE;
	
	too_many_requests	EXCEPTION;

	-- Cursor for customers meeting the requirements
	CURSOR	customers_cur
		(
		p_date	DATE
		)
	IS
	-- Here we select customers having contracts in 's' status more than
	-- two billings
	SELECT	DISTINCT common.umc_util.find_paymntresp( co.customer_id )
	FROM	contract_history	ch,
		contract_all		co,
		customer_all		ca
	WHERE	co.co_id = ch.co_id
	AND	ca.customer_id = common.umc_util.find_paymntresp( co.customer_id )
	AND	ca.csclimit IS NULL
	AND	ch.ch_status = 's'
	AND	ch.ch_validfrom < ADD_MONTHS( p_date, c_period )
	AND	ch.ch_seqno =
		(
		SELECT	MAX( ch_seqno )
		FROM	contract_history
		WHERE	co_id = ch.co_id
		)
	MINUS
	-- Here we filter out customers having active contracts or suspended
	-- not more than 2 billing ago
	SELECT	DISTINCT common.umc_util.find_paymntresp( co.customer_id )
	FROM	contract_history	ch,
		contract_all		co
	WHERE	co.co_id = ch.co_id
	AND	(
		ch.ch_status = 'a'
		OR	(
			ch.ch_status = 's'
			AND
			ch.ch_validfrom > ADD_MONTHS( p_date, c_period )
			)
		)
	AND	ch.ch_seqno =
		(
		SELECT	MAX( ch_seqno )
		FROM	contract_history
		WHERE	co_id = ch.co_id
		);

	-- Cursor for contract of the paymentresponsible
	CURSOR	contract_cur
		(
		p_customer_id	NUMBER
		)
	IS
	SELECT	ch.co_id,
		-- flag if the contract has AA - we don't need any data
		DECODE ( NVL( aa.aa_id, 0), 0, 0, 1 )
	FROM	contract_history	ch,
		contract_all		co,
		executor.active_aa	aa
	WHERE	ch.co_id = co.co_id
	AND	co.co_id = aa.co_id(+)
	AND	co.customer_id IN
		(
		SELECT	customer_id
		FROM	customer_all
		CONNECT	BY PRIOR customer_id = customer_id_high
		AND	paymntresp IS NULL
		START	WITH customer_id = p_customer_id
		)
	AND	ch.ch_status = 's'
	AND	ch.ch_seqno =
		(
		SELECT	MAX( ch_seqno )
		FROM	contract_history
		WHERE	co_id = ch.co_id
		);

BEGIN

	-- Looking for last billing date
/*	SELECT	TRUNC( MAX( lrstart ), 'MM' )
	INTO	i_date
	FROM	bch_history_table;*/

	v_date := TO_DATE( '01.02.2003', 'DD.MM.YYYY' );

	-- Looking for customers
	OPEN	customers_cur( v_date );

		FETCH	customers_cur
		BULK	COLLECT
		INTO	customers;

	CLOSE	customers_cur;

	FORALL	i IN customers.FIRST..customers.COUNT
	INSERT	INTO customers_for_cashcollectors
	(		
	SELECT	cc.custcode || ';' ||
		cc.cclname || ';' ||
		cc.ccfname || ';' ||
		cc.ccname || ';' ||
		cc.cccity || ';' ||
		cc.ccstreet || ';' ||
		cc.ccstreetno || ';' ||
		cc.ccaddr1 || ';' ||
		cc.ccaddr2 || ';' ||
		cc.ccaddr3 || ';' ||
		cc.cczip || ';' ||
		cc.cctn || ';' ||
		cc.cctn_area || ';' ||
		cc.cctn2 || ';' ||
		cc.cctn2_area
	FROM	common.customer_address		cc
	WHERE	cc.customer_id = customers(i)
	);

END;
/

