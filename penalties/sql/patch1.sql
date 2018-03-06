DROP	TABLE &owner..phone_nums
/

CREATE	TABLE &owner..phone_nums
	(
	model_name	VARCHAR2(40) NOT NULL,
	imei		VARCHAR2(15) NOT NULL,
	phone_sold	VARCHAR2(1),
	username	VARCHAR2(20) DEFAULT 'EXECUTOR' NOT NULL,
	entdate		DATE DEFAULT SYSDATE NOT NULL
	)
/

CREATE	TABLE &owner..phone_models1
	(
	model_name	VARCHAR2(40) NOT NULL,
	atcode		NUMBER,
	username	VARCHAR2(20) DEFAULT 'EXECUTOR' NOT NULL,
	entdate		DATE DEFAULT SYSDATE NOT NULL
	)
/

INSERT	INTO &owner..phone_models1
	(
	SELECT	atcode,
		model_name,
		entuser,
		entdate
	FROM	&owner..phone_models
	)
/

DROP	TABLE &owner..phone_models
/

RENAME	&owner..phone_models1 TO &owner..phone_models
/

ALTER	TABLE &owner..phone_models
ADD	CONSTRAINT pkphone_models
PRIMARY	KEY ( model_name, atcode )
USING	INDEX
PCTFREE		10
INITRANS	2
MAXTRANS	255
TABLESPACE	&indtsp
/