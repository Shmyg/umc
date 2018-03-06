CREATE	OR REPLACE
TYPE	&owner..contr_service_t

/*
|| Object describing contracted service
|| Created by Shmyg
|| Last modified by Shmyg 16.10.2002
*/

AS	OBJECT
	(
	co_id		NUMBER,
	seqno		NUMBER,
	status		VARCHAR2(1),
	pending_state	VARCHAR2(8),
	request		NUMBER,
	prm_value_id	NUMBER,
	service		service_t,

	-- Constructor - creates instance of contracted service and
	-- populates it with relevant data from DB
	MEMBER	PROCEDURE init
		(
		i_co_id		IN NUMBER,
		i_sncode	IN NUMBER
		),

	-- Procedure to set market parameters needed for the service.
	-- Needed parameters should be retreived from service_t object
	-- with corresponding sncode
	MEMBER	PROCEDURE set_mkt_parameter
		(
		i_mkt_parameters	IN mkt_parameters_tab
		),
	
	-- Procedure to set phone number parameters for bearer service
	-- Service type can be checked by service_t.is_bearer_service
	-- function
	MEMBER	PROCEDURE set_dn_parameter
		(
		i_dn_parameter		IN dn_parameter_t
		)
	);

/
SHOW ERROR
