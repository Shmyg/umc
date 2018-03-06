/*
|| Script for automatic contracts reactivation
|| depending on balance of a customer
|| Created by Shmyg
|| Last modified by Shmyg 29.11.2001
*/

SET SERVEROUTPUT ON SIZE 1000000

-- CRUD Matrix for react.sql
--+---------------------------------+---+---+---+---+---+----------------------+
--| OBJECT                          |SEL|INS|UPD|DEL|CRE|OTHER                 |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CONTRACT_ALL                    | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CONTRACT_HISTORY                | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MPULKTMB                        | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CUSTOMER_ALL                    | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| IBU_POS_MESSAGES                | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| <N/A>                           |   |   |   |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+

DECLARE

	v_customer_id_high	NUMBER;
	v_cscurbalance		NUMBER;
	v_unbilled_amount	NUMBER;
	v_csclimit		NUMBER;
	v_request		NUMBER;
	v_result		NUMBER;
	v_message		VARCHAR2(2000);
	v_rowcount		NUMBER := 0;	-- total number of contract processed
	v_count			NUMBER := 0;	-- number of reactivated contracts

	c_sncode		CONSTANT NUMBER := 118;	-- Sncode for 'Reactivation' service
	c_sysdate		CONSTANT DATE := TRUNC( SYSDATE );

	-- Cursor for suspended due to 'Non payment of invoices' or
	-- 'Autosuspension' reason contracts
	CURSOR	contract_cur IS
	SELECT	ca.co_id,
		ca.tmcode,
		ca.sccode,
		ca.customer_id
	FROM	contract_history	ch,
		contract_all		ca
	WHERE	ca.co_id = ch.co_id
	AND	ch.ch_status = 's'
	AND	ch.ch_reason IN (25, 44)
	AND	ch.ch_seqno =
		(
		SELECT	MAX( ch_seqno )
		FROM	contract_history
		WHERE	co_id = ch.co_id
		);

	contract_rec	contract_cur%ROWTYPE;

	fee_insert_failure	EXCEPTION;	-- error while fee insertion

BEGIN

	-- Defining parameters
	common.IBU_POS_Message.Raise_Errors('N');
	common.IBU_POS_API_GMD.SetPackageParameter ('MAX_RETRY_NUMBER', 5000);
	common.IBU_POS_API_GMD.SetPackageParameter ('COMMIT_ON_SUCCESS', 'Y');
	common.IBU_POS_API_GMD.SetPackageParameter ('ERROR_HANDLING', 'Y');
	common.IBU_POS_API_GMD.SetPackageParameter ('CREATE_TICKLERS', 'Y');
	common.IBU_POS_API_GMD.SetPackageParameter ('AUTOROLLBACK', 'Y');

	dbms_application_info.set_module( 'Reactivation', 'Opening contracts cursor' );

	-- Looking for contracts
	OPEN	contract_cur;
	LOOP
		FETCH	contract_cur
		INTO	contract_rec;
		EXIT	WHEN contract_cur%NOTFOUND;

		v_rowcount := contract_cur%ROWCOUNT;

		-- Looking for paymentresponsible and balance
		dbms_application_info.set_module( 'Reactivation', 'Looking for boss of ' || contract_rec.customer_id);
		v_customer_id_high := common.umc_util.find_paymntresp( contract_rec.customer_id );

		-- Looking for balance and credit limit of customer
		SELECT	cscurbalance,
			NVL( csclimit, 0 )
		INTO	v_cscurbalance,
			v_csclimit
		FROM	customer_all
		WHERE	customer_id = v_customer_id_high;

		-- Looking for sum of all calls of the branch
		dbms_application_info.set_module( 'Reactivation', 'Looking for calls of ' || contract_rec.customer_id);
		v_unbilled_amount := common.umc_util.get_unbilled_amount( v_customer_id_high );

		-- Checking total balance
		IF	v_cscurbalance + v_unbilled_amount - v_csclimit < 0	-- Customer has advance
		THEN
			
			v_request := NULL;
			v_result := NULL;

			-- Reactivating contract
			dbms_application_info.set_module( 'Reactivation', 'Activating contract # ' || v_rowcount );
			dbms_output.put_line('Contract: ' || contract_rec.co_id );
			common.IBU_POS_API_GMD.ReactivateContract
				(
				contract_rec.co_id,
				'IT',
				9,
				c_sysdate,
				NULL,
				'X',
				v_request,
				v_result,
				43
				);

			-- Checking result		
			IF	v_result = 0	-- success
			THEN
				v_message := 'Request: ' || TO_CHAR( v_request );
				v_count := v_count + 1;

				-- Inserting fee for reactivation
				v_result := common.umc_util.insert_fee
					(
					contract_rec.co_id,
					c_sncode
					);
				
				-- Checking result
				IF	v_result != 0	-- failure
				THEN
					RAISE	fee_insert_failure;
				END	IF;
				
				-- Logging data
				INSERT	INTO reactivated_customers
					(
					customer_id,
					cscurbalance,
					csclimit,
					unbilled_amount,
					co_id,
					entdate
					)
				VALUES	(
					v_customer_id_high,
					v_cscurbalance,
					v_csclimit,
					v_unbilled_amount,
					contract_rec.co_id,
					SYSDATE
					);
				
			ELSIF	v_result = -1	-- uknown error during reactivation
			THEN
				v_message := 'An unknown DBMS error occurred while activating contract ' || TO_CHAR( contract_rec.co_id );
			ELSIF	v_result < -1	-- registered error during reactivation
			THEN
				SELECT	MAX('Error while reactivation of contract ' || TO_CHAR( contract_rec.co_id ) || ' occurred:'||description||'-'||
					DECODE( error_type,	'P', error_code || ' primary key constraint violated',
								'R', error_code || ' foreign key constraint violated',
								'I', error_code || ' unique key constraint violated',
								'M', error_code || ' mandatory value passed NULL',
								'('||error_code||')' ))
				INTO	v_message 
				FROM	common.ibu_pos_messages
				WHERE	result_code = v_result;
			END	IF;

			-- Logging execution
			dbms_output.put_line(v_message);

		END	IF;
		COMMIT;
	END	LOOP;
	CLOSE	contract_cur;

	-- Statistics
	dbms_output.put_line ( 'Total number of contracts processed: ' || v_rowcount );
	dbms_output.put_line ( 'Number of reactivated contracts: ' || v_count );

EXCEPTION
WHEN	fee_insert_failure
THEN
	dbms_output.put_line ( 'Fatal error: cannot insert fee for customer_id ' || contract_rec.customer_id );
END;
/
