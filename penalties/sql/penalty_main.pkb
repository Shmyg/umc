CREATE	OR REPLACE
PACKAGE	BODY &owner..penalty_main
AS

	g_username	VARCHAR2(20) := USER;

	TYPE	number_tab_type
	IS	TABLE
	OF	NUMBER
	INDEX	BY BINARY_INTEGER;

--------------------------------------------------------------

FUNCTION	add_contr_penalty
	(
     i_pencode                    NUMBER,
     i_co_id                      NUMBER,
     i_aa_id                      NUMBER,
     i_pen_amt_calc               NUMBER,
     i_pen_amt                    NUMBER,
     i_status                     VARCHAR2,
     i_pen_remark                 VARCHAR2,
     i_tickler_text               VARCHAR2  
     )

RETURN	NUMBER
IS
	i	BINARY_INTEGER;
	v_cp_id	NUMBER;

	-- Customer who owes the contract
	CURSOR	customer_cur
		(
		p_co_id	NUMBER
		)
	IS
	SELECT	customer_id
	FROM	contract_all
	WHERE	co_id = p_co_id;

	-- GL-code to enter money
	CURSOR	glacode_cur
		(
		p_pencode	NUMBER
		)
	IS
	SELECT	pr.glacode, pr.ohinvtype
	FROM	pentypes	pr,
		penalties_setup	ps
	WHERE	pr.pentype_id = ps.pentype_id
	AND	ps.pencode = p_pencode;

	v_glacode		pentypes.glacode%TYPE;
    v_ohinvtype     pentypes.ohinvtype%TYPE;
	v_customer_id		NUMBER;
	v_ohxact		NUMBER;
	v_result		NUMBER;

	glacode_not_found	EXCEPTION;
	customer_not_found	EXCEPTION;
	order_insertion_failure	EXCEPTION;
	tickler_creation_failure	EXCEPTION;

BEGIN

	SELECT	NVL( MAX( cp_id ), 0 ) + 1
	INTO	v_cp_id
	FROM	contr_penalties;

	-- Looking for customer who owes the contract
	OPEN	customer_cur( i_co_id );

		FETCH	customer_cur
		INTO	v_customer_id;

		IF	customer_cur%NOTFOUND
		THEN
			RAISE	customer_not_found;
		END	IF;

	CLOSE	customer_cur;

	-- Looking for paymentresponsible
	v_customer_id := common.umc_util.find_paymntresp( v_customer_id );

	OPEN	glacode_cur( i_pencode );

		FETCH	glacode_cur
		INTO	v_glacode, v_ohinvtype;

		IF	glacode_cur%NOTFOUND
		THEN
			RAISE	glacode_not_found;
		END	IF;

	CLOSE	glacode_cur;

	INSERT	INTO contr_penalties
		(
		cp_id,
		pencode,
		co_id,
		aa_id,
		entdate,
		pen_amt_calc,
		pen_amt,
		status,
		username,
		pen_remark
		)
	VALUES	(
		v_cp_id,
		i_pencode,
		i_co_id,
	    i_aa_id,
		TRUNC(SYSDATE),
		i_pen_amt_calc,
		i_pen_amt,
		'W',
		g_username,
	    i_pen_remark
		);

	v_ohxact := common.umc_finance.insert_order
		(
		v_customer_id,
		'Sh'||TO_CHAR(i_co_id),
		i_pen_amt,
		v_glacode,
		'IN',
		v_ohinvtype,
		NULL,
		TRUNC(SYSDATE),
		i_co_id
		);

	IF	v_ohxact < 0
	THEN
		RAISE	order_insertion_failure;
	END	IF;


	UPDATE	customer_all
	SET	cscurbalance = cscurbalance + i_pen_amt
	WHERE	customer_id = v_customer_id;

	common.ibu_pos_api_tickler.createtickler
		(
		v_customer_id,	-- Customer_id
		i_co_id,	-- Contract_id
		4,	-- Priority
		'SYSTEM',	-- Tickler_code
		'NOTE',		-- Tickler_status
		'CC UPDATE',	-- Short description
        i_tickler_text, 
/*        'Penalty: '
           ||TO_CHAR(i_pen_amt)
           ||' on contract #'||TO_CHAR(i_co_id)
           ||'. '||TO_CHAR(SYSDATE),	-- Long_description */
		NULL,	-- action ID
		NULL,	-- equipment ID
		NULL,	-- market ID
		NULL,	-- message ID
		NULL,	-- date when the last message was sent
		NULL,	-- user who sent the last message
		NULL,	-- source code ID
		NULL,	-- problem tracking ID
		NULL,	-- type ID
		NULL,	-- usage ID
		g_username,	-- follow up user
		NULL,	-- follow up action ID
		SYSDATE,	-- follow up date
		NULL,	-- X co-ordinate
		NULL,	-- Y co-ordinate
		NULL,	-- distibution list user 1
		NULL,	-- distibution list user 2
		NULL,	-- distibution list user 3
		NULL,	-- user who closed the tickler
		SYSDATE,	-- date when the tickler was sent
		g_username,	-- user who created the tickler
		v_result
		);

	IF	v_result != 0
	THEN
		RAISE	tickler_creation_failure;
	END	IF;

	RETURN	v_cp_id;

EXCEPTION

	WHEN	customer_not_found
	THEN
		RETURN -1;
	WHEN	glacode_not_found
	THEN
		RETURN -2;
	WHEN	order_insertion_failure
	THEN
		RETURN -3;
	WHEN	tickler_creation_failure
	THEN
		RETURN	-4;
	WHEN	OTHERS
	THEN
		RETURN -5;


END	add_contr_penalty;

--------------------------------------------------------

PROCEDURE	lock_contr_penalty
	(
	i_contr_penalty_tab	IN OUT NOCOPY contr_penalty_tab_type,
	o_result	OUT NUMBER
	)
IS
	v_pencode	NUMBER;
	i		BINARY_INTEGER;
BEGIN
	FOR	i IN i_contr_penalty_tab.FIRST..i_contr_penalty_tab.LAST
	LOOP
		SELECT	pencode
		INTO	v_pencode
		FROM	contr_penalties
		WHERE	cp_id = i_contr_penalty_tab(i).cp_id
		FOR	UPDATE;
	END	LOOP;

	o_result := 0;

EXCEPTION
	WHEN	OTHERS
	THEN
		o_result := -2;
		RETURN;
END	lock_contr_penalty;
-----------------------------------------------------------------
PROCEDURE	update_contr_penalty
	(
	i_contr_penalty_tab	IN OUT NOCOPY contr_penalty_tab_type,
	o_result	OUT NUMBER
	)
IS
	i	BINARY_INTEGER;
BEGIN
	FOR	i in i_contr_penalty_tab.FIRST..i_contr_penalty_tab.LAST
	LOOP
		UPDATE	contr_penalties
		SET	pencode = i_contr_penalty_tab(i).pencode,
			co_id = i_contr_penalty_tab(i).co_id,
			entdate = i_contr_penalty_tab(i).entdate,
			pen_amt_calc = i_contr_penalty_tab(i).pen_amt_calc,
			pen_amt = i_contr_penalty_tab(i).pen_amt,
			status = i_contr_penalty_tab(i).status,
			username = g_username
		WHERE	cp_id = i_contr_penalty_tab(i).cp_id;
	END	LOOP;

	o_result := 0;

EXCEPTION
	WHEN	OTHERS
	THEN
		o_result := -3;
		RETURN;
END	update_contr_penalty;

----------------------------------------------------

PROCEDURE	view_contr_penalty
	(
	o_contr_penalty_cur	IN OUT contr_penalty_cur_type,
	i_customer_id IN NUMBER
	)
IS
BEGIN
	OPEN	o_contr_penalty_cur
	FOR
	SELECT	cp.cp_id,
		cp.pencode,
		cp.co_id,
        cp.aa_id,
		cp.pen_amt_calc,
		cp.pen_amt,
		cp.status,
		cp.username,
        cp.entdate,
        pen_remark
	FROM	contr_penalties	cp,
		contract_all	ca
	WHERE	cp.co_id = ca.co_id
	AND	ca.customer_id = i_customer_id
	ORDER	BY cp.co_id;
END	view_contr_penalty;

-------------------------------------------------------------
END	penalty_main;
/
SHOW ERROR

