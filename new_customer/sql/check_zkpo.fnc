CREATE OR REPLACE
FUNCTION	&owner..check_zkpo
	(
	i_zkpo	IN VARCHAR2
	)
RETURN	NUMBER
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

BEGIN

	v_length := LENGTH( i_zkpo );

	-- Checking zkpo length
	IF	v_length != 8
	THEN
		RETURN	-1;
	END IF;

	IF	(
		i_zkpo > 30000000
		AND
		i_zkpo < 60000000
		)
	THEN
		my_array := numbers_array( 1, 2, 3, 4, 5, 6, 7 );
	ELSE
		my_array := numbers_array( 7, 1, 2, 3, 4, 5, 6 );
	END	IF;

	FOR	i IN 1..7
	LOOP
		v_sum := v_sum + TO_NUMBER( SUBSTR( i_zkpo, i, 1 ) ) * my_array(i);
	END	LOOP;

	v_contr_num := MOD( v_sum, 11 );
	v_last_num := TO_NUMBER( SUBSTR( i_zkpo, 8, 1 ) );

	IF	v_contr_num = 10
	THEN
		IF	(
			i_zkpo > 30000000
			AND
			i_zkpo < 60000000
			)
		THEN
			my_array := numbers_array( 3, 4, 5, 6, 7, 8, 9 );
		ELSE
			my_array := numbers_array( 9, 3, 4, 5, 6, 7, 8 );
		END	IF;

		v_sum := 0;

		FOR	i IN 1..7
		LOOP
			v_sum := v_sum + TO_NUMBER( SUBSTR( i_zkpo, i, 1 ) ) * my_array(i);
		END	LOOP;

		v_contr_num := MOD( v_sum, 11 );

	END	IF;

	IF	v_last_num = v_contr_num
		OR	(
			v_last_num = 0
			AND
			v_contr_num = 10
			)
	THEN
		RETURN	0;
	ELSE
		RETURN	-1;
	END	IF;

END	check_zkpo;
/
SHOW ERROR