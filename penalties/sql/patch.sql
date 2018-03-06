ALTER TABLE &owner..agreement_all
ADD	user_deactivated VARCHAR2(20)
/

COMMENT ON COLUMN &owner..agreement_all.user_deactivated IS 'User who deactivated AA'
/

CREATE	TABLE &owner..old_aa
	(
	text02		VARCHAR2(80) NOT NULL,
	text14		VARCHAR2(80),
	username	VARCHAR2(20) NOT NULL
	)
PCTFREE		0
PCTUSED		40
INITRANS	1
MAXTRANS	255
TABLESPACE	&deftsp
/

ALTER	TABLE &owner..agreement_all
DROP	CONSTRAINT unq_co_id_atcode
/

UPDATE	repman.repman_errors
SET	err_message = 'На цьому контракті вже є активна ДУ!',
	des = 'Contract already has active AA'
WHERE	modulename = 'CONTR_AA_MNG'
AND	err_id = 9
/