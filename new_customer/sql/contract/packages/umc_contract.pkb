CREATE	OR REPLACE
PACKAGE	BODY &owner..umc_contract
AS

	g_username	CONSTANT VARCHAR2(20) := USER;
	c_sysdate	CONSTANT DATE := TRUNC( SYSDATE );

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

	-- Constants for services which need record
	-- to be inserted in contr_services_cap
	c_gsm_sncode		CONSTANT NUMBER := 12;
	c_fax_sncode		CONSTANT NUMBER := 19;
	c_data_sncode		CONSTANT NUMBER := 30;
	c_nmt_sncode		CONSTANT NUMBER := 140;


	-- Global exceptions
	not_active_contract	EXCEPTION;

/*
create_service_parameters - creates all parameters for service if needed
In case of success return prm_value_id, in case of failure - negative number
corresponding to error number

-- CRUD for create_service_parameters
--+---------------------------------+---+---+---+---+---+----------------------+
--| OBJECT                          |SEL|INS|UPD|DEL|CRE|OTHER                 |
--+---------------------------------+---+---+---+---+---+----------------------+
--| APP_SEQUENCE_VALUE              | X |   | X |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| APP_SEQUENCE                    | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| SERVICE_PARAMETER               | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| PARAMETER_AREA                  | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MKT_PARAMETER                   | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| PARAMETER_VALUE                 |   | X |   |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MKT_PARAMETER_RANGE             | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MKT_PARAMETER_DOMAIN            | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+

*/
FUNCTION	create_service_parameters
	(
	i_sccode	NUMBER,
	i_svcode	NUMBER,
	i_param		NUMBER := NULL,
	i_param_des	VARCHAR2 := NULL
	)
RETURN	NUMBER
IS

	-- Cursor for next parameter id
	CURSOR	prm_value_id_cur
	IS
	SELECT	next_free_value
	FROM	app_sequence_value
	WHERE	app_sequence_id =
		(
		SELECT	app_sequence_id
		FROM	app_sequence
		WHERE	app_sequence_key = 'MAX_PRM_VALUE_ID'
		)
	FOR	UPDATE;
	
	-- Cursor for all parameters belonging to service
	CURSOR	parameter_cur
		(
		p_sccode	NUMBER,
		p_svcode	NUMBER
		)
	IS
	SELECT	sp.parameter_id,
		sp.prm_no,
		pa.parameter_type_id,
		pa.parameter_area_id
	FROM	service_parameter	sp,
		parameter_area		pa,
		mkt_parameter		mp
	WHERE	sp.parameter_id = mp.parameter_id
	AND	pa.parameter_area_id = mp.parameter_area_id
	AND	sp.sccode = p_sccode
	AND	sp.svcode = p_svcode
	AND	mp.sccode = p_sccode;

	parameter_rec	parameter_cur%ROWTYPE;

	TYPE	prm_value_cur_type
	IS	REF CURSOR;

	prm_value_cur	prm_value_cur_type;

	v_prm_value_id		app_sequence_value.next_free_value%TYPE;

	-- Variables of diff types to store parameters data
	v_prm_value_string	parameter_value.prm_value_string%TYPE;
	v_prm_value_number	parameter_value.prm_value_number%TYPE;

	-- Names of tables to retreive parameter values
	-- depending on parameter_type_id
	c_mkt_parameter_domain	CONSTANT NUMBER := 9;
	c_mkt_parameter_range	CONSTANT NUMBER := 4;

BEGIN

	-- Looking for next parameter number
	OPEN	prm_value_id_cur;

		FETCH	prm_value_id_cur
		INTO	v_prm_value_id;

		UPDATE	app_sequence_value
		SET	next_free_value = next_free_value + 1
		WHERE	CURRENT OF prm_value_id_cur;

	CLOSE	prm_value_id_cur;

	INSERT	INTO parameter_value_base
		(
		prm_value_id,
		entry_date
		)
	VALUES	(
		v_prm_value_id,
		SYSDATE
		);

	-- Looking for all parameters needed for the service
	OPEN	parameter_cur
		(
		i_sccode,
		i_svcode
		);

	LOOP
	
		FETCH	parameter_cur
		INTO	parameter_rec;
		EXIT	WHEN parameter_cur%NOTFOUND;

		-- Looking for default parameter value
		-- here table name to retreive data from and data type of
		-- variable depends on parameter_area_id column
		IF	parameter_rec.parameter_area_id = c_mkt_parameter_range
		THEN

			IF	i_param IS NULL
			THEN

				OPEN	prm_value_cur
				FOR
				SELECT	prm_default
				FROM	mkt_parameter_range
				WHERE	parameter_id = parameter_rec.parameter_id
				AND	sccode = i_sccode;

					FETCH	prm_value_cur
					INTO	v_prm_value_string;
				
				CLOSE	prm_value_cur;
			ELSE
				v_prm_value_number := i_param;
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
				v_prm_value_id,	-- prm_value_id
				parameter_rec.prm_no,	-- prm_no
				1,	-- prm_seqno
				1,	-- parent_seqno
				1,	-- sibling_seqno
				1,	-- complex_seqno
				1,	-- value_seqno
				1,	-- complex_level
				parameter_rec.parameter_id,	-- parameter_id
				NULL,	-- deleted_flag
				NULL,	-- prm_value_date
				v_prm_value_string,	-- prm_value_string
				NULL,	-- prm_value_number
				i_param_des,	-- prm_description
				TRUNC( SYSDATE ),	-- prm_valid_from
				NULL,	-- request_id
				0	-- rec_version
				);

		ELSIF	parameter_rec.parameter_area_id = c_mkt_parameter_domain
		THEN
			
			IF	i_param IS NULL
			THEN

				OPEN	prm_value_cur
				FOR
				SELECT	prm_value_seqno
				FROM	mkt_parameter_domain
				WHERE	parameter_id = parameter_rec.parameter_id
				AND	sccode = i_sccode
				AND	prm_value_def = 'X';

					FETCH	prm_value_cur
					INTO	v_prm_value_number;
				
				CLOSE	prm_value_cur;
			ELSE
				v_prm_value_number := i_param;
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
				v_prm_value_id,	-- prm_value_id
				parameter_rec.prm_no,	-- prm_no
				1,	-- prm_seqno
				1,	-- parent_seqno
				1,	-- sibling_seqno
				1,	-- complex_seqno
				1,	-- value_seqno
				1,	-- complex_level
				parameter_rec.parameter_id,	-- parameter_id
				NULL,	-- deleted_flag
				TRUNC( SYSDATE ),	-- prm_value_date
				NULL,	-- prm_value_string
				v_prm_value_number,	-- prm_value_number
				i_param_des,	-- prm_description
				TRUNC( SYSDATE ),	-- prm_valid_from
				NULL,	-- request_id
				0	-- rec_version
				);
		ELSE
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
				v_prm_value_id,	-- prm_value_id
				parameter_rec.prm_no,	-- prm_no
				1,	-- prm_seqno
				1,	-- parent_seqno
				1,	-- sibling_seqno
				1,	-- complex_seqno
				1,	-- value_seqno
				1,	-- complex_level
				parameter_rec.parameter_id,	-- parameter_id
				NULL,	-- deleted_flag
				NULL,	-- prm_value_date
				NULL,	-- prm_value_string
				i_param,	-- prm_value_number
				i_param_des,	-- prm_description
				TRUNC( SYSDATE ),	-- prm_valid_from
				NULL,	-- request_id
				0	-- rec_version
				);
		END	IF;

	END	LOOP;

	CLOSE	parameter_cur;

	RETURN	v_prm_value_id;

EXCEPTION
	WHEN	OTHERS
	THEN
		RETURN	-1;
END	create_service_parameters;

FUNCTION	assign_service
	(
	i_co_id		IN NUMBER,
	i_spcode	IN NUMBER := NULL,
	i_sncode	IN NUMBER := NULL,
	i_dn_id		IN NUMBER := NULL,
	i_fup_id	IN NUMBER := NULL
	)
RETURN	NUMBER
IS

	-- Record with contract data
	TYPE	contract_rec_type
	IS	RECORD
		(
		tmcode		NUMBER,
		sccode		NUMBER,
		spcode		NUMBER,
		currency	NUMBER
		);
	
	TYPE	contract_cur_type
	IS	REF CURSOR
	RETURN	contract_rec_type;

	contract_rec	contract_rec_type;
	contract_cur	contract_cur_type;

	c_det_bill_sncode	CONSTANT NUMBER := 93;
	c_fup_sncode		CONSTANT NUMBER := 203;

	-- Cursor for all the sncodes for spcode
	-- except sncodes wich needs records in contr_services_cap
	CURSOR	sncode_cur IS
	SELECT	lk.sncode
	FROM	mpulkpxn	lk,
		mpusntab	sn
	WHERE	sn.sncode = lk.sncode
	AND	lk.spcode = i_spcode
	AND	lk.sncode NOT IN
		(
		c_gsm_sncode,
		c_fax_sncode,
		c_data_sncode,
		c_nmt_sncode
		)
	/*
	we can assign only network services and detailed bill services
	which is not network service
	*/
	AND	(
		sn.snind = 'Y'
		OR
		sn.sncode = c_det_bill_sncode
		)
	-- we cannot and must not assign services which are already assigned
	AND	NOT EXISTS
		(
		SELECT	*
		FROM	contr_services
		WHERE	co_id = i_co_id
		AND	sncode = lk.sncode
		);

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

	main_dirnum_rec		main_dirnum_cur%ROWTYPE;

	-- Cursor for retreiving service type
	CURSOR	srv_type_cur
		(
		i_sncode	NUMBER
		)
	IS
	SELECT	srv_type
	FROM	mpulknxv
	WHERE	sncode = i_sncode;

	-- Cursor for VAS on contract
	CURSOR	contr_vas_cur
		(
		p_co_id		NUMBER,
		p_sncode	NUMBER
		)
	IS
	SELECT	NVL( MAX( seqno ), 0 ) + 1
	FROM	contr_vas
	WHERE	co_id = p_co_id
	AND	sncode = p_sncode;

	-- Cursor for free units package
	CURSOR	fup_cur
		(
		p_fup_id	NUMBER
		)
	IS
	SELECT	long_name
	FROM	fu_pack
	WHERE	fu_pack_id = p_fup_id
	AND	assignment_level = 'C';	-- assignment level must be contract

	-- Array for sncodes in spcode
	sncodes			number_tab_type;

	i			BINARY_INTEGER := 1;

	v_sncode		NUMBER;	-- Service code in mpusntab
	v_seqno			NUMBER;
	v_seqno_pre		NUMBER;
	v_result		NUMBER;
	
	v_cs_seqno		contr_services.cs_seqno%TYPE;
	v_ch_status		contract_history.ch_status%TYPE;

	v_dn_status		VARCHAR2(1);
	v_srv_type		VARCHAR2(1);	-- Service type ( 'V' - VAS )
	v_long_name		VARCHAR2(30);	-- fu pack name
	v_srv_subtype		VARCHAR2(1);
	v_sn_class		NUMBER;

	service_is_telephony	BOOLEAN := FALSE;	-- Switch for services which need dn_id

	wrong_sncode		EXCEPTION;
	no_parameters_passed	EXCEPTION;
	fee_insertion_failure	EXCEPTION;
	empty_dn_id		EXCEPTION;
	prm_creation_failure	EXCEPTION;
	dn_not_found		EXCEPTION;
	wrong_dn_status		EXCEPTION;
	wrong_fup_id		EXCEPTION;
	has_pending_request	EXCEPTION;

	service		service_t := service_t( NULL, NULL, NULL, NULL );
	services	creator.contr_services_tab;
	v_contract	contract_t := contract_t( NULL, NULL, NULL, NULL, NULL, services );
	needed_parameters	parameters_tab := parameters_tab();

BEGIN

	v_contract.init( i_co_id );
	service.init( i_sncode );

	-- Check if contract doesn't have pending request
	IF	v_contract.has_pending_request = TRUE
	THEN
		RAISE	has_pending_request;
	END	IF;

	-- Checking parameters passes
	IF	i_spcode IS NULL
	THEN
		IF	i_sncode IS NULL
		THEN
			RAISE	no_parameters_passed;
		ELSE
			-- We have only one service to assign			
			sncodes(1) := i_sncode;

			-- Checking if service is telephony service
			IF	i_sncode IN
				(
				c_gsm_sncode,
				c_fax_sncode,
				c_data_sncode,
				c_nmt_sncode
				)
			THEN
				IF	i_dn_id IS NULL
				THEN
					RAISE	empty_dn_id;
				ELSE
					service_is_telephony := TRUE;

					-- Checking dn_id passed
					OPEN	dn_cur( i_dn_id );

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
			END	IF;

			-- Looking for contract data related to sncode
			OPEN	contract_cur
			FOR
			SELECT	ca.tmcode,
				ca.sccode,
				mp.spcode,
				ca.currency
			FROM	mpulktmb	mp,
				contract_all	ca
			WHERE	ca.tmcode = mp.tmcode
			AND	mp.sncode = i_sncode
			AND	ca.co_id = i_co_id
			AND	mp.vscode =
				(
				SELECT	MAX ( vscode )
				FROM	mputmtab
				WHERE	tmcode = mp.tmcode
				AND	status = 'P'
				AND	vsdate <= SYSDATE
				);
		END	IF;
	ELSE
		-- We have spcode and should assign service package
		OPEN	sncode_cur;

			FETCH	sncode_cur
			BULK	COLLECT
			INTO	sncodes;

		CLOSE	sncode_cur;

		-- Looking for contract data related to spcode
		OPEN	contract_cur
		FOR
		SELECT	DISTINCT ca.tmcode,
			ca.sccode,
			mp.spcode,
			ca.currency
		FROM	mpulktmb	mp,
			contract_all	ca
		WHERE	ca.tmcode = mp.tmcode
		AND	mp.spcode = i_spcode
		AND	ca.co_id = i_co_id
		AND	mp.vscode =
			(
			SELECT	MAX ( vscode )
			FROM	mputmtab
			WHERE	tmcode = mp.tmcode
			AND	status = 'P'
			AND	vsdate <= SYSDATE
			);
	END	IF;

	-- Retreiving contract data
	FETCH	contract_cur
	INTO	contract_rec;

	IF	contract_cur%NOTFOUND
	THEN
		CLOSE	contract_cur;
		RAISE	wrong_sncode;
	END	IF;

	CLOSE	contract_cur;

	-- Checking contract status
	v_ch_status := v_contract.status;

	IF	(
		v_ch_status NOT IN ( 'a', 'o' )
		OR
		v_ch_status IS NULL
		)
	THEN
		RAISE	not_active_contract;
	END	IF;

	-- Looking for a sequence number for services to insert
	SELECT	DECODE ( NVL( MAX( cs_seqno ), 0 ), 0, 1, MAX( cs_seqno ) )
	INTO	v_cs_seqno
	FROM	contr_services
	WHERE	co_id = i_co_id;

	-- Checking list of services
	IF	sncodes.COUNT != 0	-- List is not empty
	THEN
		i := 1;
		FOR	i IN sncodes.FIRST..sncodes.COUNT
		LOOP

			OPEN	srv_type_cur( sncodes(i) );
				
				FETCH	srv_type_cur
				INTO	v_srv_type;

			CLOSE	srv_type_cur;

			v_sn_class := sncodes(i);

			-- For free units we need srv_subtype to insert
			-- into contr_services and set sn_class to null
			IF	sncodes(i) = c_fup_sncode
			THEN
				v_srv_subtype := 'C';
				v_sn_class := NULL;
			ELSE
				v_srv_subtype := NULL;
				-- For detailed bill we also set sn_class
				-- to null
				IF	sncodes(i) = c_det_bill_sncode
				THEN
					v_sn_class := NULL;
				END	IF;
			END	IF;

			INSERT	INTO contr_services
				(
				co_id,
				tmcode,
				spcode,
				sncode,
				cs_seqno,
				cs_channel_num,
				cs_stat_chng,
				cs_on_cbb,
				cs_date_billed,
				cs_request,
				sn_class,
				rec_version,
				cs_ovw_subscr,
				cs_subscript,
				cs_ovw_access,
				cs_ovw_acc_prd,
				cs_access,
				cs_pending_state,
				cs_channel_excl,
				cs_ovw_acc_first,
				cs_dis_subscr,
				cs_moddate,
				cs_adv_charge,
				cs_ovw_last,
				cs_srv_type,
				subpayer,
				usgpayer,
				accpayer,
				cs_entdate,
				install_date,
				trial_end_date,
				currency,
				cs_adv_charge_currency,
				cs_adv_charge_end_date,
				prm_value_id,
				srv_subtype
				)
			VALUES	(
				i_co_id,	-- co_id
				contract_rec.tmcode,	-- tmcode
				contract_rec.spcode,	-- spcode
				sncodes(i),	-- sncode
				v_cs_seqno,	-- cs_seqno
				NULL,		-- cs_channel_num
				NULL,		-- cs_stat_chng
				NULL,		-- cs_on_cbb
				NULL,		-- cs_date_billed
				NULL,		-- cs_request
				v_sn_class,	-- sn_class
				0,		-- rec_version
				NULL,		-- cs_ovw_subscr
				0,		-- cs_subscript
				NULL,		-- cs_ovw_access
				NULL,		-- cs_ovw_acc_prd
				NULL,		-- cs_access
				NULL,		-- cs_pending_state
				NULL,		-- cs_channel_excl
				NULL,		-- cs_ovw_acc_first
				0,		-- cs_dis_subscr
				NULL,		-- cs_moddate
				NULL,		-- cs_adv_charge
				NULL,		-- cs_ovw_last
				v_srv_type,	-- cs_srv_type
				NULL,		-- subpayer
				NULL,		-- usgpayer
				NULL,		-- accpayer
				SYSDATE,	-- cs_entdate
				NULL,		-- install_date
				NULL,		-- trial_end_date
				contract_rec.currency,	-- currency
				NULL,		-- cs_adv_charge_currency
				NULL,		-- cs_adv_charge_end_date
				NULL,		-- prm_value_id
				v_srv_subtype	-- srv_subtype
				);

			IF	v_srv_type = 'V'	-- non-event VAS
			THEN
				OPEN	contr_vas_cur
					(
					i_co_id,
					sncodes(i)
					);

					FETCH	contr_vas_cur
					INTO	v_seqno;
				
				CLOSE	contr_vas_cur;

				INSERT	INTO contr_vas
					(
					co_id,
					seqno,
					sncode,
					quantity,
					validfrom,
					cbb_date,
					rec_version
					)
				VALUES	(
					i_co_id,
					v_seqno,
					sncodes(i),
					1,
					TRUNC( SYSDATE ),
					NULL,
					0
					);
			END	IF;
			
			-- Checking if service needs parameters
			needed_parameters := service.needed_parameters;

			IF	needed_parameters.COUNT > 0	-- parameters needed
			THEN
				FOR	i IN needed_parameters.FIRST..needed_parameters.COUNT
				LOOP
					IF	sncodes(i) = c_fup_sncode
					THEN
						OPEN	fup_cur( i_fup_id );

							FETCH	fup_cur
							INTO	v_long_name;

							IF	fup_cur%NOTFOUND
							THEN
								CLOSE	fup_cur;
								RAISE	wrong_fup_id;
							END	IF;

						CLOSE	fup_cur;

						v_result := create_service_parameters
							(
							contract_rec.sccode,
							needed_parameters(i),
							i_fup_id,
							v_long_name
							);

					ELSE

						v_result := create_service_parameters
							(
							contract_rec.sccode,
							needed_parameters(i)
							);
					END	IF;
						
					IF	v_result < 0	-- failure
					THEN
						RAISE	prm_creation_failure;
					ELSE	-- success
						UPDATE	contr_services
						SET	prm_value_id = v_result
						WHERE	co_id = i_co_id
						AND	sncode = sncodes(i)
						AND	cs_seqno = v_cs_seqno;
					END	IF;
				END	LOOP;
			END	IF;

			
			-- Checking if service is telephony service
			-- and needs dn_id to insert in contr_services_cap
			IF	service_is_telephony = TRUE
			THEN

				OPEN	contr_services_cur
					(
					i_co_id,
					sncodes(i)
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

					OPEN	main_dirnum_cur( i_co_id );
						
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
					i_co_id,
					sncodes(i),
					v_seqno,
					v_seqno_pre,
					NULL,
					NULL,
					i_dn_id,
					DECODE( sncodes(i), 12, main_dirnum_rec.main_dirnum, NULL ),
					DECODE( v_seqno, 1, 'O', 'R' ),
					NULL,
					NULL,
					NULL,
					DECODE( v_seqno, 1, 0, v_seqno + 1 ),
					NULL
					);
				
				UPDATE	directory_number
				SET	dn_status = 'a'
				WHERE	dn_id = i_dn_id;

			END	IF;

			-- Checking if service is detailed bill
			IF	sncodes(i) = c_det_bill_sncode
			THEN
				UPDATE	contract_all
				SET	co_itemized_bill = 'X'
				WHERE	co_id = i_co_id;

				v_result := common.umc_util.insert_fee
					(
					i_co_id,
					sncodes(i)
					);
				
				-- Checking result
				IF	v_result != 0	-- failure
				THEN
					RAISE	fee_insertion_failure;
				END	IF;
			END	IF;

		END	LOOP;

	END	IF;

	RETURN	0;

EXCEPTION
	WHEN	DUP_VAL_ON_INDEX	-- such a service exists for the contract
	THEN
		RETURN	-1;
	WHEN	wrong_sncode
	THEN
		RETURN	-2;
	WHEN	not_active_contract
	THEN
		RETURN	-3;
	WHEN	no_parameters_passed
	THEN
		RETURN	-4;
	WHEN	fee_insertion_failure
	THEN
		RETURN	v_result;
	WHEN	empty_dn_id
	THEN
		RETURN	-6;
	WHEN	prm_creation_failure
	THEN
		RETURN	-7;
	WHEN	dn_not_found
	THEN
		RETURN	-8;
	WHEN	wrong_dn_status
	THEN
		RETURN	-9;
	WHEN	wrong_fup_id
	THEN
		RETURN	-10;
	WHEN	has_pending_request
	THEN
		RETURN	-17;
	WHEN	OTHERS
	THEN
		RETURN	SQLCODE;
END	assign_service;

-- All the real functionality moved to contract_t object
FUNCTION	create_contract
	(
	i_customer_id	IN customer_all.customer_id%TYPE,
	i_tmcode	IN mputmtab.tmcode%TYPE,
	i_sm_serialnum	IN storage_medium.sm_serialnum%TYPE,
	i_dn_num	IN directory_number.dn_num%TYPE
	)
RETURN	NUMBER
IS
	v_contract	creator.contract_t;
	v_service	creator.service_t := creator.service_t
						(
						NULL,
						NULL,
						NULL,
						NULL
						);
	v_contr_service	creator.contr_service_t := creator.contr_service_t
						(
						NULL,
						NULL,
						NULL,
						NULL,
						NULL,
						NULL,
						NULL
						);

	v_dn_parameter	creator.dn_parameter_t := creator.dn_parameter_t
						(
						NULL,
						NULL,
						NULL,
						NULL
						);
						
	-- Cursor for main (core) services
	CURSOR	sncode_cur
		(
		p_tmcode	NUMBER,
		p_vscode	NUMBER
		)
	IS
	SELECT	sncode
	FROM	mpulktmb
	WHERE	tmcode = p_tmcode
	AND	vscode = p_vscode
	AND	csind = 'X';

	-- Cursor tmcode_cur for checking if tmcode passed
	-- can be assigned to customer passed
	CURSOR	tmcode_cur
		(
		p_customer_id	NUMBER,
		p_tmcode	NUMBER
		)
	IS
	SELECT	mp.tmcode
	FROM	customer_all	ca,
		mpulknxg	mp
	WHERE	ca.prgcode = mp.prgcode
	AND	ca.customer_id = p_customer_id
	AND	mp.typeind = 'G'
	AND	mp.tmcode = p_tmcode;

	sncodes		number_tab_type;
	v_result	NUMBER;
	v_vscode	NUMBER;

BEGIN

	v_contract := creator.contract_t
			(
			NULL,
			i_customer_id,
			i_tmcode,
			i_dn_num,
			i_sm_serialnum,
			NULL
			);

	v_contract.create_me;

	v_contract.init( v_contract.co_id );

	SELECT	vscode
	INTO	v_vscode
	FROM	common.valid_tmcodes
	WHERE	tmcode = v_contract.tmcode;

	OPEN	sncode_cur
		(
		v_contract.tmcode,
		v_vscode
		);

		FETCH	sncode_cur
		BULK	COLLECT
		INTO	sncodes;

		-- Creating contracted services
		FOR	i IN sncodes.FIRST..sncodes.COUNT
		LOOP
			v_service.init( sncodes(i) );
			v_contract.assign_service(v_service);

			IF	v_service.is_bearer_service = TRUE
			THEN
				v_contr_service.init
					(
					v_contract.co_id,
					v_service.sncode
					);
				v_dn_parameter.init( i_dn_num );
				v_contr_service.set_dn_parameter( v_dn_parameter );
			END	IF;
		END	LOOP;

	CLOSE	sncode_cur;

	RETURN	v_contract.co_id;

EXCEPTION
	WHEN	OTHERS
	THEN
		RETURN	SQLCODE;
END	create_contract;

/*
All the functionality moved to creator.contract_t object
*/
FUNCTION	register_service	
	(
	i_co_id		IN NUMBER,
	i_sncode	IN NUMBER
	)
RETURN	NUMBER
IS
	v_contract	creator.contract_t := creator.contract_t
						(
						NULL,
						NULL,
						NULL,
						NULL,
						NULL,
						NULL
						);
	v_request	NUMBER;
BEGIN

	v_contract.init( i_co_id );
	v_contract.register_service( i_sncode, v_request );

	RETURN	v_request;

END	register_service;
/*
All the functionality moved to creator.contract_t object
*/
FUNCTION	erase_service
	(
	i_co_id		IN NUMBER,
	i_sncode	IN NUMBER
	)
RETURN	NUMBER
IS
	v_contract	creator.contract_t := creator.contract_t
						(
						NULL,
						NULL,
						NULL,
						NULL,
						NULL,
						NULL
						);
	v_request	NUMBER;
BEGIN

	v_contract.init( i_co_id );
	v_contract.erase_service( i_sncode, v_request );

	RETURN	v_request;

END	erase_service;

PROCEDURE	view_not_core_services
	(
	i_tmcode	IN NUMBER,
	o_sncode_cur	IN OUT sncode_cur_type
	)
IS
BEGIN

	OPEN	o_sncode_cur
	FOR
	SELECT	sn.sncode,
		sn.des
	FROM	mpulktmb	lk,
		mpusntab	sn
	WHERE	lk.sncode = sn.sncode
	AND	lk.tmcode = i_tmcode
	AND	lk.vscode = 
		(
		SELECT	vscode
		FROM	common.valid_tmcodes
		WHERE	tmcode = i_tmcode
		)
	AND	(
		lk.csind != 'X'
		OR
		lk.csind IS NULL
		)
	ORDER	BY sn.des;

END	view_not_core_services;

PROCEDURE	init_service
	(
	i_sncode	IN NUMBER,
	i_sccode	IN NUMBER DEFAULT 1,
	o_des		OUT VARCHAR,
	o_net_service	OUT VARCHAR,
	o_service_type	OUT VARCHAR
	)
IS
	v_service	creator.service_t := creator.service_t
						(
						NULL,
						NULL,
						NULL,
						NULL
						);
BEGIN
	v_service.init( i_sncode, i_sccode );

	o_des := v_service.des;
	o_net_service := v_service.is_net_service;
	o_service_type := v_service.service_type;

END	init_service;

END	umc_contract;
/

SHOW ERRORS