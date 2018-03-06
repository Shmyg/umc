CREATE	OR REPLACE
TYPE	BODY &owner..service_t
AS

-- Constructor
MEMBER	PROCEDURE init
	(
	i_sncode	IN NUMBER,
	i_sccode	IN NUMBER DEFAULT 1	-- market. Default is GSM
	)
IS

	-- Cursor for service data
	CURSOR	service_cur
	IS
	SELECT	sn.sncode,
		sn.des,
		sn.snind,
		lk.srv_type
	FROM	mpusntab	sn,
		mpulknxv	lk
	WHERE	lk.sncode(+) = sn.sncode
	AND	sn.sncode = i_sncode;

	service_not_found	EXCEPTION;

BEGIN
	OPEN	service_cur;

		FETCH	service_cur
		INTO	SELF.sncode,
			SELF.des,
			SELF.is_net_service,
			SELF.service_type;

		IF	service_cur%NOTFOUND
		THEN
			RAISE	service_not_found;
		END	IF;

	CLOSE	service_cur;

EXCEPTION
	WHEN	service_not_found
	THEN
		RAISE_APPLICATION_ERROR( -20001, 'No such service' );
		-- SELF.sncode := -1;
END	init;

MEMBER	FUNCTION needs_request
RETURN	BOOLEAN
IS
	CURSOR	service_cur
	IS
	SELECT	snmml
	FROM	mpulknxv
	WHERE	sncode = SELF.sncode;

	v_snmml		VARCHAR2(1);
	v_result	BOOLEAN;
BEGIN
	OPEN	service_cur;
		FETCH	service_cur
		INTO	v_snmml;
	CLOSE	service_cur;

	IF	v_snmml = 'Y'
	THEN
		v_result := TRUE;
	ELSE
		v_result := FALSE;
	END	IF;

	RETURN	v_result;
END	needs_request;

-- Bearer services don't have exact criteria to distinguish them from 
-- ordinary ones. For this reason I simply placed this sncodes in package
MEMBER	FUNCTION is_bearer_service
RETURN	BOOLEAN
IS
	v_result	BOOLEAN := FALSE;
BEGIN
	IF	(
		SELF.sncode = creator.global_vars.c_gsm_sncode
		OR
		SELF.sncode = creator.global_vars.c_nmt_sncode
		OR
		SELF.sncode = creator.global_vars.c_fax_sncode
		OR
		SELF.sncode = creator.global_vars.c_data_sncode
		)
	THEN
		v_result := TRUE;
	END	IF;

	RETURN	v_result;

END	is_bearer_service;

-- Same as for bearer services
MEMBER	FUNCTION is_fup_service
RETURN	BOOLEAN
IS
	v_result	BOOLEAN := FALSE;
BEGIN
	IF	SELF.sncode = creator.global_vars.c_fup_sncode
	THEN
		v_result := TRUE;
	END	IF;

	RETURN	v_result;
END	is_fup_service;

MEMBER	FUNCTION needed_parameters
	(
	i_sccode	IN NUMBER DEFAULT 1
	)
RETURN	parameters_tab
AS
	-- Cursor for service parameter and market parameters data
	-- Parameters can be stored in sscode, s1code and s2code
	CURSOR	prm_cur
		(
		p_sncode	NUMBER,
		p_sccode	NUMBER
		)
	IS
	SELECT	sp.svcode
	FROM	mpulknxv		lk,
		mpssvtab		sv,
		service_parameter	sp
	WHERE	lk.sncode = p_sncode
	AND	lk.sscode = sv.svcode
	AND	sp.svcode = sv.svcode
	AND	sp.sccode = p_sccode
	UNION
	SELECT	sp.svcode
	FROM	mpulknxv		lk,
		mpssvtab		sv,
		service_parameter	sp
	WHERE	lk.sncode = p_sncode
	AND	lk.s1code = sv.svcode
	AND	sp.svcode = sv.svcode
	AND	sp.sccode = p_sccode
	UNION
	SELECT	sp.svcode
	FROM	mpulknxv		lk,
		mpssvtab		sv,
		service_parameter	sp
	WHERE	lk.sncode = p_sncode
	AND	lk.s2code = sv.svcode
	AND	sp.svcode = sv.svcode
	AND	sp.sccode = p_sccode;

	v_needed_parameters	parameters_tab;

BEGIN
	OPEN	prm_cur
		(
		SELF.sncode,
		i_sccode
		);

		FETCH	prm_cur
		BULK	COLLECT
		INTO	v_needed_parameters;
	
	CLOSE	prm_cur;

	RETURN	v_needed_parameters;

END	needed_parameters;

MEMBER	FUNCTION mkt_parameters
	(
	i_sccode	NUMBER DEFAULT 1
	)
RETURN	mkt_parameters_tab
AS
	-- All the market parameters for definite service parameter
	CURSOR	parameter_cur
		(
		p_svcode	NUMBER
		)
	IS
	SELECT	parameter_id
	FROM	service_parameter
	WHERE	svcode = p_svcode
	AND	sccode = i_sccode;

	v_mkt_parameter		mkt_parameter_t := mkt_parameter_t
							(
							NULL,
							NULL,
							NULL,
							NULL,
							NULL
							);

	v_mkt_parameters	mkt_parameters_tab := mkt_parameters_tab
							(
							v_mkt_parameter
							);

	i		PLS_INTEGER := 1;
	j		PLS_INTEGER := 1;
	v_parameter_id	PLS_INTEGER;

	v_needed_parameters	parameters_tab := parameters_tab();

BEGIN

	-- Looking for service parameters needed
	v_needed_parameters := SELF.needed_parameters;

	IF	v_needed_parameters.COUNT > 0	-- there are some
	THEN
		FOR	i IN v_needed_parameters.FIRST..v_needed_parameters.COUNT
		LOOP
			-- Looking for market parameters for each service
			-- parameter
			OPEN	parameter_cur( v_needed_parameters(i));
			LOOP
				FETCH	parameter_cur
				INTO	v_parameter_id;

				EXIT	WHEN parameter_cur%NOTFOUND;

				v_mkt_parameter.init( v_parameter_id );
				v_mkt_parameters(j) := v_mkt_parameter;
				v_mkt_parameters.EXTEND;
				j := j + 1;

			END	LOOP;
			CLOSE	parameter_cur;
		END	LOOP;
	END	IF;
	
	-- Trimming last empty cell in the table
	v_mkt_parameters.TRIM;

	RETURN	v_mkt_parameters;

END	mkt_parameters;

END;
/
SHOW ERROR
