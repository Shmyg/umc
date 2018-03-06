CREATE	OR REPLACE
PACKAGE	BODY &owner..penalty
AS

	g_username	VARCHAR2(20) := USER;

	TYPE	number_tab_type
	IS	TABLE
	OF	NUMBER
	INDEX	BY BINARY_INTEGER;

---------------------------------------------
FUNCTION	suspension_time
	(
	i_co_id		NUMBER,
	i_from_date	DATE := NULL,
	i_to_date	DATE := NULL
	)
RETURN	NUMBER
IS

	v_from_date	DATE;
	v_to_date	DATE;
	v_date		DATE;
	v_status	VARCHAR2(1) := NULL;
	v_susp_days	PLS_INTEGER := 0;
	v_prev_status	VARCHAR2(1) := NULL;
	v_prev_date	DATE;
	v_last_record	BOOLEAN := FALSE; -- switch to exit status_cur

	-- Cursor for deactivation date search
	CURSOR	deact_date_cur
		(
		p_co_id	NUMBER
		)
	IS
	SELECT	ch_validfrom
	FROM	contract_history
	WHERE	co_id = p_co_id
	AND	ch_status = 'd';

	-- Cursor for all the status changed in given period of time
	CURSOR	status_cur
		(
		p_co_id		NUMBER,
		p_from_date	DATE
		)
	IS
	SELECT	ch_status,
		TRUNC( ch_validfrom )
	FROM	contract_history
	WHERE	co_id = p_co_id
	AND	ch_validfrom >=	-- Looking for one step before from_time
		(
		SELECT	MAX( ch_validfrom )
		FROM	contract_history
		WHERE	co_id = p_co_id
		AND	ch_validfrom <= p_from_date
		)
	ORDER	BY ch_validfrom;

BEGIN

	-- Looking for lower bound
        -- fixed bug if co_activated more than i_from_date
        -- if contract non exists return -1 
        SELECT  co_activated
          INTO  v_from_date
          FROM  contract_all
         WHERE  co_id = i_co_id;
							       
	IF	(i_from_date IS NOT NULL) AND (i_from_date > v_from_date)
	THEN
		v_from_date := i_from_date;
	END	IF;

	-- Looking for upper bound
	IF	i_to_date IS NULL
	THEN
		-- Searching deactiovation date
		OPEN	deact_date_cur( i_co_id );

			FETCH	deact_date_cur
			INTO	v_to_date;

			-- Deactivation date not found - using sysdate
			IF	deact_date_cur%NOTFOUND
			THEN
				v_to_date := TRUNC( SYSDATE );
			END	IF;

		CLOSE	deact_date_cur;
	ELSE
		v_to_date := i_to_date;
	END	IF;

	OPEN	status_cur
		(
		i_co_id,
		v_from_date
		);
	LOOP
		FETCH	status_cur
		INTO	v_status,
			v_date;

		EXIT	WHEN
			(
			status_cur%NOTFOUND
			OR
			v_last_record = TRUE
			);

		-- First date maybe less than from_date
		IF	v_date < v_from_date
		THEN
			v_date := v_from_date;
		END	IF;

		-- Last date maybe greater than to_date
		IF	v_date > v_to_date
		THEN
			v_date := v_to_date;
			-- This is the last record to fetch
			v_last_record := TRUE;
		END	IF;

		-- Checking status change
		IF	v_status IN ( 'o', 'a', 'd' )
		THEN
			-- Looking for previous status change
			IF	v_prev_status = 's'
			THEN
				v_susp_days := v_susp_days + ( v_date - v_prev_date );
			END	IF;

			v_prev_date := v_date;
			v_prev_status := 'a';

		ELSE
			v_prev_date := v_date;
			v_prev_status := 's';
		END	IF;
	END	LOOP;
	CLOSE	status_cur;

        -- fixed susp_days if v_status = 's'
	IF (v_status = 's') and (v_to_date > v_date)
	THEN
	 v_susp_days := v_susp_days + (v_to_date - v_date);
	END IF;

	RETURN	v_susp_days;

EXCEPTION
	WHEN	OTHERS
	THEN
		RETURN	-1;
END	suspension_time;

---------------------------------------------------------------

FUNCTION	add_contr_penalty
	(
	i_pencode	NUMBER,
   	i_co_id		NUMBER,
    i_aa_id     NUMBER,
	i_pen_amt_calc	NUMBER,
	i_pen_amt	NUMBER,
	i_entdate	DATE,
    i_pen_remark varchar2 )

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
	SELECT	pr.glacode
	FROM	pentypes	pr,
		penalties_setup	ps
	WHERE	pr.pentype_id = ps.pentype_id
	AND	ps.pencode = p_pencode;

	v_glacode		pentypes.glacode%TYPE;
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
		INTO	v_glacode;

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
		i_entdate,
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
		2,
		NULL,
		TRUNC( i_entdate ),
		i_co_id
		);

	IF	v_ohxact < 0
	THEN
		RAISE	order_insertion_failure;
	END	IF;



	UPDATE	customer_all
	SET	cscurbalance = cscurbalance + i_pen_amt
	WHERE	customer_id = v_customer_id;

	-- Creating tickler

	common.ibu_pos_api_tickler.createtickler
		(
		v_customer_id,	-- Customer_id
		i_co_id,	-- Contract_id
		4,	-- Priority
		'SYSTEM',	-- Tickler_code
		'NOTE',		-- Tickler_status
		'CC UPDATE',	-- Short description
   		'Penalty: '
           ||TO_CHAR(i_pen_amt)
           ||' on contract #'||TO_CHAR(i_co_id)
           ||'. '||TO_CHAR(SYSDATE),	-- Long_description
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
		cp.entdate,
		cp.pen_amt_calc,
		cp.pen_amt,
		cp.status,
		cp.username
	FROM	contr_penalties	cp,
		contract_all	ca
	WHERE	cp.co_id = ca.co_id
	AND	ca.customer_id = i_customer_id
	ORDER	BY cp.co_id;
END	view_contr_penalty;

-------------------------------------------------------------

FUNCTION	penalty_amount
	(
	i_co_id		NUMBER,
	i_pencode	NUMBER
	)
RETURN	NUMBER
IS

	v_penamt	NUMBER;
    v_active_period_only varchar2(1);
    v_susp  number;
    v_penparam NUMBER;
    v_tmcode number;
    v_result number;
    v_access_fee number;

	-- Cursor for additional agreements search

	CURSOR	aa_cur
		(
		p_co_id	NUMBER
		)
	IS
	SELECT	aa.aa_id,
		aa.atcode,
		aa.sign_date,
		aa.cancel_date,
		ag.t_commit
	FROM	agreement_all	aa,
		agrtypes	ag
	WHERE	aa.atcode = ag.atcode
	AND	aa.co_id = p_co_id;

	aa_rec	aa_cur%ROWTYPE;

	-- Cursor for penalty code search
	CURSOR	pencode_cur
		(
		p_pencode	NUMBER
		)
	IS
	SELECT	*
	FROM	penalties_setup
	WHERE	pencode = p_pencode;

	pencode_rec		pencode_cur%ROWTYPE;
	pencode_not_found	EXCEPTION;


	-- Methods of penalty amount calculation

	-- Prorated predefined fixed amount with
    --fixed amount
    c_fxamt CONSTANT PLS_INTEGER := 1;
    -- suspension time taken into account
	c_pfxamt	CONSTANT PLS_INTEGER := 2;
	-- Prorated access fee
	c_paf	CONSTANT PLS_INTEGER := 3;
	-- Initial advance deduction
	c_iad	CONSTANT PLS_INTEGER := 4;
	-- Cross bill discount
	c_cbd	CONSTANT PLS_INTEGER := 5;

    wrong_calc_method_id	EXCEPTION;

	v_suspension_time	PLS_INTEGER := 0; -- suspension time in days
	v_customer_id		NUMBER;

BEGIN

    select active_period_only "uppercase" into v_active_period_only from
    AGRTYPES where atcode =
    (select atcode from penalties_setup where pencode = i_pencode);

    if v_active_period_only = 'X' then v_susp :=1;
    else v_susp :=0;
    end if;

     --    v_susp :=1;

	-- Looking for additional agreement
	OPEN	aa_cur( i_co_id );

		FETCH	aa_cur
		INTO	aa_rec;

		-- No additional agreement
		IF	aa_cur%NOTFOUND
		THEN
			aa_rec.aa_id := 1;
		END	IF;

		-- Looking for penalty conditions
		OPEN	pencode_cur
			(
			i_pencode
			);

			FETCH	pencode_cur
			INTO	pencode_rec;

			IF	pencode_cur%NOTFOUND
			THEN
				RAISE	pencode_not_found;
			END	IF;

		CLOSE	pencode_cur;

		-- Calculating suspension time
		v_suspension_time := suspension_time
			(
			i_co_id,
			aa_rec.sign_date,
			aa_rec.cancel_date
			);

		-- Calculating amount depending on calculation method
        -- fixed amount
		IF	pencode_rec.calc_method_id = c_fxamt
		THEN
			v_penamt := pencode_rec.fx_amt;

          -- prorated fixed amount
		ELSIF	pencode_rec.calc_method_id = c_pfxamt
		THEN

			v_penamt := ( pencode_rec.c1 ) / 365 *
				( aa_rec.t_commit - ( aa_rec.cancel_date -
				aa_rec.sign_date ) + v_susp*v_suspension_time );
        -- prorated access fee (determined from   */
		ELSIF	pencode_rec.calc_method_id = c_paf
		THEN
            select tmcode
            into v_tmcode
            from contract_all
            where co_id = i_co_id;

			v_penamt := ( get_access_fee(v_tmcode) * 12 ) / 365 *
				( aa_rec.t_commit - ( aa_rec.cancel_date -
				aa_rec.sign_date ) + v_susp*v_suspension_time);

        -- initial advance deduction
		ELSIF	pencode_rec.calc_method_id = c_iad
		THEN

			SELECT	customer_id
			INTO	v_customer_id
			FROM	contract_all
			WHERE	co_id = i_co_id;

			SELECT	cscurbalance
			INTO	v_penamt
			FROM	customer_all
			WHERE	customer_id =
				common.umc_util.find_paymntresp (v_customer_id);

		ELSIF	pencode_rec.calc_method_id = c_cbd
		THEN
			NULL;
		ELSE
			RAISE	wrong_calc_method_id;
		END	IF;


	CLOSE	aa_cur;

	RETURN	v_penamt;

EXCEPTION
	WHEN	pencode_not_found
	THEN
		RETURN	-1;
	WHEN	wrong_calc_method_id
	THEN
		RETURN	-2;

END	penalty_amount;
-------------------------------------------------
PROCEDURE	check_contract
	(
	i_co_id		IN NUMBER,
	i_pentype_id	IN NUMBER,
    o_pencode OUT NUMBER,
    o_aa_id  OUT NUMBER,
    o_error_code OUT NUMBER
	)
IS
	-- Cursor for check if such contract exists
	CURSOR	contract_cur
		(
		p_co_id	NUMBER
		)
	IS
	SELECT	co_id
	FROM	contract_all
	WHERE	co_id = p_co_id;


	-- Penalty checks
	-- Contract deactivation
	c_deact_contr	CONSTANT PLS_INTEGER := 1;
	-- Tariff model change
	c_tmcode_change	CONSTANT PLS_INTEGER := 2;

	-- Cursor for checking if contract is deactivated
	CURSOR	deact_contr_cur
		(
		p_co_id	NUMBER
		)
	IS
	SELECT	ch_seqno
	FROM	contract_history
	WHERE	co_id = p_co_id
	AND	ch_status = 'd';

	-- Cursor for checking if there is tariff model change
	CURSOR	tmcode_change_cur
		(
		p_co_id	NUMBER
		)
	IS
	SELECT	seqno
	FROM	rateplan_hist
	WHERE	co_id = p_co_id
	AND	tmcode_date >=
		(
		SELECT	MAX( lrstart )
		FROM	bch_history_table
		);

	-- Cursor for additional agreements search
	CURSOR	aa_cur
		(
		p_co_id	NUMBER
		)
	IS
	SELECT	atcode, aa_id
	FROM	agreement_all
	WHERE	co_id = p_co_id
	AND	cancel_date IS NULL;

	-- Cursor to return penalty data to user
	CURSOR	pencode_cur
		(
		p_atcode	NUMBER,
		p_pentype_id	NUMBER
		)
	IS
	SELECT	ps.pencode
	FROM	penalties_setup	ps,
    		pentypes	pt
	WHERE	ps.pentype_id = p_pentype_id
	AND	ps.atcode = p_atcode
	AND	ps.enabled = 'X';

	v_pencode		penalties_setup.pencode%TYPE;

	-- AA code - equal to 1 for contracts without AA
	v_atcode		agrtypes.atcode%TYPE := 1;
    v_aa_id         agreement_all.aa_id%TYPE := -1;

    v_check_criteria_id   pentypes.check_criteria_id%TYPE := 1;

	v_count			PLS_INTEGER;

	wrong_contract		EXCEPTION;
	contract_active		EXCEPTION;
	no_tmcode_change	EXCEPTION;
	wrong_pentype		EXCEPTION;
	pencode_not_found	EXCEPTION;

BEGIN

	-- Checking contract existence
	OPEN	contract_cur( i_co_id );

		FETCH	contract_cur
		INTO	v_count;

		IF	contract_cur%NOTFOUND
		THEN
			CLOSE	contract_cur;
			RAISE	wrong_contract;
		END	IF;

	CLOSE	contract_cur;


    select check_criteria_id into v_check_criteria_id
    from   pentypes pt
    where pt.pentype_id = i_pentype_id;


	-- Checking check criteria
	IF	v_check_criteria_id = c_deact_contr -- Checking if contract is deactive
	THEN

		OPEN	deact_contr_cur( i_co_id );

			FETCH	deact_contr_cur
			INTO	v_count;

			IF	deact_contr_cur%NOTFOUND -- contract is active
			THEN
				CLOSE	deact_contr_cur;
				RAISE	contract_active;
			END	IF;

		CLOSE	deact_contr_cur;

	ELSIF	v_check_criteria_id = c_tmcode_change -- Looking for tmcode change
	THEN
		OPEN	tmcode_change_cur( i_co_id );

			FETCH	tmcode_change_cur
			INTO	v_count;

			IF	tmcode_change_cur%NOTFOUND -- no tmcode change
			THEN
				CLOSE	tmcode_change_cur;
				RAISE	no_tmcode_change;
			END	IF;

		CLOSE	tmcode_change_cur;
	ELSE
		RAISE	wrong_pentype;
	END	IF;

	-- Looking for aa
	-- if aa not found, then it remains equal to 1
	OPEN	aa_cur( i_co_id );

		FETCH	aa_cur
		INTO	v_atcode, v_aa_id;

	CLOSE	aa_cur;

	OPEN	pencode_cur
		(
		v_atcode,
		i_pentype_id
		);

		FETCH	pencode_cur
		INTO	v_pencode;

		IF	pencode_cur%NOTFOUND
		THEN
			CLOSE	pencode_cur;
			RAISE	pencode_not_found;
		END	IF;
	CLOSE	pencode_cur;

    o_pencode := v_pencode;
    o_aa_id  := v_aa_id;

EXCEPTION
	WHEN	wrong_contract
	THEN	o_error_code :=	-1;
	WHEN	contract_active
	THEN	o_error_code :=	-2;
	WHEN	no_tmcode_change
	THEN	o_error_code :=	-3;
	WHEN	wrong_pentype
	THEN	o_error_code :=	-4;
	WHEN	pencode_not_found
	THEN	o_error_code :=	-5;
	WHEN	OTHERS
	THEN	o_error_code :=	-6;
END	check_contract;

-------------------------------------------------------------------

FUNCTION Get_Access_Fee (i_tmcode IN NUMBER ) RETURN  NUMBER IS

   i_access_fee NUMBER;

BEGIN

select tmb.accessfee
  into i_access_fee
  from sysadm.mpulktmb tmb,
       common.valid_tmcodes tm
 where tmb.tmcode = tm.tmcode
   and tm.vscode = tmb.vscode
   and tmb.sncode in (12, 140)
   and tm.tmcode = i_tmcode;

   RETURN i_access_fee;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
    return -1 ;
END Get_Access_Fee;



------------------------------------------
FUNCTION	penalty_amount_by_method
	(
	i_co_id    		NUMBER,
	i_calc_method	NUMBER,
    i_param         NUMBER,
    i_susp_incl BOOLEAN

	)
RETURN	NUMBER
IS
    -- Methods of penalty amount calculation


    -- !!!!  THESE NUMBERS ARE HARDCODED IN ADD_PENALTY_SHORT.FMB

    --fixed amount
    c_fxamt CONSTANT PLS_INTEGER := 1;
    -- prorated fixed amt suspension time taken into account
	c_pfxamt CONSTANT PLS_INTEGER := 2;
	-- Prorated access fee
	c_paf	CONSTANT PLS_INTEGER := 3;
	-- Initial advance deduction
	c_iad	CONSTANT PLS_INTEGER := 4;
	-- Cross bill discount
	c_cbd	CONSTANT PLS_INTEGER := 5;
    -- Prorated access fee for integer months
    c_paf_int_months CONSTANT PLS_INTEGER := 6;




    wrong_calc_method_id	EXCEPTION;
    strange_contract_dating	EXCEPTION;
    negative_penalty_amt    EXCEPTION;

	v_suspension_time	PLS_INTEGER := 0; -- suspension time in days

	v_penamt       	NUMBER;
    v_susp          number;
    v_tmcode        number;
    v_access_fee    number;
    v_co_act_date   date;
	v_co_deact_date date;
	v_customer_id	NUMBER;

BEGIN
       if i_susp_incl = TRUE then v_susp :=1;
       else v_susp :=0;
       end if;

		-- Determine activation date
      	SELECT	trunc(co_activated) INTO	v_co_act_date FROM	contract_all
        WHERE	co_id = i_co_id;
		-- Determine deactivation date
        SELECT	trunc(ch_validfrom) into v_co_deact_date FROM	contract_history
       	WHERE	co_id = i_co_id AND	ch_status = 'd';

        if v_co_deact_date < v_co_act_date then
        raise strange_contract_dating;
        end if;

		-- Calculating suspension time
		v_suspension_time := trunc(suspension_time
			(
			i_co_id,
			v_co_act_date,
			v_co_deact_date
			));

		-- Calculating amount depending on calculation method
        -- fixed amount
		IF	i_calc_method = c_fxamt
		THEN
			v_penamt := i_param;
        -- prorated fixed amount
		ELSIF	i_calc_method = c_pfxamt
		THEN
            v_penamt := ( i_param ) / 365 *
				( 365 - ( v_co_deact_date -
				v_co_act_date ) + v_susp*v_suspension_time );

        -- prorated access fee (determined from   */
		ELSIF	i_calc_method = c_paf
		THEN
            select tmcode
            into v_tmcode
            from contract_all
            where co_id = i_co_id;

			v_penamt := ( get_access_fee(v_tmcode) * 12 ) / 365 *
    		( 365 - TRUNC( v_co_deact_date - v_co_act_date ) + v_susp*v_suspension_time );

        -- initial advance deduction
		ELSIF	i_calc_method = c_iad
		THEN
            NULL;
		ELSIF	i_calc_method = c_cbd
		THEN
			NULL;
		ELSIF	i_calc_method = c_paf_int_months
		THEN
            select tmcode
            into v_tmcode
            from contract_all
            where co_id = i_co_id;

			v_penamt := ( get_access_fee(v_tmcode))
               * TRUNC
               (
                MONTHS_BETWEEN
                 (
                TRUNC( ADD_MONTHS(v_co_act_date, 12 ), 'MM' ),
                TRUNC( ADD_MONTHS(v_co_deact_date, 1 ), 'MM' )
                 )
                );

		ELSE
			RAISE	wrong_calc_method_id;
		END	IF;

        if v_penamt < 0 then

        raise negative_penalty_amt;
        end if;


	RETURN	v_penamt;

EXCEPTION
	WHEN	wrong_calc_method_id
	THEN
		RETURN	-2;
    WHEN    strange_contract_dating
    THEN
        RETURN  -3;
    WHEN    negative_penalty_amt
    THEN
        RETURN  -4;


END	penalty_amount_by_method;

-----------------------------------------------------
FUNCTION	insert_penalty_invoice
	(
	i_co_id		NUMBER,
	i_pencode	NUMBER,
	i_pen_amt_calc	NUMBER,
	i_pen_amt	NUMBER,
	i_entdate	DATE,
    i_pen_des   varchar2 )
RETURN	NUMBER
IS
	i	BINARY_INTEGER;

	-- Customer who owes the contract
	CURSOR	customer_cur
		(
		p_co_id	NUMBER
		)
	IS
	SELECT	customer_id
	FROM	contract_all
	WHERE	co_id = p_co_id;

	v_customer_id		        NUMBER;
	v_ohxact		            NUMBER;
	v_result		            NUMBER;
    v_add_cp_result             NUMBER;

	glacode_not_found	EXCEPTION;
	customer_not_found	EXCEPTION;
	order_insertion_failure	EXCEPTION;
	tickler_creation_failure	EXCEPTION;

BEGIN

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

	v_ohxact := common.umc_finance.insert_order
		(
		v_customer_id,
		'Sh'||TO_CHAR(i_co_id),
		i_pen_amt,
		'3210070',
		'IN',
		2,
		NULL,
		TRUNC( SYSDATE ),
		i_co_id
		);

	IF	v_ohxact < 0
	THEN
		RAISE	order_insertion_failure;
	END	IF;

/*
    v_add_cp_result:=add_contr_penalty_light
	(
	i_co_id,
	-1,
    null,
	i_pen_amt_calc,
	i_pen_amt,
	i_entdate,
    'W',
    i_pen_des);
*/

 	UPDATE	customer_all
	SET	cscurbalance = cscurbalance + i_pen_amt
	WHERE	customer_id = v_customer_id;

	-- Creating tickler

	common.ibu_pos_api_tickler.createtickler
		(
		v_customer_id,	-- Customer_id
		i_co_id,	-- Contract_id
		4,	-- Priority
		'SYSTEM',	-- Tickler_code
		'NOTE',		-- Tickler_status
		'CC UPDATE',	-- Short description
   		'Penalty: '
           ||TO_CHAR(i_pen_amt)
           ||' on contract #'||TO_CHAR(i_co_id)
           ||'. '||TO_CHAR(SYSDATE),	-- Long_description
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




	RETURN	v_result;

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


END	insert_penalty_invoice;

---------------------------------------
FUNCTION add_contr_penalty_light
	(
	i_co_id		NUMBER,
	i_pencode	NUMBER,
    i_aa_id     NUMBER,
	i_pen_amt_calc	NUMBER,
	i_pen_amt	NUMBER,
	i_entdate	DATE,
    i_status    varchar2,
    i_pen_des   varchar2)

RETURN NUMBER
IS
	v_cp_id	NUMBER;

BEGIN

	SELECT	NVL( MAX( cp_id ), 0 ) + 1
	INTO	v_cp_id
	FROM	contr_penalties;

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
		i_entdate,
        i_pen_amt_calc,
		i_pen_amt,
        i_status,
		g_username,
        i_pen_des
		);


RETURN 0;

EXCEPTION

WHEN PROGRAM_ERROR
THEN RETURN -1;

END  add_contr_penalty_light ;

-----------------------------------

FUNCTION cp_duplicates_check_passed
         (i_co_id IN NUMBER, i_pencode IN NUMBER)
RETURN boolean IS

  v_once_per_agreement      char;
  v_cp_id					CONTR_PENALTIES.cp_id%TYPE;

  check_passed exception;

 	CURSOR	cp_cur
		(
		p_co_id	NUMBER,
		p_pencode	NUMBER
		)
	IS
		SELECT CP_ID
		FROM
   		PENTYPES PT,
 			CONTR_PENALTIES CP,
 			PENALTIES_SETUP PS
		WHERE
  	  (PS.PENTYPE_ID = PT.PENTYPE_ID)
 		AND(CP.PENCODE = PS.PENCODE)
 		AND(UPPER(PT.ONCE_PER_AGREEMENT) = 'X')
 		AND(CP.PENCODE = p_pencode)
 		AND(CP.CO_ID = p_co_id);

BEGIN

   		OPEN	cp_cur( i_co_id, i_pencode );

			FETCH	cp_cur
			INTO	v_cp_id;

			IF	cp_cur%NOTFOUND
			THEN
				CLOSE	cp_cur;
				RAISE	check_passed;
			END	IF;
			CLOSE	cp_cur;

    		RETURN FALSE;

EXCEPTION

		WHEN check_passed
    	THEN RETURN TRUE;
END cp_duplicates_check_passed;



END	penalty;
/

SHOW ERROR
