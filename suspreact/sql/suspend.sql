/*
|| Script for automatic contracts suspension
|| suspend.sql
|| Number of contracts to procees must be passed in command line
|| Created by Shmyg
|| LMD by Shmyg 28.01.2003
*/

SET SERVEROUTPUT ON SIZE 1000000
SET VERIFY OFF

-- CRUD Matrix for suspend.sql
--+---------------------------------+---+---+---+---+---+----------------------+
--| OBJECT                          |SEL|INS|UPD|DEL|CRE|OTHER                 |
--+---------------------------------+---+---+---+---+---+----------------------+
--| UMC_DEBTORS                     | X |   | X |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MDSRRTAB                        | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| IBU_POS_MESSAGES                | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| <N/A>                           |   |   |   |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+

DECLARE

	v_co_id		NUMBER;
	v_rowid		UROWID;
	v_pend_req_num	NUMBER;
	v_request	NUMBER;
	v_result	NUMBER;
	v_contr_num	NUMBER := 1;	-- Counter for suspended contracts
	v_message	VARCHAR2(2000);
	c_sysdate	CONSTANT DATE := TRUNC( SYSDATE );

	-- Cursor for contracts to suspend
	CURSOR	contract_cur IS
	SELECT	co_id,
		ROWID
	FROM	reactor.umc_debtors
	WHERE	processed IS NULL
	-- Filter to remove customers who paid money but money is not
	-- processed yet. May be used not only with this purpose
	AND	customer_id NOT IN
		(
		SELECT	customer_id
		FROM	reactor.customers_paid
		WHERE	entdate >= c_sysdate - 1
		AND	customer_id IS NOT NULL
		)
	-- Filter to remove NMT phones (NMT migration project)
	AND	co_id NOT IN
		(
		SELECT	co_id
		FROM	contract_all
		WHERE	tmcode = 97
		)
	AND	entdate >= c_sysdate - 1;

	too_many_requests	EXCEPTION;

BEGIN

	-- Checking pending requests number
	dbms_application_info.set_module('Suspension', 'Counting pending requests');	

	SELECT	COUNT(*)
	INTO	v_pend_req_num
	FROM	mdsrrtab
	WHERE	request_update IS NULL;

	IF	v_pend_req_num > &1	-- Too many requests pending
	THEN
		RAISE	too_many_requests;	-- Quitting
	END	IF;

	-- Defining parameters
	common.IBU_POS_Message.Raise_Errors('N');
	common.IBU_POS_API_GMD.SetPackageParameter ('MAX_RETRY_NUMBER', 5000);
	common.IBU_POS_API_GMD.SetPackageParameter ('COMMIT_ON_SUCCESS', 'Y');
	common.IBU_POS_API_GMD.SetPackageParameter ('ERROR_HANDLING', 'Y');
	common.IBU_POS_API_GMD.SetPackageParameter ('CREATE_TICKLERS', 'Y');
	common.IBU_POS_API_GMD.SetPackageParameter ('AUTOROLLBACK', 'Y');

	-- Looking for contracts
	dbms_application_info.set_module('Suspension' , 'Opening contracts cursor');

	OPEN	contract_cur;

	WHILE	v_contr_num <= &1	-- To avoid insertion of too many requests
	LOOP
		FETCH	contract_cur
		INTO	v_co_id,
			v_rowid;

		IF	contract_cur%NOTFOUND	-- All contracts processed
		THEN
			DBMS_OUTPUT.PUT_LINE('All contracts from table UMC_DEBTORS except those from CUSTOMERS_PAID processed!');
			EXIT;
		END	IF;

		v_request := NULL;
		v_result := NULL;

		-- Suspending...
		dbms_application_info.set_module('Suspension', 'Suspending contract ' || v_contr_num);

		common.IBU_POS_API_GMD.SuspendContract
			(
			v_co_id,
			'IT',
			5,
			c_sysdate,
			NULL,
			'X',
			v_request,
			v_result,
			44
			);

		DBMS_OUTPUT.PUT_LINE('Contract: ' || v_co_id );

		-- Checking result
		IF	v_result = 0	-- Success
		THEN
			v_message := 'Request: ' || TO_CHAR( v_request );

			-- Switching completion flag
			UPDATE	reactor.umc_debtors
			SET	processed = 'X'
			WHERE	ROWID = v_rowid;

		ELSIF	v_result = -1	-- Uknown error during suspension
		THEN
			v_message := 'An unknown DBMS error occurred while activating contract ' || TO_CHAR( v_co_id );
		ELSIF	v_result < -1	-- Registered error during suspension
		THEN
			SELECT	MAX('Error while suspention of contract ' || TO_CHAR( v_co_id ) || ' occurred:'||description||'-'||
				DECODE( error_type,	'P', error_code || ' primary key constraint violated',
							'R', error_code || ' foreign key constraint violated',
							'I', error_code || ' unique key constraint violated',
							'M', error_code || ' mandatory value passed NULL',
							'('||error_code||')' ))
			INTO	v_message 
			FROM	common.ibu_pos_messages
			WHERE	result_code = v_result;
		END	IF;

		DBMS_OUTPUT.PUT_LINE( v_message );
		v_contr_num := v_contr_num + 1;

		COMMIT;
	END	LOOP;
	CLOSE	contract_cur;

EXCEPTION
	WHEN	too_many_requests
	THEN	DBMS_OUTPUT.PUT_LINE ('Fatal error: more than ' || &1 || ' pending requests in MDSRRTAB!');
END;
/
