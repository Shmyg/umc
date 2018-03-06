CREATE	OR REPLACE
TYPE	BODY &owner..customer_t
AS
MAP
MEMBER	FUNCTION get_customer_id
RETURN	NUMBER
AS
BEGIN
	RETURN	SELF.customer_id;
END	get_customer_id;

MEMBER	PROCEDURE init
	(
	i_passportno	IN VARCHAR2
	)
AS
BEGIN
	NULL;
END	init;

MEMBER	PROCEDURE set_address
	(
	i_address	creator.address_t
	)
AS
	v_prgcode	customer_all.prgcode%TYPE;
	v_ccseq		PLS_INTEGER;

	my_mail_label	creator.mail_label_t := creator.mail_label_t
							(
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL
							);
	my_address	creator.address_t := creator.address_t
						(
						NULL,
						NULL,
						NULL,
						NULL
						);
	
	same_address	EXCEPTION;

BEGIN

	-- Check if we really need to do something
	my_address := SELF.address( i_address.address_type );

	IF	my_address = i_address
	THEN
		RAISE	same_address;
	END	IF;

	-- Looking for customer attributes
	v_prgcode := SELF.prgcode;

	my_mail_label.create_
		(
		my_address.customer_name,
		my_address.postal_address
		);

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
		SELF.customer_id,		-- customer_id
		v_ccseq,			-- ccseq
		1,				-- cctitle
		i_address.customer_name.middle_name,	-- ccname
		i_address.customer_name.first_name,	-- ccfname
		i_address.customer_name.last_name,	-- cclname
		i_address.postal_address.street,	-- ccstreet
		i_address.postal_address.streetno,	-- ccstreetno
		v_cclnamemc,			-- cclnamemc
		i_address.postal_address.region,	-- ccaddr1
		i_address.postal_address.district,	-- ccaddr2
		NVL( i_address.postal_address.apptno, ' ' ),	-- ccaddr3
		i_address.postal_address.city,	-- cccity
		i_address.postal_address.zip,	-- cczip
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
		i_address.contact_person_name,	-- ccjobdesc
		NULL,			-- ccdeftrk
		'X',			-- ccuser
		DECODE( i_address.address_type,	'C', '', 'X' ),	-- ccbill
		DECODE( i_address.address_type,	'C', '', 'X' ),	-- ccbilldetails
		DECODE( i_address.address_type,	'B', '', 'X' ),	-- cccontract
		'X',			-- ccship
		NULL,			-- ccmagazine
		NULL,			-- ccdirectory
		NULL,			-- ccforward
		NULL,			-- ccurgent
		v_country_id,		-- country_id
		v_lng_id,		-- cclanguage
		NULL,			-- ccadditional
		v_sort_criteria,	-- sort_criteria
		TRUNC( SYSDATE ),	-- ccentdate
		TRUNC( SYSDATE ),	-- ccmoddate
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
*/


EXCEPTION
	WHEN	same_address
	THEN
		RAISE_APPLICATION_ERROR( -20002, 'Address is the same' );
END	set_address;

MEMBER	FUNCTION address
	(
	i_address_type	IN VARCHAR2
	)
RETURN	address_t
IS
	my_address	creator.address_t := creator.address_t
						(
						NULL,
						NULL,
						NULL,
						NULL
						);
BEGIN

	my_address.init ( SELF.customer_id, i_address_type );

	RETURN	my_address;
		
END	address;

MEMBER	FUNCTION custcode
RETURN	VARCHAR2
IS
	
	v_custcode	customer_all.custcode%TYPE;

BEGIN

	SELECT	custcode
	INTO	v_custcode
	FROM	customer_all
	WHERE	customer_id = SELF.customer_id;

	RETURN	v_custcode;

EXCEPTION
	WHEN	NO_DATA_FOUND
	THEN
		RAISE;
END	custcode;

MEMBER	FUNCTION prgcode
RETURN	VARCHAR2
IS

	v_prgcode	customer_all.prgcode%TYPE;

BEGIN

	SELECT	prgcode
	INTO	v_prgcode
	FROM	customer_all
	WHERE	customer_id = SELF.customer_id;
EXCEPTION
	WHEN	NO_DATA_FOUND
	THEN
		RAISE;
END	prgcode;

END;
/
SHOW ERROR