CREATE	OR REPLACE
PACKAGE	BODY &owner..penadmin
AS

	g_username	VARCHAR2(20) := USER;

PROCEDURE	add_pendefinitions
	(
	i_penalty_tab	IN OUT NOCOPY penalty_tab_type,
	o_result	OUT NUMBER
	)
IS
	i		BINARY_INTEGER;
	v_pencode	NUMBER;
BEGIN
	FOR	i IN i_penalty_tab.FIRST..i_penalty_tab.LAST
	LOOP
		SELECT	NVL( MAX( pencode ), 0 )  + 1
		INTO	v_pencode
		FROM	penalties_setup;

		i_penalty_tab(i).pencode := v_pencode;

		INSERT	INTO penalties_setup
			(
			pencode,
			atcode ,
			pentype_id,
			pen_des,
			username,
			enabled,
			calc_method_id,
			fx_amt,
			c1,
			c2,
			c3,
			service_param,
			entdate
			)
		VALUES	(
			v_pencode,
			i_penalty_tab(i).atcode,
			i_penalty_tab(i).pentype_id,
			i_penalty_tab(i).pen_des,
			g_username,
			i_penalty_tab(i).enabled,
   			i_penalty_tab(i).calc_method_id,
			i_penalty_tab(i).fx_amt,
			i_penalty_tab(i).c1,
			i_penalty_tab(i).c2,
			i_penalty_tab(i).c3,
			i_penalty_tab(i).service_param,
			TRUNC( SYSDATE )
			);
	END	LOOP;

	o_result := 0;
/*
EXCEPTION
	WHEN	OTHERS
	THEN
		o_result := -1;
		RETURN;
*/
END	add_pendefinitions;

PROCEDURE	lock_pendefinitions
	(
	i_penalty_tab	IN OUT NOCOPY penalty_tab_type,
	o_result	OUT NUMBER
	)
IS
	v_atcode	penalties_setup.atcode%TYPE;
	i		BINARY_INTEGER;
BEGIN
	FOR	i IN i_penalty_tab.FIRST..i_penalty_tab.LAST
	LOOP
		SELECT	atcode
		INTO	v_atcode
		FROM	penalties_setup
		WHERE	pentype_id = i_penalty_tab(i).pentype_id
		FOR	UPDATE;
	END	LOOP;

	o_result := 0;

EXCEPTION
	WHEN	OTHERS
	THEN
		o_result := -2;
		RETURN;
END	lock_pendefinitions;

PROCEDURE	update_pendefinitions
	(
	i_penalty_tab	IN OUT NOCOPY penalty_tab_type,
	o_result	OUT NUMBER
	)
IS
	i	BINARY_INTEGER;
BEGIN
	FOR	i in i_penalty_tab.FIRST..i_penalty_tab.LAST
	LOOP
		UPDATE	penalties_setup
		SET	pencode = i_penalty_tab(i).pencode,
			atcode = i_penalty_tab(i).atcode,
			pentype_id = i_penalty_tab(i).pentype_id,
			pen_des = i_penalty_tab(i).pen_des,
			username = g_username,
			enabled = i_penalty_tab(i).enabled,
            calc_method_id = i_penalty_tab(i).calc_method_id,
			fx_amt = i_penalty_tab(i).fx_amt,
			c1 = i_penalty_tab(i).c1,
			c2 = i_penalty_tab(i).c2,
			c3 = i_penalty_tab(i).c3,
            service_param = i_penalty_tab(i).service_param
		WHERE	pencode = i_penalty_tab(i).pencode;
	END	LOOP;
	o_result := 0;
EXCEPTION
	WHEN	OTHERS
	THEN
		o_result := -3;
		RETURN;
END	update_pendefinitions;

PROCEDURE	view_pendefinitions
	(
	o_penalty_cur	IN OUT penalty_cur_type,
    o_atcode_param in out number
	)
IS
BEGIN
if o_atcode_param = 0 then
	OPEN	o_penalty_cur
	FOR
/*	SELECT	pencode,
		atcode ,
		pentype_id,
		pen_des,
		username,
		enabled,
        calc_method_id,
		fx_amt,
		c1,
		c2,
		c3,
        service_param
	FROM	penalties_setup */
    SELECT
        B.PENCODE , B.ATCODE , B.PENTYPE_ID , B.PEN_DES , B.USERNAME
      , B.ENABLED , B.CALC_METHOD_ID , B.FX_AMT , B.C2 , B.C1
      , B.C3 , B.SERVICE_PARAM , C.CALC_METHOD_DES , D.SHDES , D.LONGDES, E.PENTYPE_DES
    FROM
        PENALTIES_SETUP B,
        CALC_METHODS C,
        AGRTYPES D,
        PENTYPES E
    WHERE
        (B.CALC_METHOD_ID = C.CALC_METHOD_ID)
        AND (B.ATCODE = D.ATCODE)
        AND (B.PENTYPE_ID = E.PENTYPE_ID)
	ORDER	BY pencode;
else
	OPEN	o_penalty_cur
	FOR
        SELECT
        B.PENCODE , B.ATCODE , B.PENTYPE_ID , B.PEN_DES , B.USERNAME
      , B.ENABLED , B.CALC_METHOD_ID , B.FX_AMT , B.C2 , B.C1
      , B.C3 , B.SERVICE_PARAM , C.CALC_METHOD_DES , D.SHDES , D.LONGDES, E.PENTYPE_DES
    FROM
        PENALTIES_SETUP B,
        CALC_METHODS C,
        AGRTYPES D,
        PENTYPES E
    WHERE
        (B.CALC_METHOD_ID = C.CALC_METHOD_ID)
        AND (B.ATCODE = D.ATCODE)
        AND (B.PENTYPE_ID = E.PENTYPE_ID)
	    AND  b.atcode = o_atcode_param
	ORDER	BY pencode;

end if;

END	view_pendefinitions;

PROCEDURE	add_pentypes
	(
	i_pentype_tab	IN OUT NOCOPY pentype_tab_type,
	o_result	OUT NUMBER
	)
IS
	i		BINARY_INTEGER;
	v_reason_id	NUMBER;
BEGIN
	FOR	i IN i_pentype_tab.FIRST..i_pentype_tab.LAST
	LOOP
		SELECT	NVL( MAX( pentype_id ), 0 )  + 1
		INTO	v_reason_id
		FROM	pentypes;

		i_pentype_tab(i).pentype_id := v_reason_id;

		INSERT	INTO pentypes
			(
			pentype_id,
			pentype_des,
			event_id,
			ohinvtype,
			glacode,
			postbilling,
			username,
			entdate,
			check_criteria_id
			)
		VALUES	(
			v_reason_id,
			i_pentype_tab(i).pentype_des,
			i_pentype_tab(i).event_id,
			i_pentype_tab(i).ohinvtype,
			i_pentype_tab(i).glacode,
			i_pentype_tab(i).postbilling,
			g_username,
			TRUNC( SYSDATE ),
			i_pentype_tab(i).check_criteria_id
			);
	END	LOOP;
	o_result := 0;
EXCEPTION
	WHEN	OTHERS
	THEN
		o_result := -1;
		RETURN;
END	add_pentypes;

PROCEDURE	lock_pentypes
	(
	i_pentype_tab	IN OUT NOCOPY pentype_tab_type,
	o_result	OUT NUMBER
	)
IS
	v_pentype_des	pentypes.pentype_des%TYPE;
	i		BINARY_INTEGER;
BEGIN

null;
/*
	FOR	i IN i_pentype_tab.FIRST..i_pentype_tab.LAST
	LOOP
		SELECT	pentype_des
		INTO	v_pentype_des
		FROM	pentypes
		WHERE	pentype_id = i_pentype_tab(i).pentype_id
		FOR	UPDATE;
	END	LOOP;

	o_result := 0;
*/
EXCEPTION
	WHEN	OTHERS
	THEN
		o_result := -2;
		RETURN;
END	lock_pentypes;

PROCEDURE	update_pentypes
	(
	i_pentype_tab	IN OUT NOCOPY pentype_tab_type,
	o_result	OUT NUMBER
	)
IS
	i	BINARY_INTEGER;
BEGIN
	FOR	i in i_pentype_tab.FIRST..i_pentype_tab.LAST
	LOOP
		UPDATE	pentypes
		SET	pentype_des = i_pentype_tab(i).pentype_des,
			ohinvtype = i_pentype_tab(i).ohinvtype,
			event_id = i_pentype_tab(i).event_id,
			glacode = i_pentype_tab(i).glacode,
			postbilling = i_pentype_tab(i).postbilling,
			username = g_username,
			entdate = TRUNC( SYSDATE ),
			check_criteria_id = i_pentype_tab(i).check_criteria_id
		WHERE	pentype_id = i_pentype_tab(i).pentype_id;
	END	LOOP;

	o_result := 0;

EXCEPTION
	WHEN	OTHERS
	THEN
		o_result := -3;
		RETURN;
END	update_pentypes;

PROCEDURE	view_pentypes
	(
	o_pentype_cur	IN OUT pentype_cur_type
	)
IS
BEGIN
	OPEN	o_pentype_cur
	FOR
	SELECT	pentype_id,
		pentype_des,
		event_id,
		ohinvtype,
		glacode,
		postbilling,
		username,
		entdate,
		check_criteria_id
	FROM	pentypes
	ORDER	BY pentype_id;
END	view_pentypes;

END	penadmin;
/

SHOW ERROR