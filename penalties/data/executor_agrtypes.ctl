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
1;�� 1300;�� �� ������� �� 1300 ���. �� ���� � ������ ��������;01.01.2010;365;X;X;01.05.2002;SHMYG
2;�� �� CRM;��  �� ������� �� ��������� �� ������ ������ ��� �������� �RM;01.01.2010;365;;X;01.02.2002;SHMYG
3;�� 1300�RM;�� �� ������� �� 1300 ���. �� ���� � ������ �������� ��� �������� �RM;01.01.2010;365;X;X;01.05.2002;SHMYG
4;��1300����;�� �� ������� �� 1300 ���. �� ���� � ������ �������� ��� ���. ��������;01.01.2010;365;X;X;01.05.2002;SHMYG
5;��1300����;�� �� ������� �� 1300 ���. �� ���� � ������ �������� � ���������� ������;01.01.2010;365;X;X;01.07.2002;TSLOBOD