CREATE	OR REPLACE
TYPE	BODY &owner..customer_name_t
AS
MEMBER	PROCEDURE check_name
AS
BEGIN
	NULL;
END	check_name;

MEMBER	FUNCTION match_criteria
RETURN	VARCHAR2
AS
BEGIN
	NULL;
END	match_criteria;
END;
/

SHOW ERROR