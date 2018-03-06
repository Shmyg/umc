CREATE	OR REPLACE
PACKAGE	BODY &owner..umc_customer
AS

g_username	CONSTANT VARCHAR2(20) := USER;

/*
Fucntion for match criteria creation. Match criteria is inserted in CCLNAMEMC
field of CCONTACT_ALL table and used in KV during customer creation for
duplicate customers search.
Match criteria is formed by extraction of all consonants (doesn't matter latyn
or cyrillic) except of cyrillic i short (й) from CCLNAME and making them
uppercase
*/

FUNCTION	match_criteria
	(
	i_name	VARCHAR
	)
RETURN	VARCHAR
IS
	v_mc		VARCHAR2(40);
	v_symbol	VARCHAR2(1);

	i	BINARY_INTEGER;
	j	BINARY_INTEGER;

	TYPE	varray_type IS	VARRAY(80)
	OF	INTEGER;

	integer_array	varray_type := varray_type(
		66,
		67,
		68,
		70,
		71,
		72,
		74,
		75,
		76,
		77,
		78,
		80,
		81,
		82,
		83,
		84,
		86,
		87,
		88,
		90,
		98,
		99,
		100,
		102,
		103,
		104,
		106,
		107,
		108,
		109,
		110,
		112,
		113,
		114,
		115,
		116,
		118,
		119,
		120,
		122,
		177,
		178,
		179,
		180,
		182,
		183,
		186,
		187,
		188,
		189,
		191,
		192,
		193,
		194,
		196,
		197,
		198,
		199,
		200,
		201,
		209,
		210,
		211,
		212,
		214,
		215,
		218,
		219,
		220,
		221,
		223,
		224,
		225,
		226,
		228,
		229,
		230,
		231,
		232,
		233
		);


BEGIN

	FOR	i IN 1..LENGTH( i_name )
	LOOP
		v_symbol := SUBSTR( i_name, i, 1 );

		FOR	j IN 1..integer_array.COUNT
		LOOP
			IF	ASCII( v_symbol ) = integer_array(j)
			THEN
				v_mc := v_mc || UPPER( v_symbol );
				EXIT;
			END	IF;
		END	LOOP;
	END	LOOP;

	IF	LENGTH( v_mc ) > 20
	THEN
		v_mc := SUBSTR( v_mc, 1, 20 );
	END	IF;

	RETURN	v_mc;

END	match_criteria;

PROCEDURE	check_address
	(
	i_address_tab	IN address_tab_type,
	o_result	OUT NUMBER
	)
IS
	
	i	BINARY_INTEGER;

BEGIN

	FOR	i IN i_address_tab.FIRST..i_address_tab.COUNT
	LOOP
		-- Checking parameters
		IF	(
			i_address_tab(i).cclname IS NULL
			OR
			i_address_tab(i).cccity IS NULL
			OR
			i_address_tab(i).ccstreet IS NULL
			OR
			i_address_tab(i).ccstreetno IS NULL
			OR
			i_address_tab(i).cczip IS NULL
			OR
			i_address_tab(i).cctn IS NULL
			OR
			i_address_tab(i).cctn_area IS NULL
			)
		THEN
			o_result := -1;
			RETURN;
		END	IF;
	END	LOOP;

	o_result := 0;

END	check_address;

PROCEDURE	check_customer
	(
	i_customer_tab	IN customer_tab_type,
	o_result	OUT NUMBER
	)
IS
	
	i	BINARY_INTEGER;

BEGIN

	FOR	i IN i_customer_tab.FIRST..i_customer_tab.COUNT
	LOOP
		-- Checking if such customer doesn't exist
		check_passport( i_customer_tab(i).cscusttype, i_customer_tab(i).passportno, o_result );

		IF	o_result = -2
		THEN
			RETURN;
		END	IF;

		IF	(
			i_customer_tab(i).passportno IS NULL
			OR
			i_customer_tab(i).id_type IS NULL
			OR
			i_customer_tab(i).costcenter_id IS NULL
			OR	(
				i_customer_tab(i).id_type = 2	-- Document - registration number
				AND
				i_customer_tab(i).cstaxable = 'X'
				AND	(
					i_customer_tab(i).cscompregno IS NULL
					OR
					i_customer_tab(i).cscomptaxno IS NULL
					)
				)
			OR	(
				i_customer_tab(i).id_type = 1
				AND	(
					i_customer_tab(i).cssex IS NULL	-- Document - passport
					OR
					i_customer_tab(i).birthdate IS NULL
					OR
					i_customer_tab(i).csremark_1 IS NULL
					)
				)
			)
		THEN
			o_result := -3;
			RETURN;
		END	IF;
	END	LOOP;

	o_result := 0;

END	check_customer;

PROCEDURE	check_passport
	(
	i_cscusttype	IN customer_all.cscusttype%TYPE,
	i_passportno	IN customer_all.passportno%TYPE,
	o_result	OUT NUMBER
	)
IS

	TYPE	numbers_array
	IS	VARRAY(10)
	OF	NUMBER;

	my_array	numbers_array;

	v_length	NUMBER;
	i		BINARY_INTEGER;
	v_sum		NUMBER := 0;
	v_contr_num	NUMBER;
	v_last_num	NUMBER;
	v_count		NUMBER;
	v_symbol	NUMBER;
	v_series	VARCHAR2(2);
	v_passportno	NUMBER;
	
	passport_exists		EXCEPTION;
	wrong_passportno	EXCEPTION;
	wrong_zkpo		EXCEPTION;
	stolen_passport		EXCEPTION;

BEGIN

	-- Checking if such passportno exists in database
	SELECT	COUNT(*)
	INTO	v_count
	FROM	customer_all
	WHERE	passportno = i_passportno;

	IF	v_count != 0
	THEN
		RAISE	passport_exists;
	END	IF;

	-- Checking if passport is not stolen
	v_series := SUBSTR( i_passportno, 1, 2 );
	v_passportno := SUBSTR( i_passportno, 4, 6 );

	SELECT	COUNT(*)
	INTO	v_count
	FROM	stolen_passports
	WHERE	series = v_series
	AND	passportno = v_passportno;


	IF	v_count != 0
	THEN
		RAISE	stolen_passport;
	END	IF;

	IF	i_cscusttype = 'C'
	THEN

		IF	LENGTH( i_passportno ) != 9
		THEN
			RAISE	wrong_passportno;
		END	IF;

		-- 1st and 2nd symbols must be cyrillic uppercase
		FOR i IN 1..2
		LOOP
			v_symbol := ASCII( SUBSTR( i_passportno, i, 1) );
			IF	v_symbol NOT BETWEEN 176 AND 207
			THEN
				RAISE	wrong_passportno;
			END	IF;	
		END	LOOP;
		
		-- Third symbol must be a space
		v_symbol := ASCII( SUBSTR( i_passportno, 3, 1) );

		IF	v_symbol != 32
		THEN
			RAISE	wrong_passportno;
		END	IF;
	
		-- Symbols from 4th to 9th must be numbers
		FOR	i IN 4..9
		LOOP
			v_symbol := ASCII( SUBSTR( i_passportno, i, 1) );
			IF	v_symbol NOT BETWEEN 48 AND 57
			THEN
				RAISE	wrong_passportno;
			END	IF;	
		END	LOOP;	

	ELSE

		-- Checking zkpo validity according to state requirements
		IF	LENGTH( i_passportno ) != 8
		THEN
			RAISE	wrong_zkpo;
		END	IF;

		IF	(
			i_passportno > '30000000'
			AND
			i_passportno < '60000000'
			)
		THEN
			my_array := numbers_array( 7, 1, 2, 3, 4, 5, 6 );
		ELSE
			my_array := numbers_array( 1, 2, 3, 4, 5, 6, 7 );
		END	IF;

		FOR	i IN 1..7
		LOOP
			v_sum := v_sum + TO_NUMBER( SUBSTR( i_passportno, i, 1 ) ) * my_array(i);
		END	LOOP;

		v_contr_num := MOD( v_sum, 11 );
		v_last_num := TO_NUMBER( SUBSTR( i_passportno, 8, 1 ) );

		IF	v_contr_num = 10
		THEN
			IF	(
				i_passportno > '30000000'
				AND
				i_passportno < '60000000'
				)
			THEN
				my_array := numbers_array( 9, 3, 4, 5, 6, 7, 8 );
			ELSE
				my_array := numbers_array( 3, 4, 5, 6, 7, 8, 9 );
			END	IF;

			v_sum := 0;

			FOR	i IN 1..7
			LOOP
				v_sum := v_sum + TO_NUMBER( SUBSTR( i_passportno, i, 1 ) ) * my_array(i);
			END	LOOP;

			v_contr_num := MOD( v_sum, 11 );

		END	IF;

		IF	v_last_num = v_contr_num
			OR	(
				v_last_num = 0
				AND
				v_contr_num = 10
				)
		THEN
			o_result := 0;
		ELSE
			RAISE	wrong_zkpo;
		END	IF;

	END	IF;
	
EXCEPTION

	WHEN	passport_exists
	THEN
		o_result := -2;
	WHEN	wrong_passportno
	THEN
		o_result := -13;
	WHEN	wrong_zkpo
	THEN
		o_result := -12;
	WHEN	stolen_passport
	THEN
		o_result := -14;
	WHEN	OTHERS
	THEN
		o_result := -100;

END	check_passport;

PROCEDURE	check_payment
	(
	i_payment_tab	IN payment_tab_type,
	o_result	OUT NUMBER
	)
IS
	
	i	BINARY_INTEGER;

BEGIN

	-- Checking dependencies and not null parameters
	FOR	i IN i_payment_tab.FIRST..i_payment_tab.COUNT
	LOOP
		IF	(
			i_payment_tab(i).payment_type = -2
			AND	(
				i_payment_tab(i).accountowner IS NULL
				OR
				i_payment_tab(i).bankaccno IS NULL
				OR
				i_payment_tab(i).banksubaccount IS NULL
				)
			)
			OR
			(
			i_payment_tab(i).payment_type = -4
			AND	(
				i_payment_tab(i).accountowner IS NULL
				OR
				i_payment_tab(i).bankaccno IS NULL
				OR
				i_payment_tab(i).banksubaccount IS NULL
				OR
				i_payment_tab(i).valid_thru_date IS NULL
				)
			)

		THEN
			o_result := -4;
			RETURN;
		END	IF;
	END	LOOP;
	
	o_result := 0;

END	check_payment;

PROCEDURE	create_address
	(
	i_customer_id	IN NUMBER,
	i_address_tab	IN address_tab_type,
	i_address_type	IN VARCHAR,
	o_result	OUT NUMBER
	)
IS

	v_sort_criteria	ccontact_all.sort_criteria%TYPE;
	v_country_id	country.country_id%TYPE;
	v_country_name	country.name%TYPE;
	v_lng_id	language.lng_id%TYPE;
	v_ccseq		ccontact_all.ccseq%TYPE;
	v_prgcode	customer_all.prgcode%TYPE;
	v_custcode	customer_all.custcode%TYPE;
	v_area_id	customer_all.area_id%TYPE;
	c_dmode_id	CONSTANT NUMBER := 2;	-- delivery mode (now we are using only 'mail')
	c_sysdate	CONSTANT DATE := TRUNC( SYSDATE );
	v_statement_id	INTEGER := 1;
	i		BINARY_INTEGER;
	v_ccline1	ccontact_all.ccline1%TYPE;
	v_ccline2	ccontact_all.ccline2%TYPE;
	v_ccline3	ccontact_all.ccline3%TYPE;
	v_ccline4	ccontact_all.ccline4%TYPE;
	v_ccline5	ccontact_all.ccline5%TYPE;
	v_ccline6	ccontact_all.ccline6%TYPE;
	v_cclnamemc	ccontact_all.cclnamemc%TYPE;
BEGIN

	check_address( i_address_tab, o_result );

	IF	o_result != 0
	THEN
		RETURN;
	END	IF;

	FOR	i IN i_address_tab.FIRST..i_address_tab.LAST
	LOOP
		
		-- Looking for next sequence number
		SELECT	NVL( MAX (ccseq), 0 ) + 1
		INTO	v_ccseq
		FROM	ccontact_all
		WHERE	customer_id = i_customer_id;

		-- Looking for customer data
		SELECT	prgcode,
			custcode,
			area_id
		INTO	v_prgcode,
			v_custcode,
			v_area_id
		FROM	customer_all
		WHERE	customer_id = i_customer_id;

		-- Looking for default values
		SELECT	country_id,
			name
		INTO	v_country_id,
			v_country_name
		FROM	country
		WHERE	country_def = 'X';

		SELECT	lng_id
		INTO	v_lng_id
		FROM	language
		WHERE	lng_def = 'X';

		-- Creating sort_criteria
		v_sort_criteria := LPAD( v_area_id, 5, '0' ) ||
					LPAD ( c_dmode_id, 5, '0' ) ||
					LPAD ( v_prgcode, 10, '0' ) ||
					LPAD ( v_custcode, 20, ' ' );

		-- Creating lines for envelope label
		v_ccline1 := i_address_tab(i).cclname;

		v_ccline2 := i_address_tab(i).ccfname || ' ' ||
				i_address_tab(i).ccname;

		IF	i_address_tab(i).ccaddr3 IS NOT NULL
		THEN
			v_ccline3 := i_address_tab(i).ccstreet || ',  ' ||
				i_address_tab(i).ccstreetno || ', кв.  ' ||
				i_address_tab(i).ccaddr3;
		ELSE
			v_ccline3 := i_address_tab(i).ccstreet || ', ' ||
				i_address_tab(i).ccstreetno;
		END	IF;

		IF	i_address_tab(i).ccaddr1 IS NOT NULL
		THEN
			v_ccline4 := i_address_tab(i).ccaddr1 || ', ' ||
				i_address_tab(i).ccaddr2;
		END	IF;

		v_ccline5 := i_address_tab(i).cczip || ' ' ||
			i_address_tab(i).cccity;

		v_ccline6 := v_country_name;

		v_cclnamemc := match_criteria( i_address_tab(i).cclname );

		-- Inserting address
		INSERT	INTO ccontact_all
			(
			customer_id,
			ccseq,
			cctitle,
			ccname,
			ccfname,
			cclname,
			ccstreet,
			ccstreetno,
			cclnamemc,
			ccaddr1,
			ccaddr2,
			ccaddr3,
			cccity,
			cczip,
			cccountry,
			cctn,
			cctn2,
			ccfax,
			ccline1,
			ccline2,
			ccline3,
			ccline4,
			ccline5,
			ccline6,
			cctn_area,
			cctn2_area,
			ccfax_area,
			ccjobdesc,
			ccdeftrk,
			ccuser,
			ccbill,
			ccbilldetails,
			cccontract,
			ccship,
			ccmagazine,
			ccdirectory,
			ccforward,
			ccurgent,
			country,
			cclanguage,
			ccadditional,
			sort_criteria,
			ccentdate,
			ccmoddate,
			ccmod,
			cccounty,
			ccstate,
			ccvaliddate,
			ccbill_previous,
			welcome_crit,
			ccmname,
			ccemail,
			ccaddryears,
			ccsmsno,
			ccinccode,
			ccbilltemp,
			userlastmod,
			ccvalidation,
			ccuser_inst,
			cclocation_1,
			cclocation_2,
			ccremark,
			rec_version
			)
		VALUES	(
			i_customer_id,			-- customer_id
			v_ccseq,			-- ccseq
			1,				-- cctitle
			i_address_tab(i).ccname,	-- ccname
			i_address_tab(i).ccfname,	-- ccfname
			i_address_tab(i).cclname,	-- cclname
			i_address_tab(i).ccstreet,	-- ccstreet
			i_address_tab(i).ccstreetno,	-- ccstreetno
			v_cclnamemc,			-- cclnamemc
			i_address_tab(i).ccaddr1,	-- ccaddr1
			i_address_tab(i).ccaddr2,	-- ccaddr2
			NVL( i_address_tab(i).ccaddr3, ' ' ),	-- ccaddr3
			i_address_tab(i).cccity,	-- cccity
			i_address_tab(i).cczip,		-- cczip
			v_country_name,			-- cccountry
			i_address_tab(i).cctn,		-- cctn
			i_address_tab(i).cctn2,		-- cctn2
			i_address_tab(i).ccfax,		-- ccfax
			v_ccline1,			-- ccline1
			v_ccline2,			-- ccline2
			v_ccline3,			-- ccline3
			v_ccline4,			-- ccline4
			v_ccline5,			-- ccline5
			v_ccline6,			-- ccline6
			i_address_tab(i).cctn_area,	-- cctn_area
			i_address_tab(i).cctn2_area,	-- cctn2_area
			i_address_tab(i).ccfax_area,	-- ccfax_area
			DECODE( NVL( i_address_tab(i).ccjobdesc, '0' ),
					'0', 'Businessman',
					i_address_tab(i).ccjobdesc ),	-- ccjobdesc
			NULL,			-- ccdeftrk
			'X',			-- ccuser
			'X',			-- ccbill
			'X',			-- ccbilldetails
			DECODE( i_address_type,	'BILL', '', 'X' ),	-- cccontract
			'X',			-- ccship
			NULL,			-- ccmagazine
			NULL,			-- ccdirectory
			NULL,			-- ccforward
			NULL,			-- ccurgent
			v_country_id,		-- country_id
			v_lng_id,		-- cclanguage
			NULL,			-- ccadditional
			v_sort_criteria,	-- sort_criteria
			c_sysdate,		-- ccentdate
			c_sysdate,		-- ccmoddate
			NULL,			-- ccmod
			NULL,			-- cccounty
			NULL,			-- ccstate
			c_sysdate,		-- ccvaliddate
			NULL,			-- ccbill_previous
			NULL,			-- welcome_crit
			NULL,			-- ccmname
			i_address_tab(i).ccemail,	-- ccemail
			NULL,			-- ccaddryears
			NULL,			-- ccsmsno
			NULL,			-- ccinccode
			NULL,			-- ccbilltemp
			USER,			-- userlastmod
			'X',			-- ccvalidation,
			NULL,			-- ccuser_inst,
			NULL,			-- cclocation_1,
			NULL,			-- cclocation_2,
			NULL,			-- ccremark,
			0			-- rec_version
			);

		IF	i_address_type = 'BILL'
		THEN
			UPDATE	ccontact_all
			SET	ccbill = NULL
			WHERE	customer_id = i_customer_id
			AND	ccseq =
				(
				SELECT	MAX( ccseq )
				FROM	ccontact_all
				WHERE	customer_id = i_customer_id
				AND	ccbill = 'X'
				AND	ccseq < v_ccseq
				);
		END	IF;
	END	LOOP;

	o_result := 0;

EXCEPTION
WHEN	NO_DATA_FOUND
THEN
	o_result :=-5;
	creator.admin.log_error( SQLCODE, SQLERRM );
	RETURN;
WHEN	OTHERS
THEN
	o_result := -6;
	creator.admin.log_error( SQLCODE, SQLERRM );
	RETURN;
END	create_address;

PROCEDURE	create_customer
	(
	i_customer_tab	IN OUT customer_tab_type,
	o_customer_id	OUT NUMBER,
	o_result	OUT NUMBER,
	i_tickler	IN VARCHAR DEFAULT 'Y'
	)

IS
	c_sysdate	CONSTANT DATE := TRUNC( SYSDATE );
	v_prgcode	pricegroup_all.prgcode%TYPE;
	v_rs_id		reasonstatus_all.rs_id%TYPE;
	v_cslanguage	customer_all.cslanguage%TYPE;
	v_csnationality	customer_all.csnationality%TYPE;
	v_wpid		welcome_proc.wpid%TYPE;
	v_convratetype_id	convratetypes.convratetype_id%TYPE;
	v_fc_id		currency_version.fc_id%TYPE;
	v_bm_id		NUMBER;
	v_count		NUMBER;
	i		BINARY_INTEGER;
BEGIN

	check_customer( i_customer_tab, o_result );
	IF	o_result != 0
	THEN
		RETURN;
	END	IF;

	FOR	i IN i_customer_tab.FIRST..i_customer_tab.COUNT
	LOOP

		-- Looking for customer_id
		SELECT	next_free_value
		INTO	o_customer_id
		FROM	app_sequence_value
		WHERE	app_sequence_id =
			(
			SELECT	app_sequence_id
			FROM	app_sequence
			WHERE	app_sequence_key = 'MAX_CUSTOMER_ID'
			)
		FOR	UPDATE;

		UPDATE	app_sequence_value
		SET	next_free_value = next_free_value + 1
		WHERE	app_sequence_id =
			(
			SELECT	app_sequence_id
			FROM	app_sequence
			WHERE	app_sequence_key = 'MAX_CUSTOMER_ID'
			);

		-- Looking for custcode
		SELECT	'1.' || next_free_value
		INTO	i_customer_tab(i).custcode
		FROM	app_sequence_value
		WHERE	app_sequence_id =
			(
			SELECT	app_sequence_id
			FROM	app_sequence
			WHERE	app_sequence_key = 'MAX_TL_CODE'
			)
		FOR	UPDATE;

		UPDATE	app_sequence_value
		SET	next_free_value = next_free_value + 1
		WHERE	app_sequence_id =
			(
			SELECT	app_sequence_id
			FROM	app_sequence
			WHERE	app_sequence_key = 'MAX_TL_CODE'
			);

		-- Looking for default values
		SELECT	prgcode
		INTO	v_prgcode
		FROM	pricegroup_all
		WHERE	prg_def = 'X';

		SELECT	rs_id
		INTO	v_rs_id
		FROM	reasonstatus_all
		WHERE	rs_status = 'i'
		AND	rs_default = 'X';

		SELECT	lng_id
		INTO	v_cslanguage
		FROM	language
		WHERE	lng_def = 'X';

		SELECT	country_id
		INTO	v_csnationality
		FROM	country
		WHERE	country_def = 'X';

		SELECT	wpid
		INTO	v_wpid
		FROM	welcome_proc
		WHERE	def = 'X';

		SELECT	fc_id
		INTO	v_fc_id
		FROM	currency_version
		WHERE	gl_curr = 'X'
		AND	version =
			(
			SELECT	MAX( version )
			FROM	currency_version
			WHERE	gl_curr = 'X'
			);

		SELECT	convratetype_id
		INTO	v_convratetype_id
		FROM	convratetypes
		WHERE	def = 'X';

		SELECT	bm_id
		INTO	v_bm_id
		FROM	bill_medium
		WHERE	bm_default = 'X';

		-- And n-o-o-o-o-w...
		INSERT	INTO customer_all
			(
			customer_id,
			customer_id_high,
			custcode,
			csst,
			cstype,
			csactivated,
			csdeactivated,
			customer_dealer,
			cstype_date,
			cstaxable,
			cslevel,
			cscusttype,
			cslvlname,
			tmcode,
			prgcode,
			termcode,
			csclimit,
			cscurbalance,
			csdepdate,
			billcycle,
			cstestbillrun,
			bill_layout,
			paymntresp,
			target_reached,
			pcsmethpaymnt,
			passportno,
			birthdate,
			dunning_flag,
			comm_no,
			pos_comm_type,
			btx_password,
			btx_user,
			settles_p_month,
			cashretour,
			cstradecode,
			cspassword,
			cspromotion,
			cscompregno,
			cscomptaxno,
			csreason,
			cscollector,
			cscontresp,
			csdeposit,
			cscredit_date,
			cscredit_remark,
			suspended,
			reactivated,
			prev_balance,
			lbc_date,
			employee,
			company_type,
			crlimit_exc,
			area_id,
			costcenter_id,
			csfedtaxid,
			credit_rating,
			cscredit_status,
			deact_create_date,
			deact_receip_date,
			edifact_addr,
			edifact_user_flag,
			edifact_flag,
			csdeposit_due_date,
			calculate_deposit,
			tmcode_date,
			cslanguage,
			csrentalbc,
			id_type,
			user_lastmod,
			csentdate,
			csmoddate,
			csmod,
			csnationality,
			csbillmedium,
			csitembillmedium,
			customer_id_ext,
			csreseller,
			csclimit_o_tr1,
			csclimit_o_tr2,
			csclimit_o_tr3,
			cscredit_score,
			cstraderef,
			cssocialsecno,
			csdrivelicence,
			cssex,
			csemployer,
			cstaxable_reason,
			wpid,
			csprepayment,
			csremark_1,
			csremark_2,
			ma_id,
			cssumaddr,
			bill_information,
			dealer_id,
			dunning_mode,
			not_valid,
			cscrdcheck_agreed,
			marital_status,
			expect_pay_curr_id,
			convratetype_payment,
			refund_curr_id,
			convratetype_refund,
			srcode,
			currency,
			primary_doc_currency,
			secondary_doc_currency,
			prim_convratetype_doc,
			sec_convratetype_doc,
			rec_version
			)
		VALUES	(
			o_customer_id,			-- customer_id,
			NULL,				-- customer_id_high,
			i_customer_tab(i).custcode,	-- custcode,
			NULL,				-- csst,
			'i',				-- cstype,
			NULL,				-- csactivated,
			NULL,				-- csdeactivated,
			'C',				-- customer_dealer,
			c_sysdate,			-- cstype_date,
			i_customer_tab(i).cstaxable,	-- cstaxable,
			40,				-- cslevel,
			i_customer_tab(i).cscusttype,	-- cscusttype,
			NULL,				-- cslvlname,
			153,				-- tmcode,
			v_prgcode,			-- prgcode,
			1,				-- termcode,
			0,				-- csclimit,
			0,				-- cscurbalance,
			NULL,				-- csdepdate,
			'02',				-- billcycle,
			NULL,				-- cstestbillrun,
			NULL,				-- bill_layout,
			'X',				-- paymntresp,
			NULL,				-- target_reached,
			NULL,				-- pcsmethpaymnt,
			i_customer_tab(i).passportno,	-- passportno,
			i_customer_tab(i).birthdate,	-- birthdate,
			NULL,				-- dunning_flag,
			NULL,				-- comm_no,
			NULL,				-- pos_comm_type,
			NULL,				-- btx_password,
			NULL,				-- btx_user,
			NULL,				-- settles_p_month,
			NULL,				-- cashretour,
			'01',				-- cstradecode,
			DECODE( NVL( i_customer_tab(i).cspassword, '0' ),
				0, 'UMC',
				i_customer_tab(i).cspassword ),	-- cspassword,
			NULL,				-- cspromotion,
			NVL( i_customer_tab(i).cscompregno, '007' ),	-- cscompregno
			NVL( i_customer_tab(i).cscomptaxno, '007' ),	-- cscomptaxno
			v_rs_id,			-- csreason,
			NULL,				-- cscollector,
			'X',				-- cscontresp,
			NULL,				-- csdeposit,
			NULL,				-- cscredit_date,
			NULL,				-- cscredit_remark,
			NULL,				-- suspended,
			NULL,				-- reactivated,
			0,				-- prev_balance,
			NULL,				-- lbc_date,
			NULL,				-- employee,
			NULL,				-- company_type,
			NULL,				-- crlimit_exc,
			i_customer_tab(i).area_id,	-- area_id,
			i_customer_tab(i).costcenter_id,	-- costcenter_id,
			NULL,				-- csfedtaxid,
			NULL,				-- credit_rating,
			NULL,				-- cscredit_status,
			NULL,				-- deact_create_date,
			NULL,				-- deact_receip_date,
			NULL,				-- edifact_addr,
			NULL,				-- edifact_user_flag,
			NULL,				-- edifact_flag,
			NULL,				-- csdeposit_due_date,
			NULL,				-- calculate_deposit,
			c_sysdate,			-- tmcode_date,
			v_cslanguage,			-- cslanguage,
			NULL,				-- csrentalbc,
			i_customer_tab(i).id_type,	-- id_type,
			USER,				-- user_lastmod,
			c_sysdate,			-- csentdate,
			NULL,				-- csmoddate,
			NULL,				-- csmod,
			v_csnationality,		-- csnationality,
                        1,                              -- csbillmedium,
			NULL,                           -- csitembillmedium,
			NULL,				-- customer_id_ext,
			NULL,				-- csreseller,
			NULL,				-- cslimit_o_tr1,
			NULL,				-- cslimit_o_tr2,
			NULL,				-- cslimit_o_tr3,
			NULL,				-- cscredit_score,
			NULL,				-- cstraderef,
			NULL,				-- cssocialsecno,
			NULL,				-- csdrivelicence,
			DECODE( i_customer_tab(i).cscusttype,
				'B', 'U', i_customer_tab(i).cssex ),	-- cssex,
			NULL,				-- csemployer,
			NULL,				-- cstaxable_reason,
			v_wpid,				-- wpid,
			NULL,				-- csprepayment,
			i_customer_tab(i).csremark_1,	-- csremark_1,
			NULL,				-- csremark_2,
			NULL,				-- ma_id,
			'B',				-- cssumaddr,
			NULL,				-- bill_information,
			NULL,				-- dealer_id,
			NULL,				-- dunning_mode,
			NULL,				-- not_valid,
			NULL,				-- cscrdcheck_agreed,
			1,				-- marital_status,
			NULL,				-- expect_pay_curr_id,
			NULL,				-- convratetype_payment,
			NULL,				-- refund_curr_id,
			NULL,				-- convratetype_refund,
			NULL,				-- srcode,
			v_fc_id,			-- currency,
			v_fc_id,			-- primary_doc_currency,
			NULL,				-- secondary_doc_currency,
			v_convratetype_id,		-- prim_convratetype_doc,
			NULL,				-- sec_convratetype_doc,
			0				-- rec_version
			);

		-- Adding customer to a billcycle
		UPDATE	billcycles
		SET	subscr_cont = subscr_cont + 1,
			mod_user = 'IT'
		WHERE	billcycle = '02';

		-- Unbilled amount
		INSERT	INTO mpuubtab
			(
			customer_id,
			unbilled_amount,
			crd_tickler_o_tr,
			crlimit_exc,
			last_billing_duration,
			contract_num,
			rtx_num,
			currency,
			rec_version
			)
		VALUES	(
			o_customer_id,	-- customer_id
			0,		-- unbilled_amount
			1,		-- crd_tickler_o_tr
			NULL,		-- crlimit_exc
			NULL,		-- last_billing_duration
			0,		-- contract_num
			0,		-- rtx_num
			v_fc_id,	-- currency
			0		-- rec_version
			);
		
		-- Inserting data for rateplan_hist_view
		-- Don't know what it is
		INSERT	INTO rateplan_hist_occ
			(
			customer_id,
			seqno,
			tmcode,
			tmcode_date,
			userlastmod,
			rec_version
			)
		VALUES	(
			o_customer_id,
			1,
			153,
			c_sysdate,
			'IT',
			0
			);

		INSERT	INTO individual_taxation
			(
			customer_id,
			valid_from,
			customercat_code,
			customergeo_code,
			rec_version
			)
		VALUES	(
			o_customer_id,
			c_sysdate,
			NULL,
			NULL,
			0
			);

		INSERT	INTO customer_base
			(
			customer_set_id,
			customer_id
			)
		VALUES	(
			1,
			o_customer_id
			);
	
		-- Checking if we should create a tickler
		IF	i_tickler = 'Y'
		THEN
			-- Creating tickler
			common.ibu_pos_api_tickler.createtickler
				(
				o_customer_id,	-- Customer_id
				NULL,	-- Contract_id
				4,	-- Priority
				'SYSTEM',	-- Tickler_code
				'NOTE',		-- Tickler_status
				'CC NEW',	-- Short description
				'New customer',	-- Long_description
				NULL,	-- action ID
				NULL,	-- equipment ID
				NULL,	-- market ID
				NULL,	-- message ID
				NULL,	-- date when the last message was sent
				NULL,	-- user who sent the last message
				NULL,	-- source code ID
				NULL,	-- problem tracking ID
				NULL,	-- type ID
				NULL,	-- usage ID
				g_username,	-- follow up user
				NULL,	-- follow up action ID
				SYSDATE,	-- follow up date
				NULL,	-- X co-ordinate
				NULL,	-- Y co-ordinate
				NULL,	-- distibution list user 1
				NULL,	-- distibution list user 2
				NULL,	-- distibution list user 3
				NULL,	-- user who closed the tickler
				SYSDATE,	-- date when the tickler was sent
				g_username,	-- user who created the tickler
				o_result
				);
		END	IF;
		
		-- Checking result
		IF	o_result != 0
		THEN
			o_result := -7;
			RETURN;
		END	IF;
			
	END	LOOP;

	o_result := 0;

EXCEPTION
	WHEN	NO_DATA_FOUND
	THEN
		o_result := -8;
		creator.admin.log_error( SQLCODE, SQLERRM );
		RETURN;
	WHEN	OTHERS
	THEN
		o_result := -9;
		creator.admin.log_error( SQLCODE, SQLERRM );
		RETURN;
END	create_customer;

PROCEDURE	insert_payment
	(
	i_customer_id	IN NUMBER,
	i_payment_tab	IN payment_tab_type,
	o_result	OUT NUMBER
	)
IS

	v_seq_id	NUMBER;
	v_fc_id		currency_version.fc_id%TYPE;
	c_sysdate	CONSTANT DATE := TRUNC( SYSDATE );
	i		BINARY_INTEGER;

BEGIN

	check_payment( i_payment_tab, o_result );
	
	IF	o_result != 0
	THEN
		RETURN;
	END	IF;

	SELECT	fc_id
	INTO	v_fc_id
	FROM	currency_version
	WHERE	gl_curr = 'X'
	AND	version =
		(
		SELECT	MAX( version )
		FROM	currency_version
		WHERE	gl_curr = 'X'
		);

	FOR	i IN i_payment_tab.FIRST..i_payment_tab.COUNT
	LOOP
	
		SELECT	NVL( MAX( seq_id ), 0 ) + 1
		INTO	v_seq_id
		FROM	payment_all
		WHERE	customer_id = i_customer_id;

		-- Inserting payment terms
		INSERT	INTO payment_all
			(
			customer_id,
			seq_id,
			bank_id,
			accountowner,
			bankaccno,
			banksubaccount,
			bankname,
			bankzip,
			bankcity,
			bankstreet,
			valid_thru_date,
			auth_ok,
			auth_date,
			auth_no,
			auth_credit,
			auth_tn,
			auth_remark,
			ceilingamt,
			bankstate,
			bankcounty,
			bankstreetno,
			bankcountry,
			ordernumber,
			act_used,
			payment_type,
			entdate,
			moddate,
			userlastmod,
			pmod,
			swiftcode,
			bank_controlkey,
			currency,
			rec_version
			)
		VALUES	(
			i_customer_id,	-- customer_id
			v_seq_id,	-- seq_id
			NULL,		-- bank_id
			NVL( i_payment_tab(i).accountowner, 'UMC' ),	-- accountowner
			i_payment_tab(i).bankaccno,	-- bankaccno
			i_payment_tab(i).banksubaccount,	-- banksubaccount
			NULL,		-- bankname
			NULL,		-- bankzip
			NULL,		-- bankcity
			NULL,		-- bankstreet
			i_payment_tab(i).valid_thru_date,		-- valid_thru_date
			NULL,		-- auth_ok
			NULL,		-- auth_date
			NULL,		-- auth_no
			0,		-- auth_credit
			NULL,		-- auth_tn
			NULL,		-- auth_remark
			NULL,		-- ceilingamt
			NULL,		-- bankstate
			NULL,		-- bankcounty
			NULL,		-- bankstreetno
			NULL,		-- bankcountry
			NULL,		-- ordernumber
			'X',		-- act_used
			i_payment_tab(i).payment_type,	-- payment_type
			c_sysdate,	-- entdate
			NULL,		-- moddate
			USER,		-- userlastmod
			NULL,		-- pmod
			NULL,		-- swiftcode
			NULL,		-- bank_controlkey,
			v_fc_id,	-- currency,
			0		-- rec_version
			);
	END	LOOP;

	o_result := 0;

EXCEPTION
	WHEN	NO_DATA_FOUND
	THEN
		o_result := -10;
		creator.admin.log_error( SQLCODE, SQLERRM );
		RETURN;
	WHEN	OTHERS
	THEN
		o_result := -11;
		creator.admin.log_error( SQLCODE, SQLERRM );
		RETURN;
		
END	insert_payment;

PROCEDURE	view_address
	(
	i_customer_id	IN customer_all.customer_id%TYPE,
	i_address_type	IN VARCHAR,
	o_address_cur	IN OUT address_cur_type
	)
IS
BEGIN

	IF	i_address_type = 'BILL'
	THEN
		OPEN	o_address_cur FOR
		SELECT	ccname,
			cclname,
			ccfname,
			cccity,
			ccstreet,
			ccstreetno,
			ccaddr1,
			ccaddr2,
			ccaddr3,
			cczip,
			cctn,
			cctn_area,
			cctn2,
			cctn2_area,
			ccfax,
			ccfax_area,
			ccemail,
			ccjobdesc
		FROM	ccontact_all
		WHERE	customer_id = i_customer_id
		AND	ccbill = 'X'
		AND	ccseq =
			(
			SELECT	MAX( ccseq )
			FROM	ccontact_all
			WHERE	customer_id = i_customer_id
			)
		AND	ccbill = 'X';
	ELSE
		OPEN	o_address_cur FOR
		SELECT	ccname,
			cclname,
			ccfname,
			cccity,
			ccstreet,
			ccstreetno,
			ccaddr1,
			ccaddr2,
			ccaddr3,
			cczip,
			cctn,
			cctn_area,
			cctn2,
			cctn2_area,
			ccfax,
			ccfax_area,
			ccemail,
			ccjobdesc
		FROM	ccontact_all
		WHERE	customer_id = i_customer_id
		AND	cccontract = 'X'
		AND	ccseq =
			(
			SELECT	MAX( ccseq )
			FROM	ccontact_all
			WHERE	customer_id = i_customer_id
			)
		AND	cccontract = 'X';
	END	IF;
END	view_address;

PROCEDURE	view_customer
	(
	i_passportno	IN customer_all.passportno%TYPE,
	o_customer_cur	IN OUT customer_cur_type
	)
IS
BEGIN
	OPEN	o_customer_cur FOR
	SELECT	custcode,
		passportno,
		cscusttype,
		id_type,
		cssex,
		birthdate,
		DECODE(	cscomptaxno,
			'Наутілус', NULL,
			cscomptaxno ),
		DECODE (cscompregno,
			'Наутілус', NULL,
			cscompregno ),
		costcenter_id,
		area_id,
		csremark_1,
		cstaxable,
		cspassword
	FROM	customer_all
	WHERE	passportno = i_passportno;

END	view_customer;

PROCEDURE	view_payment
	(
	i_customer_id	IN customer_all.customer_id%TYPE,
	o_payment_cur	IN OUT payment_cur_type
	)
IS
BEGIN

	OPEN	o_payment_cur FOR
	SELECT	payment_type,
		accountowner,
		bankaccno,
		banksubaccount,
		valid_thru_date
	FROM	payment_all
	WHERE	customer_id = i_customer_id
	AND	seq_id =
		(
		SELECT	MAX( seq_id )
		FROM	payment_all
		WHERE	customer_id = i_customer_id
		);
		
END	view_payment;



-- convert create_customer for jdbc call
procedure create_customer_wrapper
                  (o_customer_id IN OUT customer_all.customer_id%TYPE,  -- Customer_id
                   passportno    IN customer_all.passportno%TYPE,   -- Passportno - MANDATORY
                   cscusttype    IN customer_all.cscusttype%TYPE,   -- Customer type - MANDATORY
                   id_type       IN customer_all.id_type%TYPE,      -- Type of document - MANDATORY
                   cssex         IN customer_all.cssex%TYPE,        -- Sex of the customer - only for persons
                   birthdate     IN DATE,                           -- Birthdate - only for persons
                   cscomptaxno   IN customer_all.cscomptaxno%TYPE,  -- Registration number - only for companies
                   cscompregno   IN customer_all.cscompregno%TYPE,  -- Registration number - only for companies
                   costcenter_id IN customer_all.costcenter_id%TYPE,    -- Costcenter - MANDATORY
                   area_id       IN customer_all.area_id%TYPE,      -- Area - MANDATORY
                   csremark_1    IN customer_all.csremark_1%TYPE,   -- When and where passport issued - for persons       
                   cstaxable     IN customer_all.cstaxable%TYPE,
                   o_result      OUT NUMBER)
is
  
  v_customer customer_tab_type;
  i number := 1;

begin

  v_customer(i).passportno := passportno;
  v_customer(i).cscusttype := cscusttype;
  v_customer(i).id_type := id_type;
  v_customer(i).cssex := cssex;
  v_customer(i).birthdate := birthdate;
  v_customer(i).cscomptaxno := cscomptaxno;
  v_customer(i).cscompregno := cscompregno;
  v_customer(i).costcenter_id := costcenter_id;
  v_customer(i).area_id := area_id;
  v_customer(i).csremark_1 := csremark_1;

  create_customer(v_customer, o_customer_id, o_result, 'N');

end create_customer_wrapper;

-- convert create_address for jdbc call
procedure create_address_wrapper
                  (v_customer_id IN customer_all.customer_id%TYPE,  -- Customer_id

                   -- ADDRESS
                   ccname        IN ccontact_all.ccname%TYPE,       -- Surname (for persons)
                   cclname       IN ccontact_all.cclname%TYPE,      -- Last name (for persons)
                   ccfname       IN ccontact_all.ccfname%TYPE,      -- Name - MANDATORY
                   cccity        IN ccontact_all.cccity%TYPE,       -- City - MANDATORY
                   ccstreet      IN ccontact_all.ccstreet%TYPE,     -- Street - MANDATORY
                   ccstreetno    IN ccontact_all.ccstreetno%TYPE,   -- Street number - MANDATORY
                   ccaddr1       IN ccontact_all.ccaddr1%TYPE,      -- Region (oblast)
                   ccaddr2       IN ccontact_all.ccaddr2%TYPE,      -- Area (rayon)
                   ccaddr3       IN ccontact_all.ccaddr3%TYPE,      -- Appt. number
                   cczip         IN ccontact_all.cczip%TYPE,        -- Zip - MANDATORY
                   cctn          IN ccontact_all.cctn%TYPE,         -- Phone number - MANDATORY
                   cctn_area     IN ccontact_all.cctn_area%TYPE,    -- Phone code - MANDATORY
                   cctn2         IN ccontact_all.cctn2%TYPE,
                   cctn2_area    IN ccontact_all.cctn2_area%TYPE,
                   ccfax         IN ccontact_all.ccfax%TYPE,
                   ccfax_area    IN ccontact_all.ccfax%TYPE,
                   ccemail       IN ccontact_all.ccemail%TYPE,
                   i_address_type IN VARCHAR,
                   o_result      OUT NUMBER)
is
  
  v_address  address_tab_type;
  i number := 1;

begin

  v_address(i).ccname := ccname;
  v_address(i).cclname := cclname;
  v_address(i).ccfname := ccfname;
  v_address(i).cccity := cccity;
  v_address(i).ccstreet := ccstreet;
  v_address(i).ccstreetno := ccstreetno;
  v_address(i).ccaddr1 := ccaddr1;
  v_address(i).ccaddr2 := ccaddr2;
  v_address(i).ccaddr3 := ccaddr3;
  v_address(i).cczip := cczip;
  v_address(i).cctn := cctn;
  v_address(i).cctn_area := cctn_area;
  v_address(i).cctn2 := cctn2;
  v_address(i).cctn2_area := cctn2_area;
  v_address(i).ccfax := ccfax;
  v_address(i).ccfax_area := ccfax;
  v_address(i).ccemail := ccemail; 

  create_address(v_customer_id, v_address, i_address_type, o_result);

end create_address_wrapper;

-- convert create_bank for jdbc call
procedure create_bank_wrapper
                  (v_customer_id IN customer_all.customer_id%TYPE,  -- Customer_id

                   -- BANK
                   payment_type IN payment_all.payment_type%TYPE,  -- Payment type - MANDATORY
                   accountowner IN payment_all.accountowner%TYPE,
	           bankaccno IN payment_all.bankaccno%TYPE,
		   banksubaccount IN payment_all.banksubaccount%TYPE,
	           valid_thru_date payment_all.valid_thru_date%TYPE,
				
                   o_result      OUT NUMBER)
is
  
  v_bank  payment_tab_type;
  i number := 1;

begin

  v_bank(i).payment_type := payment_type;
  v_bank(i).accountowner := accountowner;
  v_bank(i).bankaccno := bankaccno;
  v_bank(i).banksubaccount := banksubaccount;
  v_bank(i).valid_thru_date := valid_thru_date;

  insert_payment(v_customer_id, v_bank, o_result);

end create_bank_wrapper;


-- convert create_tickler for jdbc call
procedure create_tickler_wrapper 
      (v_customer_id IN customer_all.customer_id%TYPE,  -- Customer_id
       v_desc IN tickler_records.long_description%TYPE, -- Long description
       v_user IN tickler_records.created_by%TYPE, -- Name of the user who created the record
       o_result OUT NUMBER)
is
begin

   common.ibu_pos_api_tickler.setPackageParameter('COMMIT_ON_SUCCESS', 'N');
   common.ibu_pos_api_tickler.setPackageParameter('AUTOCOMMIT', 'N');
   common.ibu_pos_api_tickler.setPackageParameter('AUTOROLLBACK', 'N');
   
   common.ibu_pos_api_tickler.createtickler
    (
     v_customer_id,	-- Customer_id
     NULL,	-- Contract_id
     4,	-- Priority
     'SYSTEM',	-- Tickler_code
     'NOTE',	-- Tickler_status
     'CC NEW',	-- Short description
     v_desc,	-- Long_description
     NULL,	-- action ID
     NULL,	-- equipment ID
     NULL,	-- market ID
     NULL,	-- message ID
     NULL,	-- date when the last message was sent
     NULL,	-- user who sent the last message
     NULL,	-- source code ID
     NULL,	-- problem tracking ID
     NULL,	-- type ID
     NULL,	-- usage ID
     v_user,	-- follow up user
     NULL,	-- follow up action ID
     SYSDATE,	-- follow up date
     NULL,	-- X co-ordinate
     NULL,	-- Y co-ordinate
     NULL,	-- distibution list user 1
     NULL,	-- distibution list user 2
     NULL,	-- distibution list user 3
     NULL,	-- user who closed the tickler
     SYSDATE,	-- date when the tickler was sent
     v_user,	-- user who created the tickler
     o_result
    );

end create_tickler_wrapper;

END	umc_customer;
/

SHOW ERRORS
