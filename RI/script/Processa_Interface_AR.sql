SET SERVEROUTPUT ON
DECLARE
  l_request_id NUMBER;
BEGIN
  
  xxfr_pck_variaveis_ambiente.inicializar('CLL','UO_FRISIA','JEAN.BEJES'); 
  
  l_request_id := fnd_request.submit_request(
    application      => 'AR',
    program          => 'RAXTRX',
    description      => NULL,
    start_time       => NULL, -- To start immediately
    sub_request      => FALSE,
    argument1        => 'MAIN',
    argument2        => 'T',
    argument3        => '3002',               --batch_source_id
    argument4        => 'NFE_000108_SERIE_0_AUTO',             --batch_source_name
    argument5        => to_char(sysdate,'DD-MON-YY'),        --should be in format  RR-MON-DD
    argument6        => NULL,
    argument7        => NULL,
    argument8        => NULL,
    argument9        => NULL,
    argument10       => NULL,
    argument11       => NULL,
    argument12       => NULL,
    argument13       => NULL,
    argument14       => NULL,
    argument15       => NULL,
    argument16       => NULL,
    argument17       => NULL,
    argument18       => NULL,  --sales_order low
    argument19       => NULL,  --sales_order high
    argument20       => NULL,
    argument21       => NULL,
    argument22       => NULL,
    argument23       => NULL,
    argument24       => NULL,
    argument25       => NULL,
    argument26       => 'Y',
    argument27       => 'Y',
    argument28       => NULL,
    argument29       => 81, -- org_id
    argument30       => chr(0) --end with chr(0)as end of parameters
  );
  COMMIT;
  dbms_output.put_line(l_request_id);
END;
/

/*
select to_char(sysdate,'RR-MON-DD') from dual;

MAIN, T, 1001, NFE_001252_SERIE_15_AUTO, 16-MAR-20          , , , , , , , , , , , , , 511, 511, , , , , , , Y, Y, , 81
MAIN, T, 3002, NFE_000108_SERIE_0_AUTO,  13-MAR-20          , , , , , , , , , , , , ,    ,    , , , , , , , Y, Y, , 81
MAIN, T, 3002, NFE_000108_SERIE_0_AUTO,  2020/02/19 00:00:00, , , , , , , , , , , , ,    ,    , , , , , , , Y, Y, , 81

RAXMTR
1, -99, 1001, NFE_001252_SERIE_15_AUTO, 16-MAR-20, , , , , , , , , , , , , , , , , , , , , Y,

1, 81, 3002, NFE_000108_SERIE_0_AUTO, 2020/03/16 00:00:00, , , , , , , , , , , , , , , , , , , , , Y,

*/