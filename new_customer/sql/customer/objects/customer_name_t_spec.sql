CREATE	OR REPLACE
TYPE	customer_name_t
AS	OBJECT
	(
	first_name	VARCHAR2(40),
	middle_name	VARCHAR2(40),
	last_name	VARCHAR2(40),

	MEMBER	PROCEDURE check_name,

	MEMBER	FUNCTION match_criteria
	RETURN	VARCHAR2
	)
/

SHOW ERROR