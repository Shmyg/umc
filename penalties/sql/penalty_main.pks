CREATE OR REPLACE
PACKAGE	&owner..penalty_main
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
      cp_id                      NUMBER,
      pencode                    NUMBER,
      co_id                      NUMBER,
      aa_id                      NUMBER,
      pen_amt_calc               NUMBER,
      pen_amt                    NUMBER,
      status                     VARCHAR2(1),
      username                   VARCHAR2(20),
      entdate                    DATE,
      pen_remark                 VARCHAR2(300)
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

------------------------------------
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

RETURN	NUMBER;

----------------------------------
PROCEDURE	lock_contr_penalty
	(
	i_contr_penalty_tab	IN OUT NOCOPY contr_penalty_tab_type,
	o_result		OUT NUMBER
	);
----------------------------------
PROCEDURE	update_contr_penalty
	(
	i_contr_penalty_tab	IN OUT NOCOPY contr_penalty_tab_type,
	o_result		OUT NUMBER
	);
-----------------------------------

PROCEDURE	view_contr_penalty
	(
   	o_contr_penalty_cur	IN OUT contr_penalty_cur_type,
	i_customer_id		IN NUMBER
	);
-----------------------------------


END	penalty_main;
/

SHOW ERROR
