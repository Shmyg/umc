CREATE	OR REPLACE
TYPE	&owner..parameter_t
/*
|| Type describing parameter for miscellaneous internal keys
|| Created by Shmyg
|| Last modified by Shmyg 16.10.2002
*/
AS	OBJECT
	(
	prm_name	VARCHAR2(22),

	-- Function for retreiving next value
	-- Should be used with care 'cause it locks table with parameter values
	MEMBER	FUNCTION next_value
	RETURN	NUMBER
	);
/
SHOW ERROR