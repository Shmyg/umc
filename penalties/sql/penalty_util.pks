CREATE OR REPLACE
PACKAGE	&owner..penalty_util
AS

-----------------------------------
FUNCTION	suspension_time
	(
	i_co_id	    IN NUMBER,
	i_from_date	IN DATE,
	i_to_date   IN DATE
	)
RETURN	NUMBER;

---------------------------
FUNCTION	penalty_amount
	(
	i_co_id		NUMBER,
	i_pencode	NUMBER,
    i_atcode    NUMBER,
    i_aa_id     NUMBER
	)
RETURN	NUMBER;
----------------------------------------
PROCEDURE	check_contract
	(
	i_co_id		IN NUMBER,
	i_pentype_id	IN NUMBER,
    o_pencode OUT NUMBER,
    o_aa_id  OUT NUMBER,
    o_error_code OUT NUMBER);

FUNCTION Get_Access_Fee (i_tmcode IN NUMBER )
RETURN  NUMBER;
--------------------------------------------
FUNCTION cp_duplicates_check_passed
         (i_co_id IN NUMBER,
          i_pencode IN NUMBER)
RETURN BOOLEAN;

----------------------------------------------
FUNCTION NO_TMCHANGE_SINCE_LAST_TMPENAL 
( i_co_id IN NUMBER,
  i_pencode IN NUMBER,
  i_tmch_pentype IN NUMBER)
RETURN BOOLEAN;

END	penalty_util;
/
SHOW ERROR
