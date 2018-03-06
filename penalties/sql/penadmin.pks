CREATE	OR REPLACE
PACKAGE	&owner..penadmin
AS

-- Record with penalty definintion data
-- modified by tslobod on 13.05.2002
TYPE	penalty_rec_type
IS	RECORD
	(
        pencode		NUMBER,
        atcode		NUMBER,
        pentype_id	NUMBER,
        pen_des		VARCHAR2(255),
        username	VARCHAR2(20),
        enabled		VARCHAR2(1),
        calc_method_id  number,
        fx_amt		NUMBER,
        c1		NUMBER,
        c2		NUMBER,
        c3		NUMBER,
        service_param	number,
        CALC_METHOD_DES	VARCHAR2(60),
        SHDES VARCHAR2 (20),
        LONGDES VARCHAR2(200),
        PENTYPE_DES VARCHAR2(200)
        
	);

-- Ref cursor
TYPE	penalty_cur_type
IS	REF CURSOR
RETURN	penalty_rec_type;

-- Table with penreasons to process
TYPE	penalty_tab_type
IS	TABLE
OF	penalty_rec_type
INDEX	BY BINARY_INTEGER;

-- Record with penreason data
TYPE	pentype_rec_type
IS	RECORD
	(
	pentype_id	NUMBER,
	pentype_des	VARCHAR2(200),
	event_id	NUMBER,
	ohinvtype	NUMBER,
	glacode		VARCHAR2(30),
	postbilling	VARCHAR2(1),
	username	VARCHAR2(20),
	entdate		DATE,
	check_criteria_id	NUMBER
	);

-- Ref cursor
TYPE	pentype_cur_type
IS	REF CURSOR
RETURN	pentype_rec_type;

-- Table with pentypes to process
TYPE	pentype_tab_type
IS	TABLE
OF	pentype_rec_type
INDEX	BY BINARY_INTEGER;

PROCEDURE	add_pendefinitions
	(
	i_penalty_tab	IN OUT NOCOPY penalty_tab_type,
	o_result	OUT NUMBER
	);

PROCEDURE	lock_pendefinitions
	(
	i_penalty_tab	IN OUT NOCOPY penalty_tab_type,
	o_result	OUT NUMBER
	);

PROCEDURE	update_pendefinitions
	(
	i_penalty_tab	IN OUT NOCOPY penalty_tab_type,
	o_result	OUT NUMBER
	);

PROCEDURE	view_pendefinitions
	(
	o_penalty_cur	IN OUT penalty_cur_type,
    o_atcode_param in out number 
	);

PROCEDURE	add_pentypes
	(
	i_pentype_tab	IN OUT NOCOPY pentype_tab_type,
	o_result	OUT NUMBER
	);

PROCEDURE	lock_pentypes
	(
	i_pentype_tab	IN OUT NOCOPY pentype_tab_type,
	o_result	OUT NUMBER
	);

PROCEDURE	update_pentypes
	(
	i_pentype_tab	IN OUT NOCOPY pentype_tab_type,
	o_result	OUT NUMBER
	);

PROCEDURE	view_pentypes
	(
	o_pentype_cur	IN OUT pentype_cur_type
	);

END	penadmin;
/

SHOW ERROR