CREATE	OR REPLACE
TYPE	BODY &owner..contract_t
AS

-- Map function for object comparing
MAP	MEMBER FUNCTION get_co_id
RETURN	NUMBER
AS
BEGIN
	RETURN	SELF.co_id;
END	get_co_id;

MEMBER	PROCEDURE create_me
AS

	v_co_id		NUMBER;
	v_vscode	mputmtab.vscode%TYPE;
	v_vsdate	mputmtab.vsdate%TYPE;
	v_sccode	mpdsctab.sccode%TYPE;
	v_plcode	mpdpltab.plcode%TYPE;
	v_subm_id	sub_market.subm_id%TYPE;
	v_tmcode	mputmtab.tmcode%TYPE;
	v_dealer_id	customer_all.customer_id%TYPE;
	v_result	NUMBER;
	v_currency	customer_all.currency%TYPE;
	v_convratetype	customer_all.prim_convratetype_doc%TYPE;

	-- Cursor for main (core) services
	CURSOR	sncode_cur ( p_tmcode NUMBER )
	IS
	SELECT	sncode
	FROM	mpulktmb
	WHERE	tmcode = p_tmcode
	AND	vscode = v_vscode
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

	-- Cursor for port data
	CURSOR	port_cur
		(
		p_dealer_id	NUMBER,
		p_sm_serialnum	storage_medium.sm_serialnum%TYPE,
		p_plcode	NUMBER
		)
	IS
	SELECT	pt.port_id,
		pt.sm_id,
		pt.port_status,
		pt.port_activ_date,
		pt.port_moddate,
		pt.port_statusmoddat,
		pt.port_userlastmod,
		pt.rec_version
	FROM	port		pt,
		storage_medium	sm
	WHERE	sm.sm_id = pt.sm_id
	AND	sm.sm_serialnum = p_sm_serialnum
	AND	pt.dealer_id = p_dealer_id
	AND	pt.plcode = p_plcode
	AND	pt.port_status = 'r'
	FOR	UPDATE;

	port_rec	port_cur%ROWTYPE;

	-- SIM data
	CURSOR	sm_cur
		(
		p_sm_serialnum	storage_medium.sm_serialnum%TYPE,
		p_plcode	NUMBER
		)
	IS
	SELECT	dealer_id,
		sm_status,
		sm_moddate,
		sm_status_mod_date,
		sm_userlastmod,
		rec_version
	FROM	storage_medium
	WHERE	sm_serialnum = p_sm_serialnum
	AND	plcode = p_plcode
	AND	sm_status = 'r'
	FOR	UPDATE;
	
	sm_rec	sm_cur%ROWTYPE;

	-- Phone data
	CURSOR	dn_cur
		(
		p_dealer_id	NUMBER,
		p_dn_num	directory_number.dn_num%TYPE,
		p_plcode	NUMBER
		)
	IS
	SELECT	dn_id
	FROM	directory_number
	WHERE	dn_num = p_dn_num
	AND	dealer_id = p_dealer_id
	AND	plcode = p_plcode
	AND	dn_status = 'r'
	FOR	UPDATE;

	v_dn_id		directory_number.dn_id%TYPE;

	-- HLR data
	CURSOR	hlr_cur
		(
		p_dn_num	directory_number.dn_num%TYPE
		)
	IS
	SELECT	hlcode
	FROM	mpdhmtab
	WHERE	snhlrid = SUBSTR( p_dn_num, 3, 2 )
	AND	msisdnlb <= SUBSTR( p_dn_num, 5, 5 )
	AND	msisdnrb >= SUBSTR( p_dn_num, 5, 5 );

	v_hlcode		mpdhmtab.hlcode%TYPE;

	sncodes			creator.global_vars.number_tab_type;
	c_sysdate		CONSTANT DATE := TRUNC( SYSDATE );

	v_parameter		parameter_t := parameter_t( 'MAX_CONTRACT_ID' );
	v_service		creator.service_t := creator.service_t
							(
							NULL,
							NULL,
							NULL,
							NULL
							);

	improper_tmcode		EXCEPTION;
	wrong_sim		EXCEPTION;
	wrong_dn_num		EXCEPTION;
	wrong_hlr		EXCEPTION;
	assign_service_error	EXCEPTION;

BEGIN
	
	-- Checking tariff model
	SELECT	vscode,
		vsdate
	INTO	v_vscode,
		v_vsdate
	FROM	common.valid_tmcodes
	WHERE	tmcode = SELF.tmcode;

	-- Checking if the tariff model can be assigned to the customer
	OPEN	tmcode_cur
		(
		SELF.customer_id,
		SELF.tmcode
		);

		FETCH	tmcode_cur
		INTO	v_tmcode;

		IF	tmcode_cur%NOTFOUND
		THEN
			-- Tariff model cannot be assigned to customer
			RAISE	improper_tmcode;
		ELSE
			-- Looking for plcode, sccode and submarket_id
			SELECT	lk.plcode,
				sc.sccode,
				sm.subm_id
			INTO	v_plcode,
				v_sccode,
				v_subm_id
			FROM	mpulknxg	lk,
				mpdsctab	sc,
				sub_market	sm,
				mpdpltab	pl
			WHERE	sc.sccode = sm.sccode
			AND	sc.sccode = pl.sccode
			AND	pl.plcode = lk.plcode
			AND	lk.tmcode = SELF.tmcode
			AND	lk.plcode IS NOT NULL
			AND	pl.plmntype = 'H';
		END	IF;
	
	CLOSE	tmcode_cur;

	SELECT	currency,
		prim_convratetype_doc
	INTO	v_currency,
		v_convratetype
	FROM	customer_all
	WHERE	customer_id = SELF.customer_id;

	-- Looking for new contract number
	v_co_id := v_parameter.next_value;

	INSERT	INTO contract_all
		(
		co_id,
		customer_id,
		type,
		ohxact,
		plcode,
		sccode,
		subm_id,
		co_signed,
		co_equ_type,
		co_rep_bill,
		co_rep,
		co_rep_bill_idno,
		co_rep_idno,
		co_installed,
		co_itemized_bill,
		co_ib_categories,
		co_ib_threshold,
		co_archive,
		co_dir_entry,
		co_operator_dir,
		co_pstn_dir,
		co_calls_anonym,
		co_ass_serv,
		co_ass_equ,
		co_ass_cbb,
		co_crd_check,
		co_crd_chk_end,
		co_crd_chk_start,
		co_crd_clicks,
		co_crd_clicks_day,
		co_crd_days,
		co_comment,
		co_duration,
		co_reserved,
		co_expir_date,
		co_activated,
		co_entdate,
		co_moddate,
		co_userlastmod,
		rec_version,
		co_tollrating,
		tmcode,
		tmcode_date,
		co_crd_d_tr1,
		co_crd_d_tr2,
		co_crd_d_tr3,
		co_crd_p_tr1,
		co_crd_p_tr2,
		co_crd_p_tr3,
		co_request,
		co_ext_csuin,
		eccode_ldc,
		pending_eccode_ldc,
		eccode_lec,
		pending_eccode_lec,
		dealer_id,
		svp_contract,
		not_valid,
		arpcode,
		co_crd_amount,
		co_crd_amount_day,
		contr_curr_id,
		convratetype_contract,
		co_addr_on_ibill,
		product_history_date,
		co_confirm,
		co_timm_modified,
		trial_end_date,
		co_ib_cdr_flag,
		currency,
		sec_contr_curr_id,
		sec_convratetype_contract
		)
	VALUES (
		v_co_id,		-- co_id
		SELF.customer_id,	-- customer_id
		'S',			-- type
		NULL,			-- ohxact
		v_plcode,		-- plcode
		v_sccode,		-- sccode
		v_subm_id,		-- subm_id
		c_sysdate,		-- co_signed
		NULL,			-- co_equ_type
		NULL,			-- co_rep_bill
		NULL,			-- co_rep
		NULL,			-- co_rep_bill_idno
		NULL,			-- co_rep_idno
		c_sysdate,		-- co_installed
		NULL,			-- co_itemized_bill
		NULL,			-- co_ib_categories
		0,			-- co_ib_threshold
		'X',			-- co_archive
		'C',			-- co_dir_entry
		NULL,			-- co_operator_dir
		NULL,			-- co_pstn_dir
		NULL,			-- co_calls_anonym
		NULL,			-- co_ass_serv
		NULL,			-- co_ass_equ
		NULL,			-- co_ass_cbb
		NULL,			-- co_crd_check
		NULL,			-- co_crd_chk_end
		NULL,			-- co_crd_chk_start
		NULL,			-- co_crd_clicks
		NULL,			-- co_crd_clicks_day
		NULL,			-- co_crd_days
		NULL,			-- co_comment
		NULL,			-- co_duration
		NULL,			-- co_reserved
		NULL,			-- co_expir_date
		NULL,			-- co_activated
		SYSDATE,		-- co_entdate
		SYSDATE,		-- co_moddate
		USER,			-- co_userlastmod
		0,			-- rec_version
		NULL,			-- co_tollrating
		SELF.tmcode,		-- tmcode
		v_vsdate,		-- tmcode_date
		NULL,			-- co_crd_d_tr1
		NULL,			-- co_crd_d_tr2
		NULL,			-- co_crd_d_tr3
		NULL,			-- co_crd_p_tr1
		NULL,			-- co_crd_p_tr2
		NULL,			-- co_crd_p_tr3
		NULL,			-- co_request
		NULL,			-- co_ext_csuin
		NULL,			-- eccode_ldc
		NULL,			-- pending_eccode_ldc
		NULL,			-- eccode_lec
		NULL,			-- pending_eccode_lec
		NULL,			-- dealer_id
		NULL,			-- svp_contract
		NULL,			-- not_valid
		NULL,			-- arpcode
		NULL,			-- co_crd_amount
		NULL,			-- co_crd_amount_day
		v_currency,		-- contr_curr_id
		v_convratetype,		-- convratetype_contract
		NULL,			-- co_addr_on_ibill
		NULL,			-- product_history_date
		NULL,			-- co_confirm
		NULL,			-- co_timm_modified
		NULL,			-- trial_end_date
		NULL,			-- co_ib_cdr_flag
		v_currency,		-- currency
		NULL,			-- sec_contr_curr_id
		NULL			-- sec_convratetype_contract
		);

	INSERT	INTO contract_history
		(
		co_id,
		ch_seqno,
		ch_status,
		ch_reason,
		ch_validfrom,
		entdate,
		userlastmod,
		request,
		rec_version,
		ch_pending
		)
	VALUES	(
		v_co_id,
		1,
		'o',
		creator.global_vars.c_onhold_rs_id,
		c_sysdate,
		SYSDATE,
		USER,
		NULL,
		0,
		NULL
		);

	INSERT	INTO contr_tariff_options
		(
		co_id,
		seqno,
		global_iot_ind,
		valid_from,
		rec_version
		)
	VALUES	(
		v_co_id,
		1,
		'N',
		c_sysdate,
		0
		);
	
	-- Looking for HLR
	OPEN	hlr_cur ( SELF.phone_num );

		FETCH	hlr_cur
		INTO	v_hlcode;

		IF	hlr_cur%NOTFOUND
		THEN
			RAISE	wrong_hlr;
		END	IF;

	CLOSE	hlr_cur;

	-- Looking for SIM data
	OPEN	sm_cur
		(
		SELF.sim_card,
		v_plcode
		);

		FETCH	sm_cur
		INTO	sm_rec;

		IF	sm_cur%NOTFOUND
		THEN
			RAISE	wrong_sim;
		END	IF;

		-- Making sim active
		UPDATE	storage_medium
		SET	sm_status = 'a',
			sm_moddate = c_sysdate,
			sm_status_mod_date = SYSDATE,
			sm_userlastmod = USER,
			rec_version = rec_version + 1
		WHERE	CURRENT OF sm_cur;

	CLOSE	sm_cur;

	-- Creating a record for the contract in contr_devices
	OPEN	port_cur
		(
		sm_rec.dealer_id,
		SELF.sim_card,
		v_plcode
		);
	
		FETCH	port_cur
		INTO	port_rec;

		INSERT	INTO contr_devices
			(
			cd_id,
			cd_seqno,
			co_id,
			port_id,
			dn_id,
			eq_id,
			cd_status,
			cd_activ_date,
			cd_deactiv_date,
			cd_validfrom,
			cd_entdate,
			cd_moddate,
			cd_userlastmod,
			cd_sm_num,
			cd_channels,
			cd_channels_excl,
			cd_eq_num,
			cd_rs_id,
			rec_version,
			cd_pending_state,
			cd_plcode,
			hlcode
			)
		VALUES	(
			1,			-- cd_id
			1,			-- cd_seqno
			v_co_id,		-- co_id
			port_rec.port_id,	-- port_id
			NULL,			-- dn_id
			NULL,			-- eq_id
			'O',			-- cd_status
			NULL,			-- cd_activ_date
			NULL,			-- cd_deactiv_date
			SYSDATE,		-- cd_validfrom
			c_sysdate,		-- cd_entdate
			NULL,			-- cd_moddate
			USER,			-- cd_userlastmod
			SELF.sim_card,		-- cd_sm_num
			NULL,			-- cd_channels
			NULL,			-- cd_channels_excl
			NULL,			-- cd_eq_num
			NULL,			-- cd_rs_id
			0,			-- rec_version
			NULL,			-- cd_pending_state
			v_plcode,		-- cd_plcode
			v_hlcode		-- hlcode
			);
		
		-- Making port active
		UPDATE	port
		SET	port_status = 'a',
			port_activ_date = c_sysdate,
			port_moddate = c_sysdate,
			port_statusmoddat = c_sysdate,
			port_userlastmod = USER,
			rec_version = rec_version + 1
		WHERE	CURRENT OF port_cur;

	CLOSE	port_cur;

	-- Fraud detection
	INSERT	INTO mpufdtab
		(
		co_id,
		rec_version
		)
	VALUES	(
		v_co_id,
		0
		);

	-- Checking if there is reserved numbers for dealer
	OPEN	dn_cur
		(
		sm_rec.dealer_id,
		SELF.phone_num,
		v_plcode
		);

		FETCH	dn_cur
		INTO	v_dn_id;

		IF	dn_cur%NOTFOUND
		THEN
			RAISE	wrong_dn_num;
		END	IF;

	CLOSE	dn_cur;
/*
	-- Looking for core services for the contract
	OPEN	sncode_cur ( SELF.tmcode );

		FETCH	sncode_cur
		BULK	COLLECT
		INTO	sncodes;

		-- Creating contracted services
		FOR	i IN sncodes.FIRST..sncodes.COUNT
		LOOP
			v_service.init( sncodes(i) );
			assign_service( v_service );
		END	LOOP;

	CLOSE	sncode_cur;
*/
	SELF.co_id := v_co_id;

EXCEPTION
	WHEN	wrong_sim
	THEN	
		SELF.co_id := -5;
	WHEN	wrong_dn_num
	THEN
		SELF.co_id := -6;
	WHEN	assign_service_error
	THEN
		SELF.co_id := v_result;
	WHEN	wrong_hlr
	THEN
		SELF.co_id := -8;
	WHEN	improper_tmcode
	THEN
		SELF.co_id := -9;
	WHEN	OTHERS
	THEN
		SELF.co_id := SQLCODE;
END	create_me;

MEMBER	PROCEDURE init
	(
	i_co_id	NUMBER
	)
AS

	-- Cursor to check if contract exists
	CURSOR	contract_cur ( p_co_id NUMBER )
	IS
	SELECT	co_id,
		customer_id,
		tmcode
	FROM	contract_all
	WHERE	co_id = p_co_id;

	-- Cursor for all contract services
	CURSOR	contr_services_cur ( p_co_id NUMBER )
	IS
	SELECT	sncode,
		cs_seqno,
		SUBSTR( cs_stat_chng, -1, 1 ) AS status,
		cs_pending_state,
		cs_request,
		prm_value_id
	FROM	contr_services
	WHERE	co_id = p_co_id
	AND	cs_seqno =
		(
		SELECT	MAX( cs_seqno )
		FROM	contr_services
		WHERE	co_id = p_co_id
		);

	-- Cursor for SIM-card search
	CURSOR	sim_card_cur ( p_co_id NUMBER )
	IS
	SELECT	cd_sm_num
	FROM	contr_devices
	WHERE	co_id = p_co_id
	AND	cd_seqno =
		(
		SELECT	MAX( cd_seqno )
		FROM	contr_devices
		WHERE	co_id = p_co_id
		);

	-- Cursor for phone number search
	CURSOR	phone_num_cur ( p_co_id NUMBER )
	IS
	SELECT	dn.dn_num
	FROM	directory_number	dn,
		contr_services_cap	cs
	WHERE	dn.dn_id = cs.dn_id
	AND	cs.co_id = p_co_id
	AND	cs.sncode IN
		(
		creator.global_vars.c_nmt_sncode,
		creator.global_vars.c_gsm_sncode
		)
	AND	cs.seqno =
		(
		SELECT	MAX( seqno )
		FROM	contr_services_cap
		WHERE	co_id = p_co_id
		AND	cs.sncode IN ( 12, 140 )
		);

	contr_services_rec	contr_services_cur%ROWTYPE;

	i			PLS_INTEGER := 1;

	curr_service		creator.service_t := creator.service_t( NULL, NULL, NULL, NULL );
	contr_service		creator.contr_service_t;

	non_existing_contract	EXCEPTION;

BEGIN

	-- Checking if contract really exists
	OPEN	contract_cur ( i_co_id );

		FETCH	contract_cur
		INTO	SELF.co_id,
			SELF.customer_id,
			SELF.tmcode;

		IF	contract_cur%NOTFOUND
		THEN
			CLOSE	contract_cur;
			RAISE	non_existing_contract;
		END	IF;

	CLOSE	contract_cur;

	-- Looking for SIM-card
	OPEN	sim_card_cur ( i_co_id );

		FETCH	sim_card_cur
		INTO	SELF.sim_card;

	CLOSE	sim_card_cur;

	-- Looking for phone_num
	OPEN	phone_num_cur ( i_co_id );

		FETCH	phone_num_cur
		INTO	SELF.phone_num;

	CLOSE	phone_num_cur;
		
	-- Initializing table with contract services
	SELF.services := creator.contr_services_tab
		(
		contr_service_t( NULL, NULL, NULL, NULL, NULL, NULL, NULL)
		);

	-- Populating table with contract services
	OPEN	contr_services_cur( i_co_id );

	LOOP

		FETCH	contr_services_cur
		INTO	contr_services_rec;
		EXIT	WHEN contr_services_cur%NOTFOUND;

		-- Creating an instance of service
		curr_service.init( contr_services_rec.sncode );

		-- This can be replaced with contr_service_t constructor
		contr_service := creator.contr_service_t
					(
					SELF.co_id,
					contr_services_rec.cs_seqno,
					contr_services_rec.status,
					contr_services_rec.cs_pending_state,
					contr_services_rec.cs_request,
					contr_services_rec.prm_value_id,
					curr_service
					);

		SELF.services.EXTEND;
		SELF.services(i) := contr_service;
		i := i + 1;

	END	LOOP;
	CLOSE	contr_services_cur;
	
	-- Trimming last empty cell from the table
	services.TRIM;

EXCEPTION
	WHEN	non_existing_contract
	THEN
		RAISE_APPLICATION_ERROR ( -20001, 'No such contract' );
		--SELF.co_id := -1;
	WHEN	OTHERS
	THEN
		RAISE;
		--SELF.co_id := SQLCODE;
END	init;

MEMBER	PROCEDURE init
	(
	i_dn_num	IN VARCHAR2
	)
AS
	
	-- Cursor for contract search by phone number
	CURSOR	phone_cur ( p_dn_num VARCHAR2 )
	IS
	SELECT	ca.co_id
	FROM	contract_all		ca,
		contr_services_cap	cs,
		directory_number	dn
	WHERE	dn.dn_id = cs.dn_id
	AND	cs.co_id = ca.co_id
	AND	dn.dn_num = p_dn_num
	AND	cs.sncode IN
		(
		creator.global_vars.c_nmt_sncode,
		creator.global_vars.c_gsm_sncode
		)
	AND	cs_deactiv_date IS NULL;

	v_co_id		PLS_INTEGER := 0;

BEGIN

	-- Looking for contract 
	OPEN	phone_cur( i_dn_num );
	
		FETCH	phone_cur
		INTO	v_co_id;

	CLOSE	phone_cur;

	-- Calling main constructor
	-- If contract is not found in cursor, then co_id passed
	-- to constructor equals to 0 and exception NON_EXISTING_CONTRACT
	-- will be raised

	init( v_co_id );

END	init;

-- Function for service assigning
MEMBER	PROCEDURE assign_service
	(
	i_sncode	IN NUMBER
	)
AS
	v_service	creator.service_t := creator.service_t
						(
						NULL,
						NULL,
						NULL,
						NULL
						);
BEGIN

	v_service.init( i_sncode );

	assign_service( v_service );

END	assign_service;

MEMBER	PROCEDURE assign_service
	(
	i_service	IN creator.service_t
	)
AS

	-- Cursor for contract data
	CURSOR	contract_cur
		(
		p_co_id		NUMBER,
		p_sncode	NUMBER
		)
	IS
	SELECT	ca.tmcode,
		ca.sccode,
		mp.spcode,
		ca.currency
	FROM	mpulktmb	mp,
		contract_all	ca
	WHERE	ca.tmcode = mp.tmcode
	AND	mp.sncode = p_sncode
	AND	ca.co_id = p_co_id
	AND	mp.vscode =
		(
		SELECT	MAX ( vscode )
		FROM	mputmtab
		WHERE	tmcode = mp.tmcode
		AND	status = 'P'
		AND	vsdate <= SYSDATE
		);

	contract_rec	contract_cur%ROWTYPE;

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

	i			BINARY_INTEGER := 1;
	v_seqno			NUMBER;
	v_sn_class		NUMBER;
	v_result		NUMBER;
	v_cs_seqno		contr_services.cs_seqno%TYPE;
	v_srv_subtype		VARCHAR2(1);

	v_contr_service		creator.contr_service_t := creator.contr_service_t
								(
								NULL,
								NULL,
								NULL,
								NULL,
								NULL,
								NULL,
								NULL
								);
	v_needed_parameters	creator.parameters_tab;
	v_mkt_parameters	creator.mkt_parameters_tab;

	not_active_contract	EXCEPTION;
	wrong_sncode		EXCEPTION;
	fee_insertion_failure	EXCEPTION;
	has_pending_request	EXCEPTION;

BEGIN

	-- Looking for contract data related to sncode
	OPEN	contract_cur
		(
		SELF.co_id,
		i_service.sncode
		);

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
	IF	(
		SELF.status NOT IN ( 'a', 'o' )
		OR
		SELF.status IS NULL
		)
	THEN
		RAISE	not_active_contract;
	END	IF;

	-- Checking if contract have global request pending
	IF	SELF.has_pending_request = TRUE
	THEN
		RAISE	has_pending_request;
	END	IF;

	-- Looking for a sequence number for services to insert
	SELECT	DECODE ( NVL( MAX( cs_seqno ), 0 ), 0, 1, MAX( cs_seqno ) )
	INTO	v_cs_seqno
	FROM	contr_services
	WHERE	co_id = SELF.co_id;

	v_sn_class := i_service.sncode;

	-- For free units we need srv_subtype to insert into contr_services
	-- and set sn_class to null
	IF	i_service.is_fup_service = TRUE
	THEN
		v_srv_subtype := 'C';
		v_sn_class := NULL;
	ELSE
		v_srv_subtype := NULL;
		-- For detailed bill we also set sn_class to null
		IF	i_service.sncode = creator.global_vars.c_det_bill_sncode
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
		SELF.co_id,	-- co_id
		SELF.tmcode,	-- tmcode
		contract_rec.spcode,	-- spcode
		i_service.sncode,	-- sncode
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
		i_service.service_type,	-- cs_srv_type
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

	-- Checking service type. For non-event VAS we need to insert record
	-- into contr_vas table
	IF	i_service.service_type = 'V'
	THEN

		OPEN	contr_vas_cur
			(
			SELF.co_id,
			i_service.sncode
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
			SELF.co_id,
			v_seqno,
			i_service.sncode,
			1,
			TRUNC( SYSDATE ),
			NULL,
			0
			);
	END	IF;

/*
	-- Checking if service needs parameters
	v_needed_parameters := i_service.needed_parameters;

	IF	v_needed_parameters.COUNT > 0
	THEN
		v_mkt_parameters := i_service.mkt_parameters;
		v_contr_service.init( SELF.co_id, i_service.sncode);
		v_contr_service.set_mkt_parameter( v_mkt_parameters );
	END	IF;
*/	
	-- Checking if service is detailed bill
	IF	i_service.sncode = creator.global_vars.c_det_bill_sncode
	THEN

		UPDATE	contract_all
		SET	co_itemized_bill = 'X'
		WHERE	co_id = SELF.co_id;

		v_result := common.umc_util.insert_fee
			(
			SELF.co_id,
			i_service.sncode
			);
		
		-- Checking result
		IF	v_result != 0	-- failure
		THEN
			RAISE	fee_insertion_failure;
		END	IF;

	END	IF;

	v_result := 0;

EXCEPTION
	WHEN	DUP_VAL_ON_INDEX	-- such a service exists for the contract
	THEN
		RAISE_APPLICATION_ERROR( -20002, 'Service is already assigned!' );
	WHEN	wrong_sncode
	THEN
		RAISE_APPLICATION_ERROR( -20003, 'This service cannot be assigned on the contract!' );
	WHEN	not_active_contract
	THEN
		RAISE_APPLICATION_ERROR( -20004, 'Contract is not active!' );
	WHEN	fee_insertion_failure
	THEN
		RAISE_APPLICATION_ERROR( -20005, 'Cannot insert fee!' );
	WHEN	has_pending_request
	THEN
		RAISE_APPLICATION_ERROR( -20006, 'Contract has pending request!' );
END	assign_service;

MEMBER	PROCEDURE erase_service
	(
	i_sncode	IN NUMBER,
	o_request	OUT NUMBER
	)
AS
	-- Instance of service passed as parameter
	curr_service		service_t := service_t( NULL, NULL, NULL, NULL );
BEGIN
	-- Calling service constructor
	curr_service.init( i_sncode );

	SELF.erase_service
		(
		curr_service,
		o_request
		);

END	erase_service;

MEMBER	PROCEDURE erase_service
	(
	i_service	IN creator.service_t,
	o_request	OUT NUMBER
	)
AS

	-- Cursor for contract data
	CURSOR	contract_cur ( p_co_id NUMBER )
	IS
	SELECT	ca.customer_id,
		ca.sccode,
		ca.plcode,
		gm.gmd_market_id
	FROM	contract_all	ca,
		gmd_mpdsctab	gm
	WHERE	gm.sccode = ca.sccode
	AND	ca.co_id = SELF.co_id;

	-- Cursor for HLR data
	CURSOR	hlcode_cur ( p_co_id NUMBER )
	IS
	SELECT	cd.hlcode,
		mp.switch_id
	FROM	contr_devices	cd,
		mpdhltab	mp
	WHERE	cd.hlcode = mp.hlcode
	AND	cd.co_id = p_co_id
	AND	cd.cd_validfrom =
		(
		SELECT	MAX( cd_validfrom )
		FROM	contr_devices
		WHERE	co_id = p_co_id
		AND	cd_activ_date IS NOT NULL
		);

	contract_rec		contract_cur%ROWTYPE;

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

	-- Objects
	-- Request
	request			creator.parameter_t := creator.parameter_t
							( 'MAX_REQUEST' );
	-- Service which will be processed
	curr_contr_service	creator.contr_service_t;

	-- Instance of service passed as parameter
	curr_service		creator.service_t := creator.service_t
							(
							NULL,
							NULL,
							NULL,
							NULL
							);

	v_hlcode		contr_devices.hlcode%TYPE;
	v_switch_id		mpdhltab.switch_id%TYPE;

	v_seqno			NUMBER;
	c_action_id		CONSTANT NUMBER := 9;	-- ID of service deletion
							-- from GMD_ACTION

	service_is_assigned	BOOLEAN := FALSE;

	-- Exceptions
	service_not_found	EXCEPTION;
	hlcode_not_found	EXCEPTION;
	service_not_assigned	EXCEPTION;
	non_existing_contract	EXCEPTION;
	not_active_contract	EXCEPTION;
	service_is_pending	EXCEPTION;
	wrong_status		EXCEPTION;
	request_num_error	EXCEPTION;
	has_pending_request	EXCEPTION;

BEGIN

	-- Checking contract status - we can perform operations only on
	-- active contracts
	IF	(
		SELF.status != 'a'
		OR
		SELF.status IS NULL
		)
	THEN
		RAISE	not_active_contract;
	END	IF;

	-- Checking if contract has global request pending
	IF	SELF.has_pending_request = TRUE
	THEN
		RAISE	has_pending_request;
	END	IF;

	-- Checking if service really exists
	IF	i_service.sncode = 0
	THEN
		RAISE	service_not_found;
	END	IF;

	-- Checking if service is assigned to the contract
	FOR	i IN SELF.services.FIRST..SELF.services.COUNT
	LOOP
		-- Running through all the contract services
		IF	SELF.services(i).service.sncode = i_service.sncode	-- bingo!
		THEN
			curr_contr_service := SELF.services(i);
			service_is_assigned := TRUE;
			EXIT;
		END	IF;
	END	LOOP;

	IF	service_is_assigned = FALSE
	THEN
		RAISE	service_not_assigned;
	END	IF;

	-- Checking if service has not pending state
	IF	curr_contr_service.pending_state IS NOT NULL
	THEN
		RAISE	service_is_pending;
	END	IF;

	-- Checking if service can be deactivated
	IF	(
		curr_contr_service.status = 'd'
		OR
		curr_contr_service.status IS NULL
		)
	THEN
		RAISE	wrong_status;
	END	IF;

	-- Checking if service needs request to be created
	IF	curr_contr_service.service.needs_request = TRUE	-- Service needs request
	THEN

		-- Looking for next request number		
		o_request := request.next_value;

		IF	o_request = -1
		THEN
			RAISE	request_num_error;
		END	IF;

		INSERT	INTO gmd_request_base
			(
			request_id,
			entry_date
			)
		VALUES	(
			o_request,
			SYSDATE
			);

		-- Looking for contract data
		OPEN	contract_cur ( SELF.co_id );
		
			FETCH	contract_cur
			INTO	contract_rec;

		CLOSE	contract_cur;

		-- Looking for HLR data
		OPEN	hlcode_cur ( SELF.co_id );

			FETCH	hlcode_cur
			INTO	v_hlcode,
				v_switch_id;

			IF	hlcode_cur%NOTFOUND
			THEN
				RAISE	hlcode_not_found;
			END	IF;

		CLOSE	hlcode_cur;

		-- Inserting request
		INSERT	INTO mdsrrtab
			(
			request,
			plcode,
			status,
			ts,
			userid,
			customer_id,
			vmd_retry,
			error_retry,
			co_id,
			insert_date,
			request_update,
			priority,
			action_date,
			switch_id,
			sccode,
			worker_pid,
			gmd_market_id,
			action_id,
			data_1,
			data_2,
			data_3,
			error_code
			)
		VALUES	(
			o_request,		-- request
			contract_rec.plcode,	-- plcode
			2,			-- status
			SYSDATE,		-- ts
			USER,			-- userid
			SELF.customer_id,	-- customer_id
			0,			-- vmd_retry
			0,			-- error_retry
			SELF.co_id,		-- co_id
			SYSDATE,		-- insert_date
			NULL,			-- request_update
			8,			-- priority
			SYSDATE,		-- action_date
			v_switch_id,		-- switch_id
			contract_rec.sccode,	-- sccode
			0,			-- worker_pid
			contract_rec.gmd_market_id,	-- gmd_market_id
			c_action_id,		-- action_id
			NULL,			-- data_1
			NULL,			-- data_2
			NULL,			-- data_3
			0			-- error_code
			);
		
		UPDATE	contr_services
		SET	cs_pending_state = TO_CHAR( SYSDATE, 'YYMMDD' ) || 'd',
			cs_request = o_request
		WHERE	co_id = SELF.co_id
		AND	sncode = curr_contr_service.service.sncode
		AND	cs_seqno = curr_contr_service.seqno;

		-- Checking if service is bearer service
		IF	curr_contr_service.service.is_bearer_service = TRUE
		THEN
			OPEN	contr_services_cur
				(
				SELF.co_id,
				curr_contr_service.service.sncode
				);
			
				FETCH	contr_services_cur
				INTO	v_seqno;
			
				UPDATE	contr_services_cap
				SET	cs_deactiv_date = SYSDATE,
					cs_request = o_request
				WHERE	CURRENT OF contr_services_cur;

			CLOSE	contr_services_cur;
		END	IF;

		-- Chcecking if service needs parameters
		IF	curr_contr_service.prm_value_id IS NOT NULL
		THEN

			UPDATE	parameter_value	pv
			SET	pv.request_id = o_request
			WHERE	pv.prm_value_id = curr_contr_service.prm_value_id
			AND	pv.parameter_id IN
				(
				SELECT	parameter_id
				FROM	mkt_parameter_action
				WHERE	sccode = contract_rec.sccode
				AND	action =
					(
					SELECT	ca_action_id
					FROM	mkt_gmd_link_action
					WHERE	gmd_action_id = c_action_id
					)
				)
			AND	pv.prm_seqno =
				(
				SELECT	MAX( pv1.prm_seqno )
				FROM	parameter_value	pv1
				WHERE	pv1.prm_value_id = pv.prm_value_id
				AND	pv1.prm_no = pv.prm_no
				AND	pv1.parent_seqno = pv.parent_seqno
				AND	pv1.sibling_seqno = pv.sibling_seqno
				AND	pv1.complex_seqno = pv.complex_seqno
				AND	NOT EXISTS
					(
					SELECT	pv2.prm_seqno
					FROM	parameter_value	pv2
					WHERE	pv2.prm_value_id = pv1.prm_value_id
					AND	pv2.parent_seqno = pv1.parent_seqno
					AND	pv2.sibling_seqno = pv1.sibling_seqno
					AND	pv2.complex_seqno = pv1.complex_seqno
					AND	pv2.prm_no = pv1.prm_no
					AND	pv2.prm_seqno > pv1.prm_seqno
					)
				);
		END	IF;
	ELSE

		o_request := 0;

		UPDATE	contr_services
		SET	cs_stat_chng = cs_stat_chng || '|' ||
				TO_CHAR( SYSDATE, 'YYMMDD' ) || 'd'
		WHERE	co_id = SELF.co_id
		AND	sncode = curr_contr_service.service.sncode
		AND	cs_seqno = curr_contr_service.seqno;

	END	IF;

	init ( SELF.co_id );

EXCEPTION
	WHEN	not_active_contract
	THEN
		o_request := -3;
		RAISE_APPLICATION_ERROR ( -20001, 'Contract is not active!' );
	WHEN	service_not_found
	THEN
		o_request := -10;
		RAISE_APPLICATION_ERROR( -20002, 'Service is not found!' );
	WHEN	hlcode_not_found
	THEN
		o_request := -11;
		RAISE_APPLICATION_ERROR( -20003, 'HLR is not found!' );
	WHEN	service_not_assigned
	THEN
		o_request := -12;
		RAISE_APPLICATION_ERROR( -20004, 'Service is not assigned!' );
	WHEN	service_is_pending
	THEN
		o_request := -14;
		RAISE_APPLICATION_ERROR( -20005, 'Service has pending request!' );
	WHEN	wrong_status
	THEN
		o_request := -15;
		RAISE_APPLICATION_ERROR( -20006, 'Service is in the wrong status!' );
	WHEN	request_num_error
	THEN
		o_request := -16;
		RAISE_APPLICATION_ERROR( -20007, 'Cannot retreive request number!' );
	WHEN	has_pending_request
	THEN
		o_request := -17;
		RAISE_APPLICATION_ERROR( -20008, 'Contract has pending request' );
	WHEN	OTHERS
	THEN
		o_request := SQLCODE;
		RAISE;
END	erase_service;

-- Function for service registering
MEMBER	PROCEDURE register_service
	(
	i_sncode	IN NUMBER,
	o_request	OUT NUMBER
	)
AS

	-- Cursor for contract data
	CURSOR	contract_cur
	IS
	SELECT	ca.customer_id,
		ca.sccode,
		ca.plcode,
		gm.gmd_market_id
	FROM	contract_all	ca,
		gmd_mpdsctab	gm
	WHERE	gm.sccode = ca.sccode
	AND	ca.co_id = SELF.co_id;

	-- Cursor for HLR data
	CURSOR	hlcode_cur
	IS
	SELECT	cd.hlcode,
		mp.switch_id
	FROM	contr_devices	cd,
		mpdhltab	mp
	WHERE	cd.hlcode = mp.hlcode
	AND	cd.co_id = SELF.co_id
	AND	cd.cd_validfrom =
		(
		SELECT	MAX( cd_validfrom )
		FROM	contr_devices
		WHERE	co_id = SELF.co_id
		AND	cd_activ_date IS NOT NULL
		);

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

	contract_rec	contract_cur%ROWTYPE;

	v_request	NUMBER := 0;
	v_hlcode	contr_devices.hlcode%TYPE;
	v_switch_id	mpdhltab.switch_id%TYPE;
	v_seqno		NUMBER;
	c_action_id	CONSTANT NUMBER := 8;	-- ID of service adding
						-- from GMD_ACTION

	service_is_assigned	BOOLEAN := FALSE;

	service_not_found	EXCEPTION;
	hlcode_not_found	EXCEPTION;
	service_not_assigned	EXCEPTION;
	service_is_pending	EXCEPTION;
	wrong_status		EXCEPTION;
	has_pending_request	EXCEPTION;

	-- Initializing request object
	request			creator.parameter_t := creator.parameter_t
							( 'MAX_REQUEST' );

	-- Service which will be processed
	curr_contr_service	contr_service_t;

BEGIN

	-- Checking if contract has global request pending
	IF	SELF.has_pending_request = TRUE
	THEN
		RAISE	has_pending_request;
	END	IF;

	-- Checking if service is assigned to contract
	FOR	i IN SELF.services.FIRST..SELF.services.COUNT
	LOOP
		IF	SELF.services(i).service.sncode = i_sncode	-- it does
		THEN
			curr_contr_service := SELF.services(i);
			service_is_assigned := TRUE;
			EXIT;
		END	IF;
	END	LOOP;

	IF	service_is_assigned = FALSE	-- service is not assigned
	THEN
		RAISE	service_not_assigned;
	END	IF;

	-- Checking if service has not pending state
	IF	curr_contr_service.pending_state IS NOT NULL
	THEN
		RAISE	service_is_pending;
	END	IF;

	-- Checking service status
	IF	curr_contr_service.status = 'a'
	THEN
		RAISE	wrong_status;
	END	IF;

	-- Checking if service needs request to be created
	IF	curr_contr_service.service.needs_request = TRUE	-- Service needs request
	THEN

		-- Looking for next request number		
		o_request := request.next_value;

		INSERT	INTO gmd_request_base
			(
			request_id,
			entry_date
			)
		VALUES	(
			o_request,
			SYSDATE
			);

		-- Looking for contract data
		OPEN	contract_cur;
		
			FETCH	contract_cur
			INTO	contract_rec;

		CLOSE	contract_cur;

		-- Looking for HLR data
		OPEN	hlcode_cur;

			FETCH	hlcode_cur
			INTO	v_hlcode,
				v_switch_id;

			IF	hlcode_cur%NOTFOUND
			THEN
				RAISE	hlcode_not_found;
			END	IF;

		CLOSE	hlcode_cur;

		-- Inserting request
		INSERT	INTO mdsrrtab
			(
			request,
			plcode,
			status,
			ts,
			userid,
			customer_id,
			vmd_retry,
			error_retry,
			co_id,
			insert_date,
			request_update,
			priority,
			action_date,
			switch_id,
			sccode,
			worker_pid,
			gmd_market_id,
			action_id,
			data_1,
			data_2,
			data_3,
			error_code
			)
		VALUES	(
			o_request,		-- request
			contract_rec.plcode,	-- plcode
			2,			-- status
			SYSDATE,		-- ts
			USER,			-- userid
			SELF.customer_id,	-- customer_id
			0,			-- vmd_retry
			0,			-- error_retry
			SELF.co_id,		-- co_id
			SYSDATE,		-- insert_date
			NULL,			-- request_update
			8,			-- priority
			SYSDATE,		-- action_date
			v_switch_id,		-- switch_id
			contract_rec.sccode,	-- sccode
			0,			-- worker_pid
			contract_rec.gmd_market_id,	-- gmd_market_id
			c_action_id,		-- action_id
			NULL,			-- data_1
			NULL,			-- data_2
			NULL,			-- data_3
			0			-- error_code
			);
		
		UPDATE	contr_services
		SET	cs_pending_state = TO_CHAR( SYSDATE, 'YYMMDD' ) || 'a',
			cs_request = o_request
		WHERE	co_id = SELF.co_id
		AND	sncode = curr_contr_service.service.sncode
		AND	cs_seqno = curr_contr_service.seqno;

		-- Checking if service is bearer service
		IF	curr_contr_service.service.is_bearer_service = TRUE
		THEN
			OPEN	contr_services_cur
				(
				SELF.co_id,
				curr_contr_service.service.sncode
				);
			
				FETCH	contr_services_cur
				INTO	v_seqno;
			
				UPDATE	contr_services_cap
				SET	cs_activ_date = SYSDATE,
					cs_request = v_request
				WHERE	CURRENT OF contr_services_cur;

			CLOSE	contr_services_cur;
		END	IF;

		-- Chcecking if service has parameters to be updated
		IF	curr_contr_service.prm_value_id IS NOT NULL
		THEN

			UPDATE	parameter_value	pv
			SET	pv.request_id = v_request
			WHERE	pv.prm_value_id = curr_contr_service.prm_value_id
			AND	pv.parameter_id IN
				(
				SELECT	parameter_id
				FROM	mkt_parameter_action
				WHERE	sccode = contract_rec.sccode
				AND	action =
					(
					SELECT	ca_action_id
					FROM	mkt_gmd_link_action
					WHERE	gmd_action_id = c_action_id
					)
				)
			AND	pv.prm_seqno =
				(
				SELECT	MAX( pv1.prm_seqno )
				FROM	parameter_value	pv1
				WHERE	pv1.prm_value_id = pv.prm_value_id
				AND	pv1.prm_no = pv.prm_no
				AND	pv1.parent_seqno = pv.parent_seqno
				AND	pv1.sibling_seqno = pv.sibling_seqno
				AND	pv1.complex_seqno = pv.complex_seqno
				AND	NOT EXISTS
					(
					SELECT	pv2.prm_seqno
					FROM	parameter_value	pv2
					WHERE	pv2.prm_value_id = pv1.prm_value_id
					AND	pv2.parent_seqno = pv1.parent_seqno
					AND	pv2.sibling_seqno = pv1.sibling_seqno
					AND	pv2.complex_seqno = pv1.complex_seqno
					AND	pv2.prm_no = pv1.prm_no
					AND	pv2.prm_seqno > pv1.prm_seqno
					)
				);
		END	IF;
	ELSE

		o_request := 0;

		-- Updating status change
		-- Here we should check if there almost is some status change
		UPDATE	contr_services
		SET	cs_stat_chng = DECODE(	cs_stat_chng || 'a',
						'a', '',	-- No status change
						cs_stat_chng || '|'
						) ||
				TO_CHAR( SYSDATE, 'YYMMDD' ) || 'a'
		WHERE	co_id = SELF.co_id
		AND	sncode = curr_contr_service.service.sncode
		AND	cs_seqno = curr_contr_service.seqno;

	END	IF;

	init ( SELF.co_id );

EXCEPTION
	WHEN	service_not_found
	THEN
		o_request := -10;
		RAISE_APPLICATION_ERROR( -20002, 'Service is not found!' );
	WHEN	hlcode_not_found
	THEN
		o_request := -11;
		RAISE_APPLICATION_ERROR( -20003, 'HLR is not found!' );
	WHEN	service_not_assigned
	THEN
		o_request := -12;
		RAISE_APPLICATION_ERROR( -20004, 'Service is not assigned!' );
	WHEN	service_is_pending
	THEN
		o_request := -14;
		RAISE_APPLICATION_ERROR( -20005, 'Service has pending request!' );
	WHEN	wrong_status
	THEN
		o_request := -15;
		RAISE_APPLICATION_ERROR( -20006, 'Service is in the wrong status!' );
	WHEN	has_pending_request
	THEN
		o_request := -17;
		RAISE_APPLICATION_ERROR( -20008, 'Contract has pending request' );
	WHEN	OTHERS
	THEN
		o_request := SQLCODE;
		RAISE;
END	register_service;

MEMBER	PROCEDURE register_service
	(
	i_service	IN creator.service_t,
	o_request	OUT NUMBER
	)
AS
BEGIN
	register_service
		(
		i_service.sncode,
		o_request
		);
END	register_service;

MEMBER	FUNCTION status
	(
	i_date	IN DATE := SYSDATE
	)
RETURN	VARCHAR2
AS

	v_status	VARCHAR2(1);

BEGIN

	SELECT	ch_status
	INTO	v_status
	FROM	contract_history
	WHERE	co_id = SELF.co_id
	AND	ch_pending IS NULL
	AND	ch_seqno =
		(
		SELECT	MAX( ch_seqno )
		FROM	contract_history
		WHERE	co_id = SELF.co_id
		AND	ch_validfrom <= i_date
		AND	ch_pending IS NULL
		);

	RETURN	v_status;

EXCEPTION

	WHEN	NO_DATA_FOUND
	THEN
		RAISE_APPLICATION_ERROR( -20001, 'No such contract!' );

END	status;

MEMBER	FUNCTION	suspension_time
	(
	i_from_date	DATE := NULL,
	i_to_date	DATE := NULL
	)
RETURN	NUMBER
IS

	v_from_date	DATE;
	v_to_date	DATE;
	v_date		DATE;
	v_status	VARCHAR2(1) := NULL;
	v_susp_days	PLS_INTEGER := 0;
	v_prev_status	VARCHAR2(1) := NULL;
	v_prev_date	DATE;
	v_last_record	BOOLEAN := FALSE; -- switch to exit status_cur

	-- Cursor for deactivation date search
	CURSOR	deact_date_cur
		(
		p_co_id	NUMBER
		)
	IS
	SELECT	TRUNC( ch_validfrom )
	FROM	contract_history
	WHERE	co_id = p_co_id
	AND	ch_status = 'd';

	-- Cursor for all the status changed in given period of time
	CURSOR	status_cur
		(
		p_co_id		NUMBER,
		p_from_date	DATE
		)
	IS
	SELECT	ch_status,
		TRUNC( ch_validfrom )
	FROM	contract_history
	WHERE	co_id = p_co_id
	AND	ch_validfrom >=	-- Looking for one step before from_time
		(
		SELECT	MAX( ch_validfrom )
		FROM	contract_history
		WHERE	co_id = p_co_id
		AND	ch_validfrom <= p_from_date
		)
	ORDER	BY ch_validfrom;

	v_co_activated	DATE;

BEGIN

	-- Looking for contract first activation date
	SELECT	co_activated
	INTO	v_co_activated
	FROM	contract_all
	WHERE	co_id = SELF.co_id;

	IF	i_from_date IS NOT NULL
	THEN
		-- Here we need to choose greated date between i_from_date
		-- passed and co_activated for correct data fetch
		v_from_date := GREATEST ( i_from_date, v_co_activated );
	ELSE
		v_from_date := v_co_activated;
	END	IF;

	-- Looking for upper bound
	IF	i_to_date IS NULL
	THEN
		-- Searching deactiovation date
		OPEN	deact_date_cur( SELF.co_id );

			FETCH	deact_date_cur
			INTO	v_to_date;

			-- Deactivation date not found - using sysdate
			IF	deact_date_cur%NOTFOUND
			THEN
				v_to_date := TRUNC( SYSDATE );
			END	IF;

		CLOSE	deact_date_cur;
	ELSE
		v_to_date := i_to_date;
	END	IF;

	OPEN	status_cur
		(
		SELF.co_id,
		v_from_date
		);
	LOOP
		FETCH	status_cur
		INTO	v_status,
			v_date;

		EXIT	WHEN
			(
			status_cur%NOTFOUND
			OR
			v_last_record = TRUE
			);

		-- First date maybe less than from_date
		IF	v_date < v_from_date
		THEN
			v_date := v_from_date;
		END	IF;

		-- Last date maybe greater than to_date
		IF	v_date > v_to_date
		THEN
			v_date := v_to_date;
			-- This is the last record to fetch
			v_last_record := TRUE;
		END	IF;

		-- Checking status change
		IF	v_status IN ( 'o', 'a' )
		THEN
			-- Looking for previous status change
			IF	v_prev_status = 's'
			THEN
				v_susp_days := v_susp_days + ( v_date - v_prev_date );
			END	IF;

			v_prev_date := v_date;
			v_prev_status := 'a';

		ELSE
			v_prev_date := v_date;
			v_prev_status := 's';
		END	IF;
	END	LOOP;
	CLOSE	status_cur;

	-- Contract can be suspended and we need take care about
	-- this period
	IF	(
		v_prev_status = 's'
		AND
		v_to_date > v_date
		)
	THEN
		v_susp_days := v_susp_days + ( v_to_date - v_date );
	END	IF;

	RETURN	v_susp_days;

EXCEPTION

	WHEN	OTHERS
	THEN
		RETURN	-1;
END	suspension_time;

MEMBER	FUNCTION has_pending_request
RETURN	BOOLEAN
IS
	v_cs_pending_state	contr_services.cs_pending_state%TYPE;
BEGIN

	SELECT	DISTINCT ( cs_pending_state )
	INTO	v_cs_pending_state
	FROM	contr_services
	WHERE	co_id = SELF.co_id
	AND	cs_pending_state IS NOT NULL
	AND	cs_seqno =
		(
		SELECT	MAX( cs_seqno )
		FROM	contr_services
		WHERE	co_id = SELF.co_id
		);
		
	RETURN	TRUE;

EXCEPTION
	WHEN	NO_DATA_FOUND
	THEN
		RETURN	FALSE;
	WHEN	TOO_MANY_ROWS
	THEN
		RETURN	FALSE;
END	has_pending_request;

MEMBER	FUNCTION has_pending_request
	(
	i_co_id	NUMBER
	)
RETURN	BOOLEAN
IS
	v_cs_pending_state	contr_services.cs_pending_state%TYPE;
BEGIN

	SELECT	DISTINCT ( cs_pending_state )
	INTO	v_cs_pending_state
	FROM	contr_services
	WHERE	co_id = i_co_id
	AND	cs_pending_state IS NOT NULL
	AND	cs_seqno =
		(
		SELECT	MAX( cs_seqno )
		FROM	contr_services
		WHERE	co_id = i_co_id
		);
		
	RETURN	TRUE;

EXCEPTION
	WHEN	NO_DATA_FOUND
	THEN
		RETURN	FALSE;
	WHEN	TOO_MANY_ROWS
	THEN
		RETURN	FALSE;
END	has_pending_request;
END;
/

SHOW ERROR