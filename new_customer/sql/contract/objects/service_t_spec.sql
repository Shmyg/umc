CREATE	OR REPLACE
TYPE	&owner..service_t
/*
|| Object describing service
|| Created by Shmyg
|| Last modified by Shmyg 16.10.2002
*/
AS	OBJECT
	(
	sncode			NUMBER,
	des			VARCHAR2(30),
	is_net_service		VARCHAR2(1),
	service_type		VARCHAR2(1),

	-- Constructor - creates service instance and populates it with data
	-- from DB
	MEMBER	PROCEDURE init
		(
		i_sncode	IN NUMBER,
		i_sccode	IN NUMBER DEFAULT 1
		),

	-- Function for check if service is bearer one and needs some data to
	-- be inserted in contr_services_cap
	MEMBER	FUNCTION is_bearer_service
	RETURN	BOOLEAN,
	PRAGMA	RESTRICT_REFERENCES ( is_bearer_service, WNPS, RNPS, WNPS, TRUST ),

	-- Function for check if service is fup one. In this case service
	-- handling (e.g. assignment) has some differences
	MEMBER	FUNCTION is_fup_service
	RETURN	BOOLEAN,
	PRAGMA	RESTRICT_REFERENCES ( is_fup_service, WNPS, RNPS, WNPS, TRUST ),

	-- Function returning parameters needed for service (if any)
	MEMBER	FUNCTION needed_parameters
		(
		i_sccode	IN NUMBER DEFAULT 1
		)
	RETURN	parameters_tab,
	PRAGMA	RESTRICT_REFERENCES ( needed_parameters, WNPS, RNPS, WNPS ),

	-- Function for check if service needs request to be created
	MEMBER	FUNCTION needs_request
	RETURN	BOOLEAN,
	PRAGMA	RESTRICT_REFERENCES ( needs_request, WNPS, RNPS, WNPS ),

	-- Returns market parameters needed for service (related to
	-- needed_parameters)
	MEMBER	FUNCTION mkt_parameters
		(
		i_sccode	NUMBER DEFAULT 1
		)
	RETURN	mkt_parameters_tab
	);
/
SHOW ERROR
