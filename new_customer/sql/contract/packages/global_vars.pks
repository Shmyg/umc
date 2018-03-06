CREATE	OR REPLACE
PACKAGE	&owner..global_vars
/*
|| Package containing all the UMC global vars needed for operations on contract
|| Created by Shmyg
|| Last modified by Shmyg 09.10.2002
*/
AS

	c_gsm_sncode		CONSTANT NUMBER := 12;
	c_fax_sncode		CONSTANT NUMBER := 19;
	c_data_sncode		CONSTANT NUMBER := 30;
	c_nmt_sncode		CONSTANT NUMBER := 140;
	c_det_bill_sncode	CONSTANT NUMBER := 93;
	c_fup_sncode		CONSTANT NUMBER := 203;
	c_onhold_rs_id		CONSTANT NUMBER := 6;
	c_takeover_rs_id	CONSTANT NUMBER := 28;

	TYPE	number_tab_type
	IS
	TABLE	OF NUMBER
	INDEX	BY BINARY_INTEGER;


END	global_vars;
/
SHOW ERROR
