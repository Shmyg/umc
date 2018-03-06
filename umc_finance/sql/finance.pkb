/*
|| 
||
|| Created by Shmyg
|| $Id: finance.pkb,v 1.1 2004/05/25 11:23:48 shmyg Exp $
*/

CREATE	OR REPLACE
PACKAGE	BODY &owner..finance
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
AS
	my_order	donor.order_t := donor.order_t();

	orders		donor.order_tab := donor.order_tab();

	i		PLS_INTEGER := 1;

	CURSOR	order_cur
	IS
	SELECT	ohxact,
		ohentdate,
		ohinvamt_gl,
		ohopnamt_gl,
		customer_id,
		ohglar,
		ohrefnum,
		ohstatus,
		ohinvtype,
		1,
		ohuserid,
		co_id
	FROM	orderhdr_all
	WHERE	customer_id = i_customer_id
	AND	order_type = i_order_type
	AND	ohentdate >= i_from_date
	AND	ohentdate < i_to_date;

	v_ohxact		orderhdr_all.ohxact%TYPE;
	v_ohentdate		orderhdr_all.ohentdate%TYPE;
	v_ohinvamt_gl		orderhdr_all.ohinvamt_gl%TYPE;
	v_ohopnamt_gl		orderhdr_all.ohopnamt_gl%TYPE;
	v_customer_id		orderhdr_all.customer_id%TYPE;
	v_ohglar		orderhdr_all.ohglar%TYPE;
	v_ohrefnum		orderhdr_all.ohrefnum%TYPE;
	v_ohstatus		orderhdr_all.ohstatus%TYPE;
	v_ohinvtype		orderhdr_all.ohinvtype%TYPE;
	v_tax_category		orderhdr_all.tax_category%TYPE;
	v_ohuserid		orderhdr_all.ohuserid%TYPE;
	v_co_id			orderhdr_all.co_id%TYPE;

BEGIN

	OPEN	order_cur;
	LOOP
		FETCH	order_cur
		INTO	v_ohxact,
			v_ohentdate,
			v_ohinvamt_gl,
			v_ohopnamt_gl,
			v_customer_id,
			v_ohglar,
			v_ohrefnum,
			v_ohstatus,
			v_ohinvtype,
			v_tax_category,
			v_ohuserid,
			v_co_id;
		EXIT	WHEN order_cur%NOTFOUND;

		orders.EXTEND;

		orders(i) := order_t (
			v_ohxact,
			v_ohentdate,
			v_ohinvamt_gl,
			v_ohopnamt_gl,
			v_customer_id,
			v_ohglar,
			v_ohrefnum,
			v_ohstatus,
			v_ohinvtype,
			v_tax_category,
			v_ohuserid,
			v_co_id
			);

		i := i + 1;

	END	LOOP;

	orders.TRIM;

	RETURN	orders;

END;
/

SHOW ERROR
