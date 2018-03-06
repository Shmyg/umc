CREATE	OR REPLACE
TYPE	BODY &owner..address_t
AS

MAP
MEMBER	FUNCTION get_address
RETURN	NUMBER
AS
BEGIN
	RETURN	0;
END	get_address;

MEMBER	FUNCTION mail_label
RETURN	mail_label_t
AS
BEGIN
	NULL;
END	mail_label;

MEMBER	FUNCTION phones
RETURN	phones_tab
AS
BEGIN
	NULL;
END	phones;

MEMBER	PROCEDURE init
	(
	i_customer_id	IN NUMBER,
	i_address_type	IN VARCHAR2
	)
IS

	CURSOR	address_cur
		(
		p_customer_id	NUMBER,
		p_address_type	VARCHAR2
		)
	IS
	SELECT	ccname,
		ccfname,
		cclname,
		ccstreet,
		ccstreetno,
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
		ccemail
	WHERE	customer_id = p_customer_id
	AND	

	wrong_address_type	EXCEPTION;

BEGIN

	IF	i_address_type = 'B'
	THEN
		SELECT	DISTINCT customer_id
		INTO	SELF.customer_id
		FROM	ccontact_all
		WHERE	customer_id = i_customer_id
		AND	ccbill = 'X';
	ELSIF	i_address_type = 'C'
	THEN
		SELECT	DISTINCT customer_id
		INTO	SELF.customer_id
		FROM	ccontact_all
		WHERE	customer_id = i_customer_id
		AND	cccontract = 'X';
	ELSE
		RAISE	wrong_address_type;
	END	IF;

EXCEPTION
	WHEN	wrong_address_type
	THEN
		RAISE_APPLICATION_ERROR( -20001, 'Wrong address type' );
	WHEN	NO_DATA_FOUND
	THEN
		RAISE;
	WHEN	OTHERS
	THEN
		RAISE;
END	init;

END;
/
SHOW ERROR