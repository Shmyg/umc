CREATE	OR REPLACE
TYPE	BODY &owner..mail_label_t
AS
MEMBER	PROCEDURE create_
	(
	i_customer_name		IN creator.customer_name_t,
	i_postal_address	IN creator.postal_address_t
	)
IS
	v_country	VARCHAR2(40);
BEGIN

	SELF.line1 := i_customer_name.last_name;

	SELF.line2 := i_customer_name.first_name || ' '
		|| i_customer_name.middle_name;

	IF	i_postal_address.apptno IS NOT NULL
	THEN
		SELF.line3 := i_postal_address.street || ',  ' ||
			i_postal_address.streetno || ', ' ||
			i_postal_address.apptno;
	ELSE
		SELF.line3 := i_postal_address.street || ', ' ||
			i_postal_address.streetno;
	END	IF;

	IF	i_postal_address.region IS NOT NULL
	THEN
		SELF.line4 := i_postal_address.region || ', ' ||
			i_postal_address.district;
	END	IF;

	SELF.line5 := i_postal_address.zip || ' ' ||
		i_postal_address.city;

	SELF.line6 := v_country;


END	create_;
END;
/
SHOW ERROR