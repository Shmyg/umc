CREATE OR REPLACE
PACKAGE	BODY &owner..penreason_admin
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
			fx_amt,
			c1,
			c2,
			c3
			)
		VALUES	(
			v_pencode,
			i_penalty_tab(i).atcode,
			i_penalty_tab(i).pentype_id,
			i_penalty_tab(i).pen_des,
			g_username,
			i_penalty_tab(i).enabled,
			i_penalty_tab(i).fx_amt,
			i_penalty_tab(i).c1,
			i_penalty_tab(i).c2,
			i_penalty_tab(i).c3
			);
	END	LOOP;

	o_result := 0;

EXCEPTION
	WHEN	OTHERS
	THEN
		o_result := -1;
		RETURN;

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
			fx_amt = i_penalty_tab(i).fx_amt,
			c1 = i_penalty_tab(i).c1,
			c2 = i_penalty_tab(i).c2,
			c3 = i_penalty_tab(i).c3
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
	o_penalty_cur	IN OUT penalty_cur_type
	)
IS
BEGIN
	OPEN	o_penalty_cur
	FOR
	SELECT	pencode,
		atcode ,
		pentype_id,
		pen_des,
		username,
		enabled,
		fx_amt,
		c1,
		c2,
		c3
	FROM	penalties_setup
	ORDER	BY pencode;

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
			ohinvtype,
			glacode,
			postbilling,
			username,
			check_criteria_id
			)
		VALUES	(
			v_reason_id,
			i_pentype_tab(i).pentype_des,
			i_pentype_tab(i).ohinvtype,
			i_pentype_tab(i).glacode,
			i_pentype_tab(i).postbilling,
			g_username,
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
	FOR	i IN i_pentype_tab.FIRST..i_pentype_tab.LAST
	LOOP
		SELECT	pentype_des
		INTO	v_pentype_des
		FROM	pentypes
		WHERE	pentype_id = i_pentype_tab(i).pentype_id
		FOR	UPDATE;
	END	LOOP;

	o_result := 0;

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
			glacode = i_pentype_tab(i).glacode,
			postbilling = i_pentype_tab(i).postbilling,
			username = g_username,
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
		ohinvtype,
		glacode,
		postbilling,
		username,
		check_criteria_id
	FROM	pentypes
	ORDER	BY pentype_id;
END	view_pentypes;

END	penreason_admin;
/

SHOW ERROR
