CREATE	OR REPLACE
TYPE	&owner..customer_t
AS	OBJECT
	(
	passport	VARCHAR2(30),
	customer_id	NUMBER,

	MAP
	MEMBER	FUNCTION get_customer_id
	RETURN	NUMBER,

	MEMBER	PROCEDURE init
		(
		i_passportno	IN VARCHAR2
		),

	MEMBER	PROCEDURE set_address
		(
		i_address	creator.address_t
		),

	MEMBER	FUNCTION address
		(
		i_address_type	IN VARCHAR2
		)
	RETURN	address_t,

	MEMBER	FUNCTION custcode
	RETURN	VARCHAR2,

	MEMBER	FUNCTION prgcode
	RETURN	VARCHAR2

	)
/
SHOW ERROR
