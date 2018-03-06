CREATE	OR REPLACE
TYPE	&owner..address_t
AS	OBJECT
	(
	customer_id	NUMBER,
	address_type	VARCHAR2(1),
	customer_name	creator.customer_name_t,
	postal_address	creator.postal_address_t,

	MAP
	MEMBER	FUNCTION get_address
	RETURN	NUMBER,

	MEMBER	FUNCTION mail_label
	RETURN	mail_label_t,

	MEMBER	FUNCTION phones
	RETURN	phones_tab,

	MEMBER	PROCEDURE init
		(
		i_customer_id	IN NUMBER,
		i_address_type	IN VARCHAR2
		)
	)
/

SHOW ERROR