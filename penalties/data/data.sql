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
	'�� �� ����',
	'�� � ������� �� �������� �� ���� ����� ��� ������������� �볺���',
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
	'�� ��',
	'�� � ������� �� �������� �� ���� �����',
	TO_DATE( '01.08.2002', 'DD.MM.YYYY' ),
	365,
	NULL,
	'X',
	TO_DATE( '01.01.2000', 'DD.MM.YYYY' ),
	'SHMYG'
	)
/
