CREATE	OR REPLACE
TYPE	BODY &owner..contr_service_t
AS

MEMBER	PROCEDURE init
	(
	i_co_id		IN NUMBER,
	i_sncode	IN NUMBER
	)
AS

	-- All contract services
	CURSOR	contr_service_cur
		(
		p_co_id		NUMBER,
		p_sncode	NUMBER
		)
	IS
	SELECT	sncode,
		cs_seqno,
		SUBSTR( cs_stat_chng, -1, 1 ) AS status,
		cs_pending_state,
		cs_request,
		prm_value_id
	FROM	contr_services
	WHERE	co_id = p_co_id
	AND	sncode = p_sncode
	AND	cs_seqno =
		(
		SELECT	MAX( cs_seqno )
		FROM	contr_services
		WHERE	co_id = p_co_id
		);
	
	v_sncode	NUMBER;
	v_service	service_t := service_t
					(
					NULL,
					NULL,
					NULL,
					NULL
					);

	no_such_service_on_contract	EXCEPTION;
BEGIN

	OPEN	contr_service_cur
		(
		i_co_id,
		i_sncode
		);

		FETCH	contr_service_cur
		INTO	v_sncode,
			SELF.seqno,
			SELF.status,
			SELF.pending_state,
			SELF.request,
			SELF.prm_value_id;
		
		-- Checking if we have records to fetch
		IF	contr_service_cur%NOTFOUND
		THEN
			RAISE	no_such_service_on_contract;
		ELSE
			SELF.co_id := i_co_id;
			v_service.init( v_sncode );
			SELF.service := v_service;
		END	IF;

	CLOSE	contr_service_cur;

EXCEPTION
	WHEN	no_such_service_on_contract
	THEN
		RAISE_APPLICATION_ERROR( -20001, 'No such service on the contract!' );
	WHEN	OTHERS
	THEN
		RAISE;
END	init;

MEMBER	PROCEDURE set_mkt_parameter
	(
	i_mkt_parameters	IN mkt_parameters_tab
	)
AS

	v_parameter		creator.parameter_t := creator.parameter_t( 'MAX_PRM_VALUE_ID' );
	v_fu_pack		fu_pack_t := fu_pack_t
						(
						NULL,
						NULL,
						NULL
						);

	v_prm_value_id		NUMBER;

	v_prm_value_string	parameter_value.prm_value_string%TYPE;
	v_prm_value_number	parameter_value.prm_value_number%TYPE;
	v_prm_description	parameter_value.prm_description%TYPE;

	no_parameters_needed	EXCEPTION;

BEGIN

	-- Checking number of parameters to be created
	IF	i_mkt_parameters.COUNT = 0
	THEN
		RAISE	no_parameters_needed;
	END	IF;

	-- Looking for next parameter_id value
	v_prm_value_id := v_parameter.next_value;

	-- Logging
	INSERT	INTO parameter_value_base
		(
		prm_value_id,
		entry_date
		)
	VALUES	(
		v_prm_value_id,
		SYSDATE
		);

	-- Assigning parameters
	FOR	i IN i_mkt_parameters.FIRST..i_mkt_parameters.COUNT
	LOOP

		-- Checking mkt_parameter properties
		IF	i_mkt_parameters(i).data_type = 'VARCHAR'
		THEN
			v_prm_value_string := i_mkt_parameters(i).prm_value;
			v_prm_value_number := NULL;
		ELSE
			v_prm_value_string := NULL;
			v_prm_value_number := i_mkt_parameters(i).prm_value;
		END	IF;		

		-- Checking if we are assigning parameters of FUP service
		IF	SELF.service.is_fup_service = TRUE
		THEN
			-- Initializing FU package, 'cause we need it's name
			-- to insert as parameter description
			v_fu_pack.init( i_mkt_parameters(i).parameter_id );
			v_prm_description := v_fu_pack.long_name;
		ELSE
			v_prm_description := NULL;
		END	IF;

		INSERT	INTO parameter_value
			(
			prm_value_id,
			prm_no,
			prm_seqno,
			parent_seqno,
			sibling_seqno,
			complex_seqno,
			value_seqno,
			complex_level,
			parameter_id,
			deleted_flag,
			prm_value_date,
			prm_value_string,
			prm_value_number,
			prm_description,
			prm_valid_from,
			request_id,
			rec_version
			)
		VALUES	(
			v_prm_value_id,		-- prm_value_id
			i_mkt_parameters(i).prm_no,	-- prm_no
			1,			-- prm_seqno
			1,			-- parent_seqno
			1,			-- sibling_seqno
			1,			-- complex_seqno
			1,			-- value_seqno
			1,			-- complex_level
			i_mkt_parameters(i).parameter_id,	-- parameter_id
			NULL,			-- deleted_flag
			NULL,			-- prm_value_date
			v_prm_value_string,	-- prm_value_string
			NULL,			-- prm_value_number
			v_prm_description,		-- prm_description
			TRUNC( SYSDATE ),	-- prm_valid_from
			NULL,			-- request_id
			0			-- rec_version
			);

	END	LOOP;

	UPDATE	contr_services
	SET	prm_value_id = v_prm_value_id
	WHERE	co_id = SELF.co_id
	AND	sncode = SELF.service.sncode
	AND	seqno = SELF.seqno;

	SELF.prm_value_id := v_prm_value_id;

EXCEPTION
	WHEN	no_parameters_needed
	THEN
		NULL;
	WHEN	OTHERS
	THEN
		RAISE;
		-- SELF.prm_value_id := -1;
END	set_mkt_parameter;

MEMBER	PROCEDURE set_dn_parameter
	(
	i_dn_parameter		IN dn_parameter_t
	)
AS

	-- Cursor for status check and update of dn_id passed
	CURSOR	dn_cur
		(
		p_dn_id	NUMBER
		)
	IS
	SELECT	dn_status
	FROM	directory_number
	WHERE	dn_id = p_dn_id
	FOR	UPDATE;

	-- Cursor for check if contract already has main dirnum
	CURSOR	main_dirnum_cur
		(
		p_co_id		NUMBER
		)
	IS
	SELECT	*
	FROM	contr_services_cap
	WHERE	co_id = p_co_id
	AND	main_dirnum = 'X'
	AND	cs_deactiv_date IS NULL;

	-- Cursor for selecting data from contr_service_cap
	CURSOR	contr_services_cur
		(
		p_co_id		NUMBER,
		p_sncode	NUMBER
		)
	IS
	SELECT	seqno
	FROM	contr_services_cap
	WHERE	co_id = p_co_id
	AND	sncode = p_sncode
	AND	seqno =
		(
		SELECT	MAX( seqno )
		FROM	contr_services_cap
		WHERE	co_id = p_co_id
		AND	sncode = p_sncode
		)
	FOR	UPDATE;

	main_dirnum_rec		main_dirnum_cur%ROWTYPE;

	v_seqno			NUMBER;
	v_seqno_pre		NUMBER;
	v_dn_status		VARCHAR2(1);

	dn_not_found		EXCEPTION;
	not_bearer_service	EXCEPTION;
	empty_dn_id		EXCEPTION;
	wrong_dn_status		EXCEPTION;

BEGIN

	-- Checking if service is bearer service
	IF	SELF.service.is_bearer_service = FALSE
	THEN
		RAISE	not_bearer_service;
	END	IF;

	IF	i_dn_parameter.dn_id IS NULL
	THEN
		RAISE	empty_dn_id;
	ELSE

		-- Checking dn_id passed
		OPEN	dn_cur( i_dn_parameter.dn_id );

			FETCH	dn_cur
			INTO	v_dn_status;

			IF	dn_cur%NOTFOUND
			THEN
				RAISE	dn_not_found;
			ELSIF	v_dn_status != 'r'
			THEN
				RAISE	wrong_dn_status;
			ELSE
				UPDATE	directory_number
				SET	dn_status = 'a'
				WHERE	CURRENT OF dn_cur;
			END	IF;
		CLOSE	dn_cur;
	END	IF;


	OPEN	contr_services_cur
		(
		SELF.co_id,
		SELF.service.sncode
		);

		FETCH	contr_services_cur
		INTO	v_seqno;
		
		-- Checking if there are records for
		-- this contract and sncode
		-- in contr_service_cap
		IF	contr_services_cur%FOUND
		THEN
			v_seqno_pre := v_seqno;
			v_seqno := v_seqno + 1;
		ELSE
			-- This is the first record in contr_services
			-- for this service
			v_seqno_pre := NULL;
			v_seqno := 1;
		END	IF;

		OPEN	main_dirnum_cur( SELF.co_id );
			
			FETCH	main_dirnum_cur
			INTO	main_dirnum_rec;

			IF	main_dirnum_cur%FOUND
			THEN
				main_dirnum_rec.main_dirnum := NULL;
			ELSE
				main_dirnum_rec.main_dirnum := 'X';
			END	IF;

		CLOSE	main_dirnum_cur;

	CLOSE	contr_services_cur;

	INSERT	INTO contr_services_cap
		(
		co_id,
		sncode,
		seqno,
		seqno_pre,
		bccode,
		pending_bccode,
		dn_id,
		main_dirnum,
		cs_status,
		cs_activ_date,
		cs_deactiv_date,
		cs_request,
		rec_version,
		dn_block_id
		)
	VALUES	(
		SELF.co_id,
		SELF.service.sncode,
		v_seqno,
		v_seqno_pre,
		NULL,
		NULL,
		i_dn_parameter.dn_id,
		DECODE( SELF.service.sncode, 12, main_dirnum_rec.main_dirnum, NULL ),
		DECODE( v_seqno, 1, 'O', 'R' ),
		NULL,
		NULL,
		NULL,
		DECODE( v_seqno, 1, 0, v_seqno + 1 ),
		NULL
		);
	
	UPDATE	directory_number
	SET	dn_status = 'a'
	WHERE	dn_id = i_dn_parameter.dn_id;

EXCEPTION
	WHEN	dn_not_found
	THEN
		RAISE_APPLICATION_ERROR( -20001, 'No such phone number!' );
	WHEN	not_bearer_service
	THEN
		RAISE_APPLICATION_ERROR( -20002, 'Service is not bearer one!' );
	WHEN	empty_dn_id
	THEN
		RAISE_APPLICATION_ERROR( -20003, 'Phone number is missing!' );
	WHEN	wrong_dn_status
	THEN
		RAISE_APPLICATION_ERROR( -20004, 'Phone number is not reserved!' );
	WHEN	OTHERS
	THEN
		RAISE;
END	set_dn_parameter;
END;
/
SHOW ERROR

