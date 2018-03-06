CREATE	OR REPLACE
TYPE	&owner..fu_pack_t
/*
|| Object for free units package entity
|| Created by Shmyg
|| Last modified 16.10.2002
*/ 
AS	OBJECT
	(
	fu_pack_id		NUMBER,
	long_name		VARCHAR2(30),
	assignment_level	VARCHAR2(1),

	-- Constructor
	MEMBER	PROCEDURE init
		(
		i_fu_pack_id	IN NUMBER
		)
	);
/

SHOW ERROR
