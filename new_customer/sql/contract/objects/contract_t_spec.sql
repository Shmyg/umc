CREATE	OR REPLACE
TYPE	&owner..contract_t

/*
|| Object contract
|| Created by Shmyg
|| Last modified by Shmyg 16.10.2002
*/

AS	OBJECT
	(
	co_id		NUMBER,
	customer_id	NUMBER,
	tmcode		NUMBER,
	phone_num	VARCHAR2(63),
	sim_card	VARCHAR2(50),
	services	contr_services_tab,

	MAP
	MEMBER	FUNCTION get_co_id
	RETURN	NUMBER,

	-- Procedure for contract creation
	-- Creates contract with instance parameters
	MEMBER	PROCEDURE create_me,

	-- Constructors - populate object instance with data from DB
	MEMBER	PROCEDURE init
		(
		i_co_id		IN NUMBER
		),
	MEMBER	PROCEDURE init
		(
		i_dn_num	IN VARCHAR2
		),

	-- Functions for service assigning
	MEMBER	PROCEDURE assign_service
		(
		i_sncode	IN NUMBER
		),
	MEMBER	PROCEDURE assign_service
		(
		i_service	IN creator.service_t
		),

	-- Functions for service erasing
	MEMBER	PROCEDURE erase_service
		(
		i_sncode	IN NUMBER,
		o_request	OUT NUMBER
		),
	MEMBER	PROCEDURE erase_service
		(
		i_service	IN creator.service_t,
		o_request	OUT NUMBER
		),

	-- Functions for service registering
	MEMBER	PROCEDURE register_service
		(
		i_sncode	IN NUMBER,
		o_request	OUT NUMBER
		),
	MEMBER	PROCEDURE register_service
		(
		i_service	IN creator.service_t,
		o_request	OUT NUMBER
		),

	-- Function returning current contract status for some date
	-- If date is not passed, returns current status
	MEMBER	FUNCTION status
		(
		i_date	IN DATE := SYSDATE
		)
	RETURN	VARCHAR2,
	PRAGMA	RESTRICT_REFERENCES ( status, WNPS, RNPS, WNPS ),

	-- Function returning suspension time in days
	-- If parameters are not passed, returns suspension time from
	-- first contract activation up to sysdate
	MEMBER	FUNCTION suspension_time
		(
		i_from_date	DATE := NULL,
		i_to_date	DATE := NULL
		)
	RETURN	NUMBER,
	PRAGMA	RESTRICT_REFERENCES( suspension_time, WNPS, RNPS, WNPS ),

	-- Functions for check if contract has pending request not for some
	-- definite service but for all the services (e.g. contract should
	-- suspended or reactivated etc)
	-- If it does - returns true, else - false
	MEMBER	FUNCTION has_pending_request
	RETURN	BOOLEAN,
	PRAGMA	RESTRICT_REFERENCES( has_pending_request, WNPS, RNPS, WNPS ),

	MEMBER	FUNCTION has_pending_request
		(
		i_co_id	NUMBER
		)
	RETURN	BOOLEAN,
	PRAGMA	RESTRICT_REFERENCES( has_pending_request, WNPS, RNPS, WNPS )

	);

/
SHOW ERROR
