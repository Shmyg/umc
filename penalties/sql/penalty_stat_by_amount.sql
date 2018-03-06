SET TERMOUT OFF
SET TRIMSPOOL ON
SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 1000000
SET PAGESIZE 0
SET FEEDBACK OFF
SET TIMING OFF
ALTER SESSION SET NLS_NUMERIC_CHARACTERS=',.';

/*
|| Script calculating penalties statistics
|| Outputs: treshold (up to 2000 UAH - divisible by 50 and then - 
|| divisible by 1000), penalties number and sum
|| Uses: ORDERHDR_ALL
|| Usage: @penalty_stat_by_amount DD.MM.YYYY DD.MM.YYYY, where DD.MM.YYYY -
|| period beginning and end respectively
|| Created by Shmyg
|| LMD 12.05.2003
*/

SPOOL penalty_stat_by_amount.csv

SELECT	DECODE	(
		SIGN( ohinvamt_gl - 2000 ),
			-1,	( ( TRUNC( ohinvamt_gl / 50 ) * 50 ) + 50 ),
				( ( TRUNC( ohinvamt_gl / 1000 ) * 1000 ) + 1000 )
		) || ';' ||
	COUNT( ohxact ) || ';' ||
	SUM( ohinvamt_gl)
FROM	orderhdr_all	oh
WHERE	ohentdate >= TO_DATE( '&1', 'DD.MM.YYYY' )
AND	ohentdate < TO_DATE ( '&2', 'DD.MM.YYYY' )
AND	ohstatus = 'IN'
AND	ohinvtype = 2
GROUP	BY DECODE	(
		SIGN( ohinvamt_gl - 2000 ),
			-1,	( ( TRUNC( ohinvamt_gl / 50 ) * 50 ) + 50 ),
				( ( TRUNC( ohinvamt_gl / 1000 ) * 1000 ) + 1000 )
		)
/

SPOOL OFF
SET TERMOUT ON
