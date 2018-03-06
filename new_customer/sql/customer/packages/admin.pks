CREATE	OR REPLACE
PACKAGE	&owner..admin
AS
	PROCEDURE	log_error
		(
		i_sqlcode	IN NUMBER,
		i_sqlerrm	IN VARCHAR2
		);
END;
/
SHOW ERROR