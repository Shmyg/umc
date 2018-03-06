CREATE	OR REPLACE
TRIGGER	&owner..aft_ins_on_cust_paid
AFTER	INSERT ON reactor.customers_paid
BEGIN
	reactor.debtors.fill_customer_payments;
END;
/