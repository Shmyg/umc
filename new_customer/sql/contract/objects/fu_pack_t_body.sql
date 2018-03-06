CREATE	OR REPLACE
TYPE	BODY &owner..fu_pack_t
AS
MEMBER	PROCEDURE init
	(
	i_fu_pack_id	IN NUMBER
	)
AS
	CURSOR	fu_pack_cur
	IS
	SELECT	fu_pack_id,
		long_name,
		assignment_level
	FROM	fu_pack
	WHERE	fu_pack_id = i_fu_pack_id;

	non_existing_fup	EXCEPTION;

BEGIN
	OPEN	fu_pack_cur;

		FETCH	fu_pack_cur
		INTO	SELF.fu_pack_id,
			SELF.long_name,
			SELF.assignment_level;

		IF	fu_pack_cur%NOTFOUND
		THEN
			CLOSE	fu_pack_cur;
			RAISE	non_existing_fup;
		END	IF;

	CLOSE	fu_pack_cur;
EXCEPTION
	WHEN	non_existing_fup
	THEN
		RAISE_APPLICATION_ERROR( -20001, 'No such FUP!' );
		--SELF.fu_pack_id := -1;
END	init;
END;
/

SHOW ERROR