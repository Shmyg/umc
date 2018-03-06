ALTER SESSION SET ISOLATION_LEVEL SERIALIZABLE;

CREATE	MATERIALIZED VIEW customer_data
BUILD	DEFERRED
REFRESH	COMPLETE ON DEMAND
AS
SELECT	ca.customer_id,
	ca.custcode,
	cc.cclname,
	ce.cost_desc,
	pg.prgname,
	NVL( ca.cscurbalance, 0 ) cscurbalance,
	NVL( ca.csclimit, 0 ) csclimit
FROM	customer_all	ca,
	costcenter	ce,
	ccontact_all	cc,
	pricegroup_all	pg
WHERE	ce.cost_id = ca.costcenter_id
AND	cc.customer_id = ca.customer_id
AND	pg.prgcode = ca.prgcode
AND	cc.cccontract = 'X'
AND	cc.ccseq =
	(
	SELECT	MAX( ccseq )
	FROM	ccontact_all
	WHERE	customer_id = cc.customer_id
	AND	cccontract = 'X'
	)
AND	ca.paymntresp = 'X'
AND	ca.cstype = 'a'
ORDER	BY ce.cost_desc,
	ca.customer_id
/


CREATE	MATERIALIZED VIEW customer_contracts
BUILD	DEFERRED
REFRESH	COMPLETE ON DEMAND
AS
SELECT	cu.customer_id,
	cs.co_id,
	ca.sccode,
	dn.dn_num
FROM	customer_data		cu,
	contract_all		ca,
	contract_history	ch,
	contr_services_cap	cs,
	directory_number	dn
WHERE	ca.co_id = ch.co_id
AND	cs.co_id = ch.co_id
AND	dn.dn_id = cs.dn_id
AND	cs.seqno =
	(
	SELECT	MAX( seqno )
	FROM	contr_services_cap
	WHERE	co_id = cs.co_id
	AND	sncode = cs.sncode
	)
AND	ca.customer_id IN
	(
	SELECT	customer_id
	FROM	customer_all
	CONNECT	BY PRIOR customer_id = customer_id_high
	AND	paymntresp IS NULL
	START	WITH customer_id = cu.customer_id
	)
AND	ch.ch_status = 'a'
AND	ch.ch_seqno =
	(
	SELECT	MAX( ch_seqno )
	FROM	contract_history
	WHERE	co_id = ca.co_id
	)
/