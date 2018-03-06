SET TERMOUT OFF
SET TRIMSPOOL ON
SET ECHO OFF
SET FEEDBACK OFF
SET TAB OFF
SET PAGESIZE 0
SET LINESIZE 32767
SET HEADING OFF

ALTER SESSION SET NLS_DATE_FORMAT='YYYYMMDD';

/*
Script collecting statistics about bad debt write-off
Outputs 2 files: one - with general info and another one - with detailed info
for every written off order
USES: DONOR.CLOSED_ORDERS, COSTCENTER, ORDERHDR_ALL, IFACE2SAP.ORDERS,
CUSTOMER_ALL
Usage: @bad_debt_stat
Created by Shmyg
LMD by Shmyg 24.06.2003
*/
SPOOL bad_debt_groupped.txt

SELECT	de.costcenter || '	' ||
	co.entdate || '	' ||
	co.prgcode || '	' ||
	co.ohentdate || '	' ||
	co.ohduedate || '	' ||
	DECODE( co.ohinvtype,	2, 'SH',
				5, 'IV',
				8, 'IP' ) || '	' ||
	SUM( co.closed_amount - co.vat_amount ) || '	' ||
	SUM( co.vat_amount ) || '	' ||
	SUM( DECODE ( SIGN( co.closed_amount - co.roam_amount) , 1,
			co.roam_amount, co.closed_amount ) ) || '	' ||
	SUM( co.closed_amount ) || '	' ||
	DECODE( od.market_id,	'G', 'GSM',
				'N', 'NMT',
				'2', 'G+N', 'XXX' )
FROM	donor.closed_orders	co,
	iface2sap.orders	od,
	dealer.dealer_export	de
WHERE	od.ohxact = co.ohxact
AND	de.costcenter_id = co.costcenter_id
AND	co.entdate =
	(
	SELECT	MAX( entdate )
	FROM	donor.closed_orders
	)
GROUP	BY de.costcenter,
	co.prgcode,
	co.entdate,
	co.ohentdate,
	co.ohduedate,
	DECODE( co.ohinvtype,	2, 'SH',
				5, 'IV',
				8, 'IP' ),
	DECODE( od.market_id,	'G', 'GSM',
				'N', 'NMT',
				'2', 'G+N', 'XXX' )
/

SPOOL OFF

SPOOL bad_debt_detailed.txt

SELECT	de.costcenter || '	' ||
	co.entdate || '	' ||
	ca.custcode || '	' ||
	oa.ohrefnum || '	' ||
	oa.ohentdate || '	' ||
	oa.ohduedate || '	' ||
	DECODE( oa.ohinvtype,	2, 'SH',
				5, 'IV',
				8, 'IP' ) || '	' ||
	( co.closed_amount - co.vat_amount ) || '	' ||
	co.vat_amount || '	' ||
	DECODE ( SIGN( co.closed_amount - co.roam_amount) , 1,
			co.roam_amount, co.closed_amount ),
	co.closed_amount || '	' ||
	DECODE( od.market_id,	'G', 'GSM',
				'N', 'NMT',
				'2', 'G+N', 'XXX' )
FROM	donor.closed_orders	co,
	dealer.dealer_export	de,
	orderhdr_all		oa,
	customer_all		ca,
	iface2sap.orders	od
WHERE	de.costcenter_id = co.costcenter_id
AND	oa.ohxact = co.ohxact
AND	ca.customer_id = co.customer_id
AND	od.ohxact = co.ohxact
AND	co.entdate =
	(
	SELECT	MAX( entdate )
	FROM	donor.closed_orders
	)
/

SPOOL OFF
