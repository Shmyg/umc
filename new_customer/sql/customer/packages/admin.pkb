CREATE	OR REPLACE
PACKAGE	BODY &owner..admin
AS
PROCEDURE	log_error
	(
	i_sqlcode	IN NUMBER,
	i_sqlerrm	IN VARCHAR2
	)
AS
	PRAGMA	AUTONOMOUS_TRANSACTION;
BEGIN

	INSERT	INTO error_log
		(
		sql_code,
		sql_errm,
		sql_date,
		sql_user
		)
	VALUES	(
		i_sqlcode,
		i_sqlerrm,
		SYSDATE,
		USER
		);
	COMMIT;
END	log_error;
END	admin;
/
SHOW ERROR