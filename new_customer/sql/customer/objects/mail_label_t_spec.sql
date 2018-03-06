CREATE	OR REPLACE
TYPE	&owner..mail_label_t
AS	OBJECT
	(
	line1	VARCHAR2(120),
	line2	VARCHAR2(120),
	line3	VARCHAR2(120),
	line4	VARCHAR2(120),
	line5	VARCHAR2(120),
	line6	VARCHAR2(120),

	MEMBER	PROCEDURE create_
		(
		i_customer_name		IN creator.customer_name_t,
		i_postal_address	IN creator.postal_address_t
		)
	)
/
SHOW ERROR