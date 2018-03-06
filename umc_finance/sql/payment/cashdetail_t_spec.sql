CREATE	OR REPLACE
TYPE	&owner..cashdetail_t

/*
Object cashdetail.
Represents one position of payment if it closes some order
Created by Shmyg
LMD 25.02.2003
*/

AS	OBJECT
	(
	-- Payment transaction id - cadxact in CASHDETAIL
	pt_tx_id	NUMBER,
	-- Order transaction id - ohxact in ORDERHDR_ALL
	ord_tx_id	NUMBER,
	-- GL-code - cadglar in CASHDETAIL
	gl_code		VARCHAR2(30),
	-- Associated payment transaction id - cadassocxact in CASHDETAIL
	ass_pt_tx_id	NUMBER,
	amount		NUMBER,

	/*
	Constructor - fills instance with data
	Necessary parameters - cadxact and cadoxact - parts of primary key on
	CASHDETAIL
	*/
	MEMBER	PROCEDURE init
		(
		i_pt_tx_id	IN NUMBER,	-- Payment transaction ID
		i_ord_tx_id	IN NUMBER	-- Order transaction ID
		),

	-- Procedure to create cashdetails with instance parameters
	MEMBER	PROCEDURE insert_me
	);
/

SHOW ERROR
