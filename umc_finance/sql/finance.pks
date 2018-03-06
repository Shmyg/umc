/*
|| Some useful progs to get financial data for the customer 
||
|| Created by Shmyg
|| $Id: finance.pks,v 1.1 2004/05/25 11:23:48 shmyg Exp $
*/

CREATE	OR REPLACE
PACKAGE	&owner..finance

AS
FUNCTION	open_orders
	(
	i_customer_id	NUMBER,
	i_order_type	VARCHAR := 'IN',
	i_invoice_type	NUMBER := NULL,
	i_from_date	DATE := TO_DATE( '01.01.1990', 'DD.MM.YYYY' ),
	i_to_date	DATE := SYSDATE
	)
RETURN	donor..order_tab
END;
/

SHOW ERROR
