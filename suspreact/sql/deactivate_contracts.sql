SET SERVEROUTPUT ON
--SET TERMOUT OFF

/*
|| Script for automatic contracts deactivation
|| Usage: @deactivate_contracts NN, where NN - number of contracts to deactivate
|| (to avoid too many requests in MDSRRTAB)
|| Created by Shmyg
|| LMD by Shmyg 15.05.2003
|| Modified by avt 30.05.2003
|| Added pending check on current contract
*/

DECLARE

	v_rowid		UROWID;

	v_co_id		NUMBER;
	v_pend_req_num	NUMBER;
	v_request	NUMBER;
	v_result	NUMBER;
	v_contr_num	NUMBER := 0;	-- Counter for deactivated contracts

	v_message	VARCHAR2(2000);
	v_processed	VARCHAR2(1);

	c_reason_id	CONSTANT NUMBER := 53; -- Reason for autodeactivation

	c_pendingRequest CONSTANT NUMBER := -328; -- There is a pending GMD request for the specified contract
	v_ch_pending     VARCHAR2(1);
	
	c_sysdate	CONSTANT DATE := TRUNC( SYSDATE );
	
	-- Cursor for contracts to deactivate
	CURSOR	contract_cur IS
	SELECT	co_id,
		ROWID
	FROM	reactor.contracts_to_deactivate
	WHERE	processed IS NULL
	AND	entdate =
		(
		SELECT	MAX( entdate )
		FROM	reactor.contracts_to_deactivate
		)
	AND	action = 'd';

	too_many_requests	EXCEPTION;

BEGIN

	-- Checking pending requests number
	DBMS_APPLICATION_INFO.SET_MODULE
		(
		'Deactivation',
		'Counting pending requests'
		);

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
	DBMS_APPLICATION_INFO.SET_MODULE
		(
		'Deactivation', 
		'Opening contracts cursor'
		);

	OPEN	contract_cur;

	WHILE	v_contr_num <= &1	-- To avoid insertion of too many requests
	LOOP
		FETCH	contract_cur
		INTO	v_co_id,
			v_rowid;

		IF	contract_cur%NOTFOUND	-- All contracts processed
		THEN
			DBMS_OUTPUT.PUT_LINE('No contracts to process!');
			EXIT;
		END	IF;

		v_request := NULL;
		v_result := NULL;

		-- Deactivating...
		DBMS_APPLICATION_INFO.SET_MODULE(
			'Deactivation',
			'Deactivating contract ' || v_contr_num || ' from ' || &1 
			);

                
		-- pending cursor
		SELECT ch_pending
		  INTO v_ch_pending
		  FROM contract_history ch
		 WHERE co_id = v_co_id
		   AND ch_seqno = ( SELECT max(ch_seqno)
		                      FROM contract_history
				     WHERE co_id = ch.co_id );
				     
                IF v_ch_pending is NULL
		THEN				       

		 common.IBU_POS_API_GMD.DeactivateContract
			(
			v_co_id,
			'IT',
			5,
			c_sysdate,
			NULL,
			'X',
			v_request,
			v_result,
			c_reason_id
			);
		ELSE
		 
		 v_result := c_pendingRequest;
		
		END IF;	

		-- Checking result
		IF	v_result = 0	-- Success
		THEN

			v_message := 'Request: ' || TO_CHAR( v_request );
			v_processed := 'X';

		ELSIF	v_result = -1	-- Uknown error during suspension
		THEN
			v_processed := 'E';
			v_message := 'An unknown DBMS error occurred while deactivating contract ' || TO_CHAR( v_co_id );
		ELSIF	v_result < -1	-- Registered error during suspension
		THEN
			v_processed := 'E';
			SELECT	MAX( 'Error while deactivaion of contract ' ||
				TO_CHAR( v_co_id ) ||
				' occurred:' || 
				description ||
				'-' ||
				DECODE( error_type,	'P', error_code || ' primary key constraint violated',
							'R', error_code || ' foreign key constraint violated',
							'I', error_code || ' unique key constraint violated',
							'M', error_code || ' mandatory value passed NULL',
							'('||error_code||')' ))
			INTO	v_message 
			FROM	common.ibu_pos_messages
			WHERE	result_code = v_result;

		END	IF;
			
		-- Logging result
		UPDATE	reactor.contracts_to_deactivate
		SET	processed = v_processed,
			procdate = c_sysdate,
			errmessage = v_message
		WHERE	ROWID = v_rowid;

		v_contr_num := v_contr_num + 1;

		COMMIT;
	END	LOOP;
	CLOSE	contract_cur;

	DBMS_OUTPUT.PUT_LINE( 'Processed ' || v_contr_num || ' contracts' );

EXCEPTION
	WHEN	too_many_requests
	THEN
		DBMS_OUTPUT.PUT_LINE
			(
			'Fatal error: more than ' || &1 || ' pending requests in MDSRRTAB!'
			);
	WHEN	OTHERS
	THEN
		ROLLBACK;
		RAISE;
END;
/
