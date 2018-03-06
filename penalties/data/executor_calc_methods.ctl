LOAD DATA
INFILE *
REPLACE
INTO TABLE EXECUTOR.CALC_METHODS
FIELDS TERMINATED BY ';' 
 (
  calc_method_id             ,
  calc_method_des            ,
  calc_method_longdes        ,
  entdate                    DATE(12) "DD.MM.YYYY",
  username                   
  )
BEGINDATA
1;Գ������� ���� ������ ;��������� C1,C2,C3 ����������� ;26.06.2002;TSLOBOD
2;����������� �� ��������� ���� �� ��;penalty = (C1)/365 *(365-(co_deact_date - co_act_date ) + suspension_time);26.06.2002;TSLOBOD
3;����������� �� ������� ��������� �� �����;penalty = (get_access_fee(tmcode)*12)/365*(365-TRUNC(co_deact_date - co_act_date)+v_suspension_time);26.06.2002;TSLOBOD
4;������������ ������� ������;Initial advance deduction;26.06.2002;TSLOBOD
5;�� ���� ������ CBD;PENALTY=CBD_AMT(t1)/N(t1) +...+ CBD_AMT(tm-1)/N(tm-1)+CBD_AMT(tm)/N(tm),where CBD_AMT(ti) � amount of CBD discount on customer's account in billing period i in UAH representation,N(ti)-number of contacts on customer's account in billing period i;26.06.2002;TSLOBOD