LOAD DATA
INFILE *
BADFILE 'executor_check_criteria.bad'
DISCARDFILE 'executor_check_criteria.dis'
REPLACE
INTO TABLE EXECUTOR.CHECK_CRITERIA
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'

 (
  check_criteria_id          ,
  shdes                      CHAR,
  des                        CHAR,
  username                   CHAR,
  entdate                    DATE "DD-MM-YYYY"
 )

BEGINDATA
1,Deact,Deactivation,TSLOBOD,25-JUN-2002
2,TMCh,TMChange,TSLOBOD,25-JUN-2002