INSERT	INTO &owner..agrtypes
	(
	atcode,
	shdes,
	longdes,
	expires,
	t_commit,
	active_period_only,
	excl_mode,
	validfrom,
	username
	)
VALUES	(
	5,
	'ДУ АП КОРП',
	'ДУ зі штрафом по абонплаті за повні місяці для корпоративних клієнтів',
	TO_DATE( '01.08.2002', 'DD.MM.YYYY' ),
	365,
	NULL,
	'X',
	TO_DATE( '01.01.2000', 'DD.MM.YYYY' ),
	'SHMYG'
	)
/

INSERT	INTO &owner..agrtypes
	(
	atcode,
	shdes,
	longdes,
	expires,
	t_commit,
	active_period_only,
	excl_mode,
	validfrom,
	username
	)
VALUES	(
	6,
	'ДУ АП',
	'ДУ зі штрафом по абонплаті за повні місяці',
	TO_DATE( '01.08.2002', 'DD.MM.YYYY' ),
	365,
	NULL,
	'X',
	TO_DATE( '01.01.2000', 'DD.MM.YYYY' ),
	'SHMYG'
	)
/
