set SERVEROUTPUT ON;
declare 

  x_return_status VARCHAR2(10);
  x_msg_count     NUMBER;
  x_msg_data      VARCHAR2(3000);
  
  l_rec_retorno   xxfr_pck_interface_integracao.rec_retorno_integracao;
  
  l_retorno       clob;
  l_msg_retorno   varchar2(3000);

  op              number := 1;     
  l_delivery_id   number := 249025;
  l_trip_id       number := 25009;
  p_id_integracao number := 1172;

  isCommit        boolean := false;
  
begin
  if (op in (1,2,3)) then
    UPDATE xxfr_integracao_detalhe 
    SET IE_STATUS_PROCESSAMENTO = 'PENDENTE' 
    WHERE ID_INTEGRACAO_DETALHE = p_id_integracao
    ; 
    commit;
  end if;
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
      p_tipo_liberacao => NULL,
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
    XXFR_WSH_PCK_INT_ENTREGA.processar_om_backorder(
      p_delivery_id => l_delivery_id, 
      p_trip_id     => l_trip_id,
      x_retorno     => l_retorno
   );
  end if;
  --
  if (op=7) then
    XXFR_WSH_PCK_INT_ENTREGA.processar_trip_confirm(
      p_trip_id     => l_trip_id, 
      p_action_code => 'TRIP-CONFIRM',
      x_retorno     => l_retorno
    );
  end if;
  if (op=8) then
    XXFR_WSH_PCK_INT_ENTREGA.processar_conteudo_firme (
      p_delivery_id => l_delivery_id, 
      p_action_code => 'PLAN',
      x_retorno     => l_retorno
    );
    dbms_output.put_line(l_retorno);
    XXFR_WSH_PCK_INT_ENTREGA.processar_percurso_firme (
      p_trip_id     => l_trip_id, 
      p_action_code => 'PLAN',
      x_retorno     => l_retorno
    );
  end if;
  
  dbms_output.put_line(l_retorno);
exception when others then
  dbms_output.put_line('Erro da Chamada não previsto:'||sqlerrm);
end;
/


/*

-- ***************************************************************************************************
--  INTEGRACAO
-- ***************************************************************************************************

select * from xxfr_integracao_detalhe 
where 1=1
  and id_integracao_detalhe = -113
  --and id_transacao = 159508
  --and cd_interface_detalhe = 'PROCESSAR_ENTREGA'
  --and cd_interface_detalhe = 'CONFIRMAR_ENTREGA'
  --and DS_DADOS_RETORNO like '%117%'
order by dt_atualizacao desc
;

select * 
from xxfr_integracao_detalhe 
where 1=1
  and CD_INTERFACE_DETALHE = 'PROCESSAR_ENTREGA' 
  --and id_integracao_detalhe = 11393
order by 1 desc
;

select 
  id_integracao_cabecalho, dt_criacao, nm_usuario_criacao, cd_programa_criacao 
from  xxfr_integracao_cabecalho 
where id_integracao_cabecalho = 7225;


select * --id_integracao_detalhe, ie_status_processamento, tp_operacao, dt_criacao, dt_atualizacao, nm_percurso, cd_tipo_ordem_venda, nu_ordem_venda, nu_linha_ordem_venda, nu_envio_linha_ordem_venda 
from xxfr_wsh_vw_int_proc_entrega 
where 1=1
  --and nu_ordem_venda = '7'
  --and nm_percurso = '011_25697'
  --and id_integracao_detalhe=10819
  and id_integraco_detalhe= 11154
order by nu_ordem_venda, nu_linha_ordem_venda, nu_envio_linha_ordem_venda, ID_INTEGRACAO_DETALHE
;
-- ***************************************************************************************************
--  LOGS
-- ***************************************************************************************************
select ds_escopo, nvl(ds_log,' ') log
from xxfr_logger_log
where 1=1
  and upper(ds_escopo) = 'PROCESSAR_ENTREGA_1172'
  --and upper(ds_escopo) = 'XXFR_RI_PCK_INTEGRACAO_AR_261053' 
  --and DT_CRIACAO >= sysdate -1
order by 
  --DT_CRIACAO desc,
  id
;

"  1) Erro inesperado: Erro na Rotina WSH_TRIPS_PVT.CREATE_TRIP,  Erro Oracle - -1
ORA-00001: restrição exclusiva (WSH.WSH_TRIPS_U2) violada"

"  1) Erro inesperado: Erro na Rotina WSH_TRIPS_PVT.CREATE_TRIP,  Erro Oracle - -1
ORA-00001: restrição exclusiva (WSH.WSH_TRIPS_U2) violada"

"  1) Erro inesperado: Erro na Rotina WSH_TRIPS_PVT.CREATE_TRIP,  Erro Oracle - -1
ORA-00001: restrição exclusiva (WSH.WSH_TRIPS_U2) violada"

select DS_LOG 
from xxfr_logger_log x 
where x.ds_escopo = 'PROCESSAR_ENTREGA_572' order by ID ;

select ds_escopo, nvl(ds_log,' ') log
from xxfr_logger_logs_60_min x
where 1=1 
  and x.dt_criacao >= sysdate -1
  and upper(ds_escopo) like upper('processar_entrega_%')
order by id;

-- ***************************************************************************************************
--  OUTROS
-- ***************************************************************************************************

select * from xxfr_sif_vw_agricola_principio;
select * from MTL_TXN_REQUEST_LINES_V where REQUEST_NUMBER=231029;

select lot_control_code,  from mtl_system_items_b where inventory_item_id = '46002';

SELECT * FROM FND_USER where user_id = 1511

select RESERVATION_ID, ORGANIZATION_ID, INVENTORY_ITEM_ID, RESERVATION_QUANTITY, SUBINVENTORY_CODE, LOCATOR_ID, LOT_NUMBER 
from MTL_RESERVATIONS_ALL_V
where 1=1
  --and ORGANIZATION_ID   = 103
  --and INVENTORY_ITEM_ID = 13588
  and DEMAND_SOURCE_LINE_ID = 219394 --Linha da OE

--CHECAGEM DOS LOTES...
select distinct 
  moqd.inventory_item_id, msib.SEGMENT1, msib.DESCRIPTION, 
  (mil.segment1||'.'||mil.segment2||'.'||mil.segment3||'.'||mil.segment4) cd_endereco_estoque, mil.subinventory_code , moqd.lot_number 
from 
  mtl_onhand_quantities_detail moqd,
  mtl_system_items_b           msib,
  mtl_item_locations           mil,
  org_organization_definitions ood
where 1=1
  and moqd.locator_id           = mil.inventory_location_id
  and moqd.organization_id      = mil.organization_id
  and msib.inventory_item_id    = moqd.inventory_item_id
  and msib.organization_id      = moqd.organization_id 
  and mil.organization_id       = ood.organization_id
  and moqd.inventory_item_id    = 46002  -- ID Item
  and msib.segment1             = '79792' -- Cod Item
  and ood.organization_code     = '22L'
  and mil.segment1||'.'||mil.segment2||'.'||mil.segment3||'.'||mil.segment4 = 'MPG.00.101.00'
;

*/



