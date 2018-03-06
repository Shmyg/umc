CREATE	OR REPLACE
TYPE	BODY &owner..parameter_t
AS

MEMBER	FUNCTION next_value
RETURN	NUMBER
AS
	CURSOR	prm_cur
	IS
	SELECT	next_free_value
	FROM	app_sequence_value
	WHERE	app_sequence_id =
		(
		SELECT	app_sequence_id
		FROM	app_sequence
		WHERE	app_sequence_key = SELF.prm_name
		)
	FOR	UPDATE;	

	v_next_value		NUMBER;

	non_existing_parameter	EXCEPTION;
BEGIN
	OPEN	prm_cur;

		FETCH	prm_cur
		INTO	v_next_value;

		IF	prm_cur%NOTFOUND
		THEN
			CLOSE	prm_cur;
			RAISE	non_existing_parameter;
		END	IF;

		UPDATE	app_sequence_value
		SET	next_free_value = v_next_value + 1
		WHERE	CURRENT OF prm_cur;

	CLOSE	prm_cur;

	RETURN	v_next_value;

EXCEPTION
	WHEN	non_existing_parameter
	THEN
		RAISE_APPLICATION_ERROR( -20001, 'No such parameter!' );
	WHEN	OTHERS
	THEN
		RAISE;
END	next_value;
END;
/
SHOW ERROR