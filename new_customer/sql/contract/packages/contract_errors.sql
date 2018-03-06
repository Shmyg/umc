INSERT	INTO repman.repman_errors
	(
	modulename,
	err_id,
	err_message,
	des
	)
VALUES	(
	'UMC_CONTRACT',
	1,
	'На цьому контракті вже є такий сервіс!',
	'Such a service exists for the contract'
	)
/
INSERT	INTO repman.repman_errors
	(
	modulename,
	err_id,
	err_message,
	des
	)
VALUES	(
	'UMC_CONTRACT',
	2,
	'Сервіс не може бути призначений на контракт!',
	'Sncode cannot be assigned to contract'
	)
/
INSERT	INTO repman.repman_errors
	(
	modulename,
	err_id,
	err_message,
	des
	)
VALUES	(
	'UMC_CONTRACT',
	3,
	'Контракт не є активним!',
	'Contract is not in active status'
	)
/
INSERT	INTO repman.repman_errors
	(
	modulename,
	err_id,
	err_message,
	des
	)
VALUES	(
	'UMC_CONTRACT',
	4,
	'Відсутні параметри!',
	'Mandatory parameters are missing'
	)
/
INSERT	INTO repman.repman_errors
	(
	modulename,
	err_id,
	err_message,
	des
	)
VALUES	(
	'UMC_CONTRACT',
	5,
	'Помилка під час нарахування OCC!',
	'Fee insertion failure'
	)
/
INSERT	INTO repman.repman_errors
	(
	modulename,
	err_id,
	err_message,
	des
	)
VALUES	(
	'UMC_CONTRACT',
	6,
	'Відсутній номер телефону!',
	'Dn_id is null'
	)
/
INSERT	INTO repman.repman_errors
	(
	modulename,
	err_id,
	err_message,
	des
	)
VALUES	(
	'UMC_CONTRACT',
	7,
	'Помилка під час створення параметрів сервісу!',
	'Parameter creation failure'
	)
/
INSERT	INTO repman.repman_errors
	(
	modulename,
	err_id,
	err_message,
	des
	)
VALUES	(
	'UMC_CONTRACT',
	8,
	'Не знайдено телефону з таким номером!!',
	'No such dn_id in directory_number'
	)
/
INSERT	INTO repman.repman_errors
	(
	modulename,
	err_id,
	err_message,
	des
	)
VALUES	(
	'UMC_CONTRACT',
	9,
	'Невірний статус телефону!',
	'Dn_id is not in reserved status'
	)
/
INSERT	INTO repman.repman_errors
	(
	modulename,
	err_id,
	err_message,
	des
	)
VALUES	(
	'UMC_CONTRACT',
	10,
	'Невірний код сервісу!',
	'Sncode is not found in mpulknxv'
	)
/

INSERT	INTO repman.repman_errors
	(
	modulename,
	err_id,
	err_message,
	des
	)
VALUES	(
	'UMC_CONTRACT',
	11,
	'Не знайдено код HLR!',
	'No HLR data for this contract'
	)
/

INSERT	INTO repman.repman_errors
	(
	modulename,
	err_id,
	err_message,
	des
	)
VALUES	(
	'UMC_CONTRACT',
	12,
	'Цей сервіс не призначений абоненту!',
	'Service is not assigned to contract'
	)
/

-- 30.09.2002
INSERT	INTO repman.repman_errors
	(
	modulename,
	err_id,
	err_message,
	des
	)
VALUES	(
	'UMC_CONTRACT',
	13,
	'Контракту з таким номером не існує!',
	'No such contract in contract_all'
	)
/

INSERT	INTO repman.repman_errors
	(
	modulename,
	err_id,
	err_message,
	des
	)
VALUES	(
	'UMC_CONTRACT',
	17,
	'На цьому контракті є запит на зміну статусу!',
	'Contract has global pending request'
	)
/
