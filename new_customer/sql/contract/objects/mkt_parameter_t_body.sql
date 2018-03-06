CREATE	OR REPLACE
TYPE	BODY &owner..mkt_parameter_t
AS

MEMBER	PROCEDURE init
	(
	i_parameter_id	IN NUMBER,
	i_sccode	IN NUMBER DEFAULT 1
	)
AS
	-- All the parameters data
	CURSOR	parameter_cur
	IS
	SELECT	mp.parameter_id,
		pa.parameter_area_id,
		sp.prm_no,
		DECODE	(
			dt.data_type_code,	'CHAR', 'VARCHAR',
						'NUMB', 'NUMBER',
						'VARCHAR'
			),
		-- Parameter types can be retreived from comments for this table
		DECODE	(
			pt.parameter_type_id,	1, 'DF',
						2, 'CB',
						3, 'CX'
			)
	FROM	mkt_parameter	mp,
		parameter_area	pa,
		data_type	dt,
		parameter_type	pt,
		service_parameter	sp
	WHERE	mp.parameter_area_id = pa.parameter_area_id
	AND	pa.parameter_type_id = pt.parameter_type_id
	AND	pa.data_type_id = dt.data_type_id
	AND	sp.parameter_id = i_parameter_id
	AND	sp.sccode = i_sccode
	AND	mp.parameter_id = i_parameter_id;

	v_parameter_area_id	parameter_area.parameter_area_id%TYPE;

	-- Names of tables to retreive parameter values depending on
	-- parameter_type_id
	c_mkt_parameter_domain	CONSTANT NUMBER := 9;
	c_mkt_parameter_range	CONSTANT NUMBER := 4;

	-- Cursor for parameter value. Depends on parameter_area_id
	TYPE	prm_value_cur_type
	IS	REF CURSOR;

	prm_value_cur	prm_value_cur_type;

BEGIN

	OPEN	parameter_cur;
	
		FETCH	parameter_cur
		INTO	SELF.parameter_id,
			v_parameter_area_id,
			SELF.prm_no,
			SELF.data_type,
			SELF.prm_type;

		-- Looking for default parameter value
		-- here table name to retreive data from and data type of
		-- variable depends on parameter_area_id column
		IF	v_parameter_area_id = c_mkt_parameter_range
		THEN
			OPEN	prm_value_cur
			FOR
			SELECT	prm_default
			FROM	mkt_parameter_range
			WHERE	parameter_id = i_parameter_id
			AND	sccode = i_sccode;
			
				FETCH	prm_value_cur
				INTO	SELF.prm_value;

			CLOSE	prm_value_cur;

		ELSIF	v_parameter_area_id = c_mkt_parameter_domain
		THEN
			OPEN	prm_value_cur
			FOR
			SELECT	TO_CHAR( prm_value_seqno )
			FROM	mkt_parameter_domain
			WHERE	parameter_id = i_parameter_id
			AND	sccode = i_sccode
			AND	prm_value_def = 'X';

				FETCH	prm_value_cur
				INTO	SELF.prm_value;

			CLOSE	prm_value_cur;
		END	IF;

	CLOSE	parameter_cur;

END	init;

MEMBER	PROCEDURE set_prm_value
	(
	i_prm_value	IN VARCHAR2
	)
AS
BEGIN

	SELF.prm_value := i_prm_value;

END	set_prm_value;
END;
/
SHOW ERROR