CREATE OR REPLACE
TYPE	&owner..postal_address_t
AS	OBJECT
	(
	zip		VARCHAR2(15),
	region		VARCHAR2(40),	-- ccaddr1
	district	VARCHAR2(40),	-- ccaddr2
	city		VARCHAR2(40),
	street		VARCHAR2(40),
	streetno	VARCHAR2(15),
	apptno		VARCHAR2(40)	-- ccaddr3
	)
/
SHOW ERROR