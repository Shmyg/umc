CREATE OR REPLACE
PACKAGE	&owner..penalty
AS


/*
Package for penalty administration

Contents:

add_contr_penalty
lock_contr_penalty
update_contr_penalty
view_contr_penalty

*/

-- Record in contract_penalty table
TYPE	contr_penalty_rec_type
IS	RECORD
	(
	cp_id		NUMBER,
	pencode		NUMBER,
	co_id		NUMBER,
	entdate		DATE,
	pen_amt_calc	NUMBER,
	pen_amt		NUMBER,
	status		VARCHAR2(1),
	username	VARCHAR2(20)
	);

-- Ref cursor
TYPE	contr_penalty_cur_type
IS	REF CURSOR
RETURN	contr_penalty_rec_type;

-- Table with penreasons to process
TYPE	contr_penalty_tab_type
IS	TABLE
OF	contr_penalty_rec_type
INDEX	BY BINARY_INTEGER;

FUNCTION	add_contr_penalty
	(
	i_pencode	NUMBER,
	i_co_id		NUMBER,
    i_aa_id     NUMBER,
	i_pen_amt_calc	NUMBER,
	i_pen_amt	NUMBER,
	i_entdate	DATE := TRUNC( SYSDATE ),
   	i_pen_remark IN varchar2
	)
RETURN	NUMBER;

FUNCTION add_contr_penalty_light
	(
	i_co_id		IN NUMBER,
	i_pencode	IN NUMBER,
	i_aa_id     IN NUMBER,
	i_pen_amt_calc	IN NUMBER,
	i_pen_amt	IN NUMBER,
	i_entdate	IN DATE,
	i_status	IN varchar2,
	i_pen_des	IN varchar2
	)
RETURN NUMBER;

-- this function is a modification of add_contr_penalty
-- used by add_penalty_short.fbm
-- used add_contr_penalty_light for insertion of penalties
-- to own schema

FUNCTION	insert_penalty_invoice
	(
	i_co_id		IN NUMBER,
	i_pencode	IN NUMBER,
	i_pen_amt_calc	IN NUMBER,
	i_pen_amt	IN NUMBER,
	i_entdate	IN DATE := TRUNC( SYSDATE ),
	i_pen_des	IN VARCHAR2
	)
RETURN	NUMBER;

PROCEDURE	lock_contr_penalty
	(
	i_contr_penalty_tab	IN OUT NOCOPY contr_penalty_tab_type,
	o_result		OUT NUMBER
	);

PROCEDURE	update_contr_penalty
	(
	i_contr_penalty_tab	IN OUT NOCOPY contr_penalty_tab_type,
	o_result		OUT NUMBER
	);

PROCEDURE	view_contr_penalty
	(
   	o_contr_penalty_cur	IN OUT contr_penalty_cur_type,
	i_customer_id		IN NUMBER
	);

FUNCTION	penalty_amount
	(
	i_co_id		NUMBER,
	i_pencode	NUMBER
	)
RETURN	NUMBER;

FUNCTION	penalty_amount_by_method
	(
	i_co_id    		IN NUMBER,
	i_calc_method	IN NUMBER,
	i_param         IN NUMBER,
	i_susp_incl IN BOOLEAN
    )
RETURN	NUMBER;

PROCEDURE	check_contract
	(
	i_co_id		IN NUMBER,
	i_pentype_id	IN NUMBER,
    o_pencode OUT NUMBER,
    o_aa_id  OUT NUMBER,
    o_error_code OUT NUMBER);

FUNCTION Get_Access_Fee (i_tmcode IN NUMBER )
RETURN  NUMBER;

FUNCTION	suspension_time
	(
	i_co_id	    IN NUMBER,
	i_from_date	IN DATE,
	i_to_date   IN DATE
	)
RETURN	NUMBER;

FUNCTION cp_duplicates_check_passed
         (i_co_id IN NUMBER,
          i_pencode IN NUMBER)
RETURN BOOLEAN;


END	penalty;
/

SHOW ERROR
