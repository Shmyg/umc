UPDATE	repman.repman_errors
SET	err_message = '������ ���� ������������� �����!',
	des = 'AA sign date cannot be in future or earlier than contract sign date'
WHERE	modulename = 'CONTR_AA_MNG'
AND	err_id = 5
/