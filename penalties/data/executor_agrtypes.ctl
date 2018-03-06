LOAD DATA
INFILE *
REPLACE
INTO TABLE EXECUTOR.AGRTYPES
FIELDS TERMINATED BY ';'
(ATCODE,
 SHDES,
 LONGDES,
 EXPIRES DATE(12) "DD.MM.YYYY" ,
 T_COMMIT,
 ACTIVE_PERIOD_ONLY,
 EXCL_MODE,
 VALIDFROM DATE(12) "DD.MM.YYYY",
 USERNAME)

BEGINDATA
1;ДУ 1300;ДУ со штрафом на 1300 грн. по дням с учетом саспенда;01.01.2010;365;X;X;01.05.2002;SHMYG
2;ДУ АП CRM;ДУ  со штрафом по абонплате за полные месяцы для программ СRM;01.01.2010;365;;X;01.02.2002;SHMYG
3;ДУ 1300СRM;ДУ со штрафом на 1300 грн. по дням с учетом саспенда для программ СRM;01.01.2010;365;X;X;01.05.2002;SHMYG
4;ДУ1300КОРП;ДУ со штрафом на 1300 грн. по дням с учетом саспенда для кор. клиентов;01.01.2010;365;X;X;01.05.2002;SHMYG
5;ДУ1300ДТЕР;ДУ со штрафом на 1300 грн. по дням с учетом саспенда с терминалом дилера;01.01.2010;365;X;X;01.07.2002;TSLOBOD