CREATE	OR REPLACE
PACKAGE	&owner..umc_contract
AS

/*
Package for contract management
Created by Shmyg
Last modified by Shmyg 20.11.2002
*/

/*
Contents:

assign_service - function for service assigning. Returns 0 in case of success
and negative number corresponding to error number in case of any failure

Possible call modes:
spcode is not null - function assigns all the services belonging to spcode
except service which need directory numbers (12, 19, 30, 140)
spcode is null - function assigns only sncode passed.
If either of parameters is null, an error is raised
For services which need directory number this function must be called
separately for each service with dn_id passed. If dn_id is not passed, an error
is raised.

CRUD Matrix for assign_service
--+---------------------------------+---+---+---+---+---+----------------------+
--| OBJECT                          |SEL|INS|UPD|DEL|CRE|OTHER                 |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MPULKPXN                        | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CONTR_SERVICES                  | X | X |   |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MPULKNXV                        | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CONTR_SERVICES_CAP              | X | X | X |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CONTRACT_HISTORY                |   |   |   |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MPUTMTAB                        | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| DIRECTORY_NUMBER                | X |   | X |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CONTRACT_ALL                    | X |   | X |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+

create_contract - function to create contract
Creates new contract, assigns all core services to it and makes all contract
devices (port, directory number, SIM-card) active
In case of success returns co_id, else - negative number of corresponding error

-- CRUD Matrix for create_contract
--+---------------------------------+---+---+---+---+---+----------------------+
--| OBJECT                          |SEL|INS|UPD|DEL|CRE|OTHER                 |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CUSTOMER_ALL                    | X |   |   |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MPUTMTAB                        |   |   |   |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| STORAGE_MEDIUM                  | X |   | X |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| DIRECTORY_NUMBER                | X |   |   |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MPDSCTAB                        | X |   |   |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MPDPLTAB                        | X |   |   |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| SUB_MARKET                      | X |   |   |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MPULKTMB                        | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| APP_SEQUENCE_VALUE              | X |   | X |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| APP_SEQUENCE                    | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MPULKNXG                        | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| PORT                            | X |   | X |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MPDHMTAB                        | X |   |   |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| VALID_TMCODES                   | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CONTRACT_ALL                    |   | X |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CONTRACT_HISTORY                |   | X |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CONTR_TARIFF_OPTIONS            |   | X |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| RATEPLAN_HIST                   |   | X |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CONTR_DEVICES                   |   | X |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MPUFDTAB                        |   | X |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+


register_service - function for service registering (activation). Registers
(activates) service - inserts record in mdsrrtab. In case of success returns 0
or request number if request needs to be created, in case of failure - negative
number of corresponding error

-- CRUD Matrix for register service
--+---------------------------------+---+---+---+---+---+----------------------+
--| OBJECT                          |SEL|INS|UPD|DEL|CRE|OTHER                 |
--+---------------------------------+---+---+---+---+---+----------------------+
--| APP_SEQUENCE_VALUE              | X |   | X |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| APP_SEQUENCE                    | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CONTRACT_ALL                    | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| GMD_MPDSCTAB                    | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CONTR_SERVICES                  | X |   | X |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CONTR_DEVICES                   | X |   |   |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MPDHLTAB                        | X |   |   |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| GMD_REQUEST_BASE                |   | X |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MDSRRTAB                        |   | X |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| PARAMETER_VALUE                 | X |   | X |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MKT_PARAMETER_ACTION            | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MKT_GMD_LINK_ACTION             | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+

view_not_core_services - procedure to retreive all not core services which can 
be assigned to contract

-- CRUD Matrix view_not_core_services
--+---------------------------------+---+---+---+---+---+----------------------+
--| OBJECT                          |SEL|INS|UPD|DEL|CRE|OTHER                 |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MPUSNTAB                        | X |   |   |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MPULKTMB                        | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| VALID_TMCODES                   | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+

erase_service - function for service erasing (deactivation). Erases
(deactivates) service - inserts record in mdsrrtab. In case of success returns 0
or request number if request needs to be created, in case of failure - negative
number of corresponding error

-- CRUD Matrix for register service
--+---------------------------------+---+---+---+---+---+----------------------+
--| OBJECT                          |SEL|INS|UPD|DEL|CRE|OTHER                 |
--+---------------------------------+---+---+---+---+---+----------------------+
--| APP_SEQUENCE_VALUE              | X |   | X |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| APP_SEQUENCE                    | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CONTRACT_ALL                    | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| GMD_MPDSCTAB                    | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CONTR_SERVICES                  | X |   | X |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| CONTR_DEVICES                   | X |   |   |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MPDHLTAB                        | X |   |   |   |   |X                     |
--+---------------------------------+---+---+---+---+---+----------------------+
--| GMD_REQUEST_BASE                |   | X |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MDSRRTAB                        |   | X |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| PARAMETER_VALUE                 | X |   | X |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MKT_PARAMETER_ACTION            | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+
--| MKT_GMD_LINK_ACTION             | X |   |   |   |   |                      |
--+---------------------------------+---+---+---+---+---+----------------------+

init_service - procedure returing service data. Used in java objects
*/

TYPE	number_tab_type
IS	TABLE
OF	NUMBER
INDEX	BY BINARY_INTEGER;

TYPE	sncode_rec_type
IS	RECORD
	(
	sncode	NUMBER,
	des	VARCHAR2(30)
	);

TYPE	sncode_cur_type
IS	REF CURSOR
RETURN	sncode_rec_type;

FUNCTION	assign_service
	(
	i_co_id		IN NUMBER,
	i_spcode	IN NUMBER := NULL,
	i_sncode	IN NUMBER := NULL,
	i_dn_id		IN NUMBER := NULL,
	i_fup_id	IN NUMBER := NULL
	)
RETURN	NUMBER;

FUNCTION	create_contract
	(
	i_customer_id	IN customer_all.customer_id%TYPE,
	i_tmcode	IN mputmtab.tmcode%TYPE,
	i_sm_serialnum	IN storage_medium.sm_serialnum%TYPE,
	i_dn_num	IN directory_number.dn_num%TYPE
	)
RETURN	NUMBER;

FUNCTION	register_service
	(
	i_co_id		IN NUMBER,
	i_sncode	IN NUMBER
	)
RETURN	NUMBER;

PROCEDURE	view_not_core_services
	(
	i_tmcode	IN NUMBER,
	o_sncode_cur	IN OUT sncode_cur_type
	);
PRAGMA	RESTRICT_REFERENCES ( view_not_core_services, WNDS, RNPS, WNPS );

FUNCTION	erase_service
	(
	i_co_id		IN NUMBER,
	i_sncode	IN NUMBER
	)
RETURN	NUMBER;

PROCEDURE	init_service
	(
	i_sncode	IN NUMBER,
	i_sccode	IN NUMBER DEFAULT 1,
	o_des		OUT VARCHAR,
	o_net_service	OUT VARCHAR,
	o_service_type	OUT VARCHAR
	);

END	umc_contract;
/

SHOW ERRORS