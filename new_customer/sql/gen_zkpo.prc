CREATE	OR REPLACE
PROCEDURE	&owner..gen_zkpo
	(
	o_zkpo	OUT VARCHAR2
	)
IS
	TYPE	numbers_array
	IS	VARRAY(10)
	OF	NUMBER;

	my_array	numbers_array;

	v_length	NUMBER;
	i		BINARY_INTEGER;
	v_sum		NUMBER := 0;
	v_contr_num	NUMBER;
	v_last_num	NUMBER;

	v_random_number	BINARY_INTEGER;
	v_seed		NUMBER := TO_NUMBER( TO_CHAR( SYSDATE, 'SSHH24DDMI' ) );

BEGIN

	DBMS_RANDOM.INITIALIZE( v_seed );

	v_random_number := ABS( dbms_random.random );

	DBMS_RANDOM.TERMINATE;

	o_zkpo := SUBSTR( TO_CHAR( v_random_number ), 1, 8 );

	IF	(
		o_zkpo > 30000000
		AND
		o_zkpo < 60000000
		)
	THEN
		my_array := numbers_array( 1, 2, 3, 4, 5, 6, 7 );
	ELSE
		my_array := numbers_array( 7, 1, 2, 3, 4, 5, 6 );
	END	IF;

	FOR	i IN 1..7
	LOOP
		v_sum := v_sum + TO_NUMBER( SUBSTR( o_zkpo, i, 1 ) ) * my_array(i);
	END	LOOP;

	v_contr_num := MOD( v_sum, 11 );

	IF	v_contr_num = 10
	THEN
		IF	(
			o_zkpo > 30000000
			AND
			o_zkpo < 60000000
			)
		THEN
			my_array := numbers_array( 3, 4, 5, 6, 7, 8, 9 );
		ELSE
			my_array := numbers_array( 9, 3, 4, 5, 6, 7, 8 );
		END	IF;

		v_sum := 0;

		FOR	i IN 1..7
		LOOP
			v_sum := v_sum + TO_NUMBER( SUBSTR( o_zkpo, i, 1 ) ) * my_array(i);
		END	LOOP;

		v_contr_num := MOD( v_sum, 11 );

		IF	v_contr_num = 10
		THEN
			v_contr_num := 0;
		END	IF;
	END	IF;

	o_zkpo := SUBSTR( o_zkpo, 1, 7 ) || TO_CHAR( v_contr_num );

END	gen_zkpo;
/

SHOW ERROR