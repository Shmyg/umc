CREATE	OR REPLACE
TYPE	BODY &owner..dn_parameter_t
AS

MEMBER	PROCEDURE init
	(
	i_dn_id		IN NUMBER
	)
AS
	CURSOR	dn_cur
		(
		p_dn_id	NUMBER
		)
	IS
	SELECT	dn_id,
		dn_num,
		dn_status
	FROM	directory_number
	WHERE	dn_id = p_dn_id;

	non_existing_phone	EXCEPTION;
BEGIN
	OPEN	dn_cur( i_dn_id );

		FETCH	dn_cur
		INTO	SELF.dn_id,
			SELF.dn_num,
			SELF.status;

		IF	dn_cur%NOTFOUND
		THEN
			RAISE	non_existing_phone;
		END	IF;
EXCEPTION
	WHEN	non_existing_phone
	THEN
		RAISE_APPLICATION_ERROR( -20001, 'No such phone number!' );
END	init;

MEMBER	PROCEDURE init
	(
	i_dn_num	IN VARCHAR2
	)
AS
	CURSOR	dn_cur
		(
		p_dn_num	NUMBER
		)
	IS
	SELECT	dn_id,
		dn_num,
		dn_status
	FROM	directory_number
	WHERE	dn_num = p_dn_num;

	non_existing_phone	EXCEPTION;
BEGIN
	OPEN	dn_cur( i_dn_num );

		FETCH	dn_cur
		INTO	SELF.dn_id,
			SELF.dn_num,
			SELF.status;

		IF	dn_cur%NOTFOUND
		THEN
			RAISE	non_existing_phone;
		END	IF;
EXCEPTION
	WHEN	non_existing_phone
	THEN
		RAISE_APPLICATION_ERROR( -20001, 'No such phone number!' );

END	init;
END;
/
SHOW ERROR