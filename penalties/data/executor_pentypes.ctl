LOAD DATA
INFILE *
REPLACE
INTO TABLE EXECUTOR.PHONE_MODELS
FIELDS TERMINATED BY ';'
 (
  model_id                   ,
  atcode                     ,
  model_name                 ,
  entdate                    DATE(12) "DD.MM.YYYY",
  entuser                    
 )


BEGINDATA
1; 1;SIEMENS C35i;01.06.2002;TSLOBOD
2; 1;SIEMENS C45;01.06.2002;TSLOBOD
3; 1;Motorolla 118;01.06.2002;TSLOBOD
4; 1;Nokia 6210;01.06.2002;TSLOBOD
5; 1;Alcatel 501;01.06.2002;TSLOBOD
6; 2;SIEMENS C35i;01.06.2002;TSLOBOD
7; 2;SIEMENS C45;01.06.2002;TSLOBOD
8; 2;Motorolla 118;01.06.2002;TSLOBOD
9; 2;Nokia 8110;01.06.2002;TSLOBOD
10; 2;Alcatel 501;01.06.2002;TSLOBOD


