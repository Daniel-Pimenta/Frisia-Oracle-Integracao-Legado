set SERVEROUTPUT ON;
declare 

  x_return_status VARCHAR2(10);
  x_msg_count     NUMBER;
  x_msg_data      VARCHAR2(3000);
  
  l_rec_retorno   xxfr_pck_interface_integracao.rec_retorno_integracao;
  
  l_retorno       clob;
  l_msg_retorno   varchar2(3000);
     
  l_delivery_id   number := 40071;
  l_trip_id       number := NULL;
  
  --op              number := 1;
  --p_id_integracao number := 15364;    
  
  op              number := 1;
  p_id_integracao number := 64283;
  
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
--

SELECT * FROM WSH_TRIPS WHERE NAME = 'SOL.814154.6';

select * from xxfr_integracao_detalhe x where x.id_transacao = 377737

set SERVEROUTPUT ON;
declare
  l_retorno       varchar2(3000);
  l_rec_retorno   xxfr_pck_interface_integracao.rec_retorno_integracao;
begin

  processar_percurso_firme(
    p_trip_id     => '',
    p_action_code => 'UNPLAN',
    x_retorno     => l_retorno
  );
  dbms_output.put_line(l_retorno);
  xxfr_wsh_pck_transacoes.confirma_percurso(
    p_trip_id        => '',
    p_action_param   => 'DELETE',
    x_rec_retorno    => l_rec_retorno,
    x_retorno        => l_retorno
  );
  dbms_output.put_line(l_retorno);
exception when others then
  dbms_output.put_line('Erro da Chamada não previsto:'||sqlerrm);
end;


select * from xxfr_logger_log x where x.ds_escopo = 'CANCELAR_ENTREGA_8316' order by dt_criacao ;
select * from MTL_MATERIAL_TRANSACTIONS_TEMP;

SELECT distinct
  oh.transactional_curr_code,
  wdd.freight_terms_code,
  wdd.fob_code,
  wdd.customer_id,
  wdd.organization_id,
  wdd.ship_from_location_id,
  wdd.ship_to_location_id,
  wdd.ship_method_code,
  wdd.carrier_id,
  wdd.service_level,
  wdd.mode_of_transport,
  wdd.gross_weight,
  wdd.weight_uom_code,
  wdd.volume_uom_code
from
  oe_order_headers_all           oh,
  wsh_delivery_details           wdd,
  XXFR_WSH_VW_INF_DA_ORDEM_VENDA ov
where 1=1
  and oh.header_id              = ov.oe_header
  and oh.header_id              = wdd.source_header_id
  and wdd.delivery_detail_id    = ov.delivery_detail_id
  and ov.flow_status_code not in ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')
  and ov.line_released_status_name not in ('Entregue')
  --
  and ov.numero_ordem           = '46' 
  and ov.linha                  = '2' 
  and ov.envio                  = '1'
  and ov.tipo_ordem             = '22L_VENDA_ORDEM_INDUSTRIAL' 


-- ***************************************************************************************************
--  INTEGRACAO
-- ***************************************************************************************************

select * from xxfr_integracao_detalhe 
where 1=1
  --and id_integracao_detalhe = 18874
  --and id_transacao = 159508
  and cd_interface_detalhe = 'PROCESSAR_ENTREGA'
  --and cd_interface_detalhe = 'CONFIRMAR_ENTREGA'
  --and DS_DADOS_RETORNO like '%117%'
  --and ID_TRANSACAO = 316613
order by dt_atualizacao desc
;

select * 
from xxfr_integracao_detalhe 
where 1=1
  --and CD_INTERFACE_DETALHE = 'CONFIRMAR_ENTREGA' 
  --and id_integracao_detalhe = 6585
  and id_transacao = 383788
order by 1 desc
;

select id_integracao_detalhe, ie_status_processamento, tp_operacao, dt_criacao, dt_atualizacao, nm_percurso, cd_tipo_ordem_venda, nu_ordem_venda, nu_linha_ordem_venda, nu_envio_linha_ordem_venda 
from xxfr_wsh_vw_int_proc_entrega 
where 1=1
  and nu_ordem_venda = '26'
  and cd_tipo_ordem_venda = '365_TRANSF_COM_IND'
  --and nu_linha_ordem_venda = '1'
  --and nu_envio_linha_ordem_venda = '1'
  --and nm_percurso = '49033'
  --and id_integracao_detalhe=29522
  --and id_integraco_detalhe= 11154
order by DT_CRIACAO desc --nu_ordem_venda, nu_linha_ordem_venda, nu_envio_linha_ordem_venda, ID_INTEGRACAO_DETALHE
;
-- ***************************************************************************************************
--  LOGS
-- ***************************************************************************************************
select ds_escopo, nvl(ds_log,' ') log
from xxfr_logger_log
where 1=1
  --and upper(ds_escopo) = 'CONFIRMAR_ENTREGA_13180'
  and DT_CRIACAO >= sysdate -0.25
order by 
  --DT_CRIACAO desc,
  id
;

select ds_escopo, DS_LOG 
from xxfr_logger_log x 
where x.ds_escopo like 'CANCELAR_ENTREGA_12648' 
and DT_CRIACAO >= sysdate -1
order by ID ;

select ds_escopo, nvl(ds_log,' ') log
from xxfr_logger_log --s_60_min x
where 1=1 
  and upper(ds_escopo) like 'PROCESSAR_ENTREGA_%'
  --and upper(ds_escopo) = 'PROCESSAR_ENTREGA_17397'
  and DT_CRIACAO >= sysdate -0.5
order by id;

id_integração detalhe = 14852
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



