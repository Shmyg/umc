CREATE	OR REPLACE
TYPE	&owner..mkt_parameter_t
/*
|| Object describing market parameter
|| Created by Shmyg
|| Last modified by Shmyg 16.10.2002
*/
AS	OBJECT
	(
	parameter_id		NUMBER,
	prm_no			NUMBER,
	data_type		VARCHAR2(8),
	prm_type		VARCHAR2(8),
	prm_value		VARCHAR2(100),	-- default value

	-- Constructor - creates mkt_parameter instance and populates it
	-- with data from DB
	MEMBER	PROCEDURE init
		(
		i_parameter_id	IN NUMBER,
		i_sccode	IN NUMBER DEFAULT 1
		),
	
	-- Procedure to set parameter value 'cause it cannot be set explicitly
	MEMBER	PROCEDURE set_prm_value
		(
		i_prm_value	IN VARCHAR2
		)
	);
/
SHOW ERROR