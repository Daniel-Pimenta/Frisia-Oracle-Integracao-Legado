set serveroutput on;
declare
  l_id_tab	            wsh_util_core.id_tab_type;
  l_retorno             varchar2(3000);
begin
  xxfr_pck_variaveis_ambiente.inicializar('ONT','UO_FRISIA');
  /*
  l_id_tab(1):=33058;
  wsh_new_delivery_actions.firm (
    p_del_rows      => l_id_tab,
    x_return_status => l_retorno
  );
  */
  --
  l_id_tab(1):=35015;
  wsh_trips_actions.plan(
    p_trip_rows       => l_id_tab,
    p_action          => 'FIRM',
    x_return_status   => l_retorno
  );
  dbms_output.put_line(l_retorno);
end;
/