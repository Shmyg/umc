/*
|| Script for selecting contracts which should be deactivated
|| Selects all the contracts which are in 's' status more than 2 billings
|| and owner - paymentresponsible doesn't have any another (except deactive)
|| on his account. Customer also must not have credit limit
|| Uses: CUSTOMER_ALL, CONTRACT_ALL, CONTRACT_HISTORY
|| Usage: @select_contracts_to_deactivate.sql
|| Created by Shmyg
|| LMD by Shmyg 14.05.2003
|| Modified by AVT 04.06.2003 Added checking cusomer paid more than 2 billings
|| Modified by AVT 05.06.2003 Added billing interval as parameter 
|| Usage: @select_contracts_to_deactivate.sql 2 
|| Will be check only 2 billings
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
	reasons		number_tab_type;

	actions		char_tab_type;

	-- Defining reasons. Only contracts suspended due to these ones
	-- must be deactivated
	c_autosuspension_reason	CONSTANT PLS_INTEGER := 44;
	c_non_payment_reason	CONSTANT PLS_INTEGER := 25;
	--c_bill_period_insuspend	CONSTANT PLS_INTEGER := -1;
	--c_bill_period_withoutpaiment CONSTANT PLS_INTEGER := -1;	

	v_customer_id	PLS_INTEGER;
	v_co_id		PLS_INTEGER;
	v_ch_reason	PLS_INTEGER;
	i		PLS_INTEGER := 1;
	j		PLS_INTEGER := 1;
	v_date		DATE;
	v_bills		PLS_INTEGER; 
	
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
	AND	(ca.csclimit IS NULL OR ca.csclimit = 0)
	AND	ch.ch_status = 's'
	AND	ch.ch_validfrom < ADD_MONTHS( p_date, v_bills) --c_bill_period_insuspend )
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
			ch.ch_validfrom > ADD_MONTHS( p_date, v_bills) --c_bill_period_insuspend )
			)
		)
	AND	ch.ch_seqno =
		(
		SELECT	MAX( ch_seqno )
		FROM	contract_history
		WHERE	co_id = ch.co_id
		)
        -- Minus customers with payment for 2 billings
	MINUS
	SELECT  DISTINCT (customer_id)
	FROM    cashreceipts_all
	WHERE   trunc(nvl(cachkdate, caentdate)) >= ADD_MONTHS( p_date, v_bills) --c_bill_period_withoutpaiment)
	AND     cachkamt_gl > 0;

	-- Cursor for contract of the paymentresponsible
	CURSOR	contract_cur
		(
		p_customer_id	NUMBER
		)
	IS
	SELECT	co.customer_id,
		ch.co_id,
		ch.ch_reason
	FROM	contract_history	ch,
		contract_all		co
	WHERE	ch.co_id = co.co_id
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

	wrong_parameter         EXCEPTION;

BEGIN

	-- Looking for last billing date
	SELECT	TRUNC( MAX( lrstart ), 'MM' )
	INTO	v_date
	FROM	bch_history_table;

	--v_date := TO_DATE( '01.02.2003', 'DD.MM.YYYY' );

        -- Looking parameters as billing interval
	v_bills := - ( &1 - 1) ;

        IF v_bills > 0
        THEN
            
            RAISE wrong_parameter;
	                            
        END IF;

	-- Looking for customers
	OPEN	customers_cur( v_date );

		FETCH	customers_cur
		BULK	COLLECT
		INTO	customers;

	CLOSE	customers_cur;

	-- Looking for contracts of customers
	FOR	i IN customers.FIRST..customers.COUNT
	LOOP
		OPEN	contract_cur( customers(i) );
		LOOP
			FETCH	contract_cur
			INTO	v_customer_id,
				v_co_id,
				v_ch_reason;
			EXIT	WHEN contract_cur%NOTFOUND;

			-- Checking if need really to deactivate contract
			-- (it should be suspended with 'Non payment of
			-- invoices' or 'Autosuspension' reasons
			IF	(
				v_ch_reason = c_non_payment_reason
				OR
				v_ch_reason = c_autosuspension_reason
				)
			THEN
				-- We should deactivate this contract
				paymentresps(j) := customers(i);
				owners(j) := v_customer_id;
				contracts(j) := v_co_id;
				reasons(j) := v_ch_reason;
				actions(j) := 'd';
			ELSE
				-- We should only report about this contract
				-- for manual deactivation
				paymentresps(j) := customers(i);
				owners(j) := v_customer_id;
				contracts(j) := v_co_id;
				reasons(j) := v_ch_reason;
				actions(j) := 'r';
			END	IF;

			-- This counter increments through all the customers
			j := j + 1;

		END	LOOP;
		CLOSE	contract_cur;
	END LOOP;

	i := paymentresps.FIRST;

	-- Inserting data into table for future deactivation
	FORALL	i IN paymentresps.FIRST..paymentresps.COUNT
	INSERT	INTO reactor.contracts_to_deactivate
		(
		entdate,
		paymentresp_id,
		customer_id,
		co_id,
		ch_reason,
		action,
		processed,
		procdate,
		errmessage
		)
	VALUES	(
		TRUNC( SYSDATE ),
		paymentresps(i),
		owners(i),
		contracts(i),
		reasons(i),
		actions(i),
		NULL,
		NULL,
		NULL
		);
	COMMIT;

EXCEPTION

        WHEN    wrong_parameter
        THEN
                RAISE_APPLICATION_ERROR( -20001, 'Parameter is wrong !' );
        WHEN    OTHERS
        THEN
                RAISE;
								
END;
/