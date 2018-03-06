CREATE	OR REPLACE
TYPE	&owner..dn_parameter_t
/*
Type describing phone number entity
Created by Shmyg
Last modified 15.10.2002
*/
AS	OBJECT
	(
	dn_id		NUMBER,
	dn_num		VARCHAR2(63),
	status		VARCHAR(1),
	main_dirnum	VARCHAR2(1),

	-- Constructors
	MEMBER	PROCEDURE init
		(
		i_dn_id		IN NUMBER
		),

	MEMBER	PROCEDURE init
		(
		i_dn_num	IN VARCHAR2
		)
	);
/
SHOW ERROR