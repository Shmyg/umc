CREATE	OR REPLACE
TYPE	&owner..phone_t
AS	OBJECT
	(
	area_code	VARCHAR2(10),
	phone_num	VARCHAR2(25)
	)
/

SHOW ERROR