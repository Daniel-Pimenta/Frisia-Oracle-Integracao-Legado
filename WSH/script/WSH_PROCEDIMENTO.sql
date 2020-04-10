set SERVEROUTPUT ON;
declare 

  x_return_status VARCHAR2(10);
  x_msg_count     NUMBER;
  x_msg_data      VARCHAR2(3000);
  
  l_rec_retorno   xxfr_pck_interface_integracao.rec_retorno_integracao;
  
  l_retorno       clob;
  l_msg_retorno   varchar2(3000);

  op              number := 7;     
  l_delivery_id   number := 218034;
  l_trip_id       number := 227026;
  p_id_integracao number := -175;

  isCommit        boolean := false;
  
begin

  UPDATE xxfr_integracao_detalhe 
  SET IE_STATUS_PROCESSAMENTO = 'PENDENTE' 
  WHERE ID_INTEGRACAO_DETALHE = p_id_integracao
  ; 
  commit;
  --
  if (op = 1) then
    XXFR_WSH_PCK_INT_ENTREGA.processar_entrega(
      p_id_integracao_detalhe => p_id_integracao,
      p_commit                => isCommit,
      p_retorno               => l_retorno
    ); 
  end if;
  if (op = 2) then
    XXFR_WSH_PCK_INT_ENTREGA.cancelar_entrega(
      p_id_integracao_detalhe => p_id_integracao,
      p_commit                => isCommit,
      p_retorno               => l_retorno
    );
  end if;
  if (op = 3) then
    XXFR_WSH_PCK_INT_ENTREGA.confirmar_entrega(
      p_id_integracao_detalhe => p_id_integracao,
      p_commit                => isCommit,
      p_retorno               => l_retorno
    );
  end if;
  if (op = 4) then
    XXFR_WSH_PCK_INT_ENTREGA.proc_delivery_pick_release(
      p_delivery_id    => l_delivery_id,
      p_trip_id        => null,
      p_r              => 1,
      p_tipo_liberacao => null,
      x_msg_retorno    => l_msg_retorno,
      x_retorno        => l_retorno
    );
  end if;
  if (op = 5) then
    xxfr_wsh_pck_transacoes.associar_percurso_entrega(
      p_delivery_id => 74080,
      p_trip_id     => 68094,
      x_retorno     => l_retorno
    );  
  end if;
  --
  if (op=6) then
    XXFR_WSH_PCK_INT_ENTREGA.cancelar_entrega(
      p_trip_id => l_trip_id, 
      p_commit  => isCommit,
      x_retorno => l_retorno
   );
  end if;
  if (op=66) then
    XXFR_WSH_PCK_INT_ENTREGA.processar_backorder(
      p_delivery_id => l_delivery_id, 
      x_retorno => l_retorno
   );
  end if;
  --
  if (op=7) then
    XXFR_WSH_PCK_INT_ENTREGA.processar_trip_confirm(
      p_trip_id     => l_trip_id, 
      p_action      => 'TRIP-CONFIRM',
      x_retorno     => l_retorno
    );
  end if;
  dbms_output.put_line(l_retorno);
end;
/

/*

select * from MTL_TXN_REQUEST_LINES_V where REQUEST_NUMBER=231029;

212064

set SERVEROUTPUT ON;
declare
  l_return_status varchar2(10);
  l_msg_count     number;
  l_msg_data      varchar2(3000);
begin
  INV_MO_BACKORDER_PVT.BACKORDER(
    p_line_id       => 212064,
    x_return_status => l_return_status,
    x_msg_count     => l_msg_count,
    x_msg_data      => l_msg_data
  );
  dbms_output.put_line('  Retorno :'||l_return_status);
  if (l_return_status <> 'S') then
    for i in 1 .. l_msg_count loop
      l_msg_data := fnd_msg_pub.get( 
        p_msg_index => i, 
        p_encoded   => 'F'
      );
      dbms_output.put_line( i|| ') '|| l_msg_data);
    end loop;
  end if;
end;
/


select lot_control_code,  from mtl_system_items_b where inventory_item_id = '46002';

select * from xxfr_integracao_detalhe 
where 1=1
  and id_integracao_detalhe = 7987
  --and id_transacao = 159508
  --and cd_interface_detalhe = 'PROCESSAR_ENTREGA'
  --and cd_interface_detalhe = 'CONFIRMAR_ENTREGA'
  --and DS_DADOS_RETORNO like '%117%'
order by dt_atualizacao desc
;

select * from xxfr_integracao_detalhe 
where 1=1
  --and CD_INTERFACE_DETALHE = 'PROCESSAR_ENTREGA' 
  and id_integracao_detalhe = 8510 --8288
order by 1 desc
;
select id_integracao_cabecalho, dt_criacao, nm_usuario_criacao, cd_programa_criacao from  xxfr_integracao_cabecalho where id_integracao_cabecalho = 7225;


select ds_escopo, nvl(ds_log,' ') log
--from xxfr_logger_log x
from xxfr_logger_log x --_60_min x
where 1=1 
  and x.dt_criacao >= sysdate -1
  and upper(ds_escopo) = upper('processar_entrega_5708')
order by id;

select * 
from xxfr_wsh_vw_int_proc_entrega 
where 1=1
  --and nu_ordem_venda = '684'
  and nm_percurso = '011_25676'
  --and id_integracao_detalhe=8087
;

select ds_escopo, nvl(ds_log,' ') log
from xxfr_logger_log
where 1=1
and upper(ds_escopo) like 'XXFR_RI_PCK_INTEGRACAO_AR%'--'CONFIRMAR_ENTREGA_-175'
and DT_CRIACAO >= sysdate -1
order by 
  --DT_CRIACAO desc
  id
;

ID_TRANSACAO_DETALHE = 8510

select RESERVATION_ID, ORGANIZATION_ID, INVENTORY_ITEM_ID, RESERVATION_QUANTITY, SUBINVENTORY_CODE, LOCATOR_ID, LOT_NUMBER 
from MTL_RESERVATIONS_ALL_V
where 1=1
  --and ORGANIZATION_ID   = 103
  --and INVENTORY_ITEM_ID = 13588
  and DEMAND_SOURCE_LINE_ID = 219394 --Linha da OE

select * from xxfr_logger_log x where x.ds_escopo = 'CANCELAR_ENTREGA_8316' order by dt_criacao ;

*/



