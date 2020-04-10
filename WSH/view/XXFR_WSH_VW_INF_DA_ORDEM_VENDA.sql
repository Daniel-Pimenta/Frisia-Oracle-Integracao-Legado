--DROP VIEW XXFR_WSH_VW_INF_DA_ORDEM_VENDA;
CREATE OR REPLACE VIEW XXFR_WSH_VW_INF_DA_ORDEM_VENDA AS
select distinct
  h.org_id,
  h.header_id         oe_header,
  l.line_id           oe_line,
  (
    select DISTINCT 'EM RETENCAO' from oe_order_holds_all 
    where (header_id = h.header_id and nvl(line_id,l.line_id) = l.line_id)
    and released_flag  = 'N'
  ) oe_hold,
  --
  h.order_number               numero_ordem,
  l.line_number                linha,
  l.shipment_number            envio,
  ood.organization_id          organization_id,
  ood.organization_code        organization_code,
  h.order_type_id              id_tipo_ordem,
  ot.name                      tipo_ordem,
  l.flow_status_code,
  wdd.released_status,
  (
  select meaning
  from
    fnd_lookup_values flv
  where 1=1
    and flv.lookup_type         = 'PICK_STATUS'
    and flv.lookup_code         = wdd.released_status
    and flv.language            = userenv('LANG')
    and flv.view_application_id = 665
    and flv.security_group_id   = 0
  ) pick_status_name, 
  (
  select meaning
  from
    fnd_lookup_values flv
  where 1=1
    and flv.lookup_type         = 'WSH_LINE_RELEASED_STATUS'
    and flv.lookup_code         = wdd.released_status
    and flv.language            = userenv('LANG')
    and flv.view_application_id = 665
    and flv.security_group_id   = 0
  ) line_released_status_name, 
  (
    select distinct batch_id 
    from wsh_trip_deliverables_v 
    where 1=1
      and trip_id            = trip.trip_id
      and delivery_detail_id = wdd.delivery_detail_id
  )   move_order_number,
  wdd.move_order_line_id, 
  wdd.subinventory, 
  wdd.lot_number, 
  wdd.locator_id, 
  wdd.transaction_id,
  --
  h.sold_to_org_id              id_cliente,
  hca.account_number            num_cliente,  
  hp.party_name                 cliente, 
  --
  wnd.delivery_id               delivery_id,
  wnd.name                      nome_entrega,
  wdd.delivery_detail_id,
  wdd.split_from_delivery_detail_id,
  wdd.cust_po_number            oc_cliente,
  l.ordered_item,
  --
  wdd.inventory_item_id,    
  wdd.item_description,
  --
  wdd.src_requested_quantity     qtd_original,
  wdd.src_requested_quantity_uom unidade_original,
  --
  wdd.requested_quantity         qtd,
  wdd.requested_quantity_uom     unidade,
  -- 
  wdd.unit_price                preco_unitario, 
  wdd.currency_code,
  --
  wnd.GROSS_WEIGHT               qtd_pedido, 
  --wdd.seal_code,
  --
  trip.carrier_id,
  wnd.fob_code, 
  trip.ship_method_code, 
  trip.service_level, 
  trip.mode_of_transport, 

  wnd.global_attribute5        reg_veiculo_antt,    
  wnd.global_attribute8        reg_cavalo_antt,
  --
  wnd.global_attribute6        placa1,
  wnd.global_attribute12       placa2,
  wnd.global_attribute14       placa3,
  wnd.global_attribute16       placa4,
  wnd.global_attribute18       placa5,
  wnd.global_attribute9        cod_lacres,
  wnd.attribute1               cod_controle_entrega_cliente,
  wdd.attribute1               percentual_gordura,
  wnd.planned_flag             conteudo_firme,
  --
  trip.trip_id, 
  trip.name                    nome_percurso,
  --
  trip.planned_flag            percurso_firme,
  trip.vehicle_item_id,
  trip.vehicle_number,
  trip.vehicle_organization_id,
  --
  trip.attribute1              cpf_motorista,
  trip.operator                nome_motorista,
  nvl(trip.attribute2,0)       peso_bruto,
  nvl(trip.attribute3,0)       tara,
  nvl(trip.attribute4,0)       peso_liquido,
  nvl(trip.attribute6,0)       peso_embalagem,
  nvl(trip.attribute5,0)       cod_lacre_veiculo,
  trip.status_code             status_percurso
from 
  oe_order_headers_all         h,
  oe_order_lines_all           l,
  
  oe_transaction_types_tl      ot,
  --
  org_organization_definitions ood,
  --
  apps.hz_locations            hl,
  apps.hz_party_sites          hps,
  apps.hz_cust_site_uses_all   hcsua,
  apps.hr_operating_units      hou,
  (select distinct org_id, cust_account_id, cust_acct_site_id, bill_to_flag, party_site_id from apps.hz_cust_acct_sites_all) hcasa,
  apps.hz_cust_accounts        hca,
  apps.hz_parties              hp,
  --
  wsh_delivery_details         wdd,
  --
  (
    select 
      wda.delivery_assignment_id, 
      wda.delivery_detail_id, 
      wnd.* 
    from 
      wsh_delivery_assignments wda, 
      wsh_new_deliveries       wnd      
    where 1=1
      and wda.delivery_id        = wnd.delivery_id
  ) wnd,
  (
    select
      wdl.delivery_id,
      wt.trip_id,
      wt.name,
      wdl.delivery_leg_id,
      --
      wt.planned_flag,
      wt.vehicle_item_id,
      wt.vehicle_number,
      wt.vehicle_organization_id,
      wt.carrier_id,
      wt.ship_method_code,
      wt.service_level,
      wt.mode_of_transport,
      --
      wt.status_code,
      wt.operator,
      wt.attribute1,  --cpf morotista
      wt.attribute2,  --bruto
      wt.attribute3,  --tara
      wt.attribute4,  --liquido
      wt.attribute6,   --embalagem
      wt.attribute5   --cod_lacre_veiculo
    from   
      wsh_trips_v              wt,
      wsh_trip_stops           wtp,
      wsh_trip_stops           wtd,
      wsh_delivery_legs        wdl
    where 1=1
      and wt.trip_id             = wtp.trip_id
      and wt.trip_id             = wtd.trip_id
      and wtp.stop_id            = wdl.pick_up_stop_id
      and wtd.stop_id            = wdl.drop_off_stop_id 
      --and wt.status_code         = 'OP'
  ) trip
where 1=1
  and h.header_id            = l.header_id
  and h.order_type_id        = ot.transaction_type_id 
  --
  and h.header_id            = wdd.source_header_id (+)
  and l.line_id              = wdd.source_line_id (+)
  --
  and ood.operating_unit     = h.org_id
  and ood.organization_code  = substr(ot.name,1,3)
  and ood.organization_id    = wdd.organization_id (+)
  --
  and wdd.delivery_detail_id = wnd.delivery_detail_id (+)
  and wnd.delivery_id        = trip.delivery_id (+)
  --and trip.trip_id           = wtd.trip_id (+)
  --
  and hcsua.site_use_code     = 'BILL_TO'
  --
  and hcasa.cust_account_id   = h.sold_to_org_id
  and hcasa.bill_to_flag      in ('Y','P')
  and hcasa.org_id            = hou.organization_id
  and hcasa.party_site_id     = hps.party_site_id
  and hcasa.cust_acct_site_id = hcsua.cust_acct_site_id
  
  and hca.cust_account_id     = h.sold_to_org_id
  and hca.party_id            = hp.party_id
  --
  and hl.location_id          = hps.location_id
  and hps.party_id            = hp.party_id
;
/



select *
from XXFR_WSH_VW_INF_DA_ORDEM_VENDA
WHERE 1=1
  --AND RELEASED_STATUS <> 'C'
  --AND flow_status_code NOT IN ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')
  --and MOVE_ORDER_LINE_ID is not null
  --and STATUS_PERCURSO is null
  --and PICK_STATUS_NAME like '%Back%'
  --and delivery_id  in (198024, 198025)
  --and trip_id =  226029
  --and OE_HEADER = 229099
  --AND delivery_detail_id  IN (223026,223027,223028)
  and nome_percurso = '011_25676' 
  --and ORDERED_ITEM    = '90170'  
  --and ORGANIZATION_CODE = substr('011_VENDA_CONTRA_ORDEM',1,3)
  --          OE:806 1.1 - 124_VENDA_FUTURA
  --and tipo_ordem        = '124_VENDA_FUTURA'
  --and linha             = '1'
  --and numero_ordem      in ('806')
  --  Na Argentina os efeitos da quarentena tambem est�o sendo sentidos...
  --and SPLIT_FROM_DELIVERY_DETAIL_ID is null
  --and envio            = '1'
ORDER BY TIPO_ORDEM, NUMERO_ORDEM, LINHA, ENVIO, RELEASED_STATUS
;

select distinct RELEASED_STATUS, PICK_STATUS_NAME from  XXFR_WSH_VW_INF_DA_ORDEM_VENDA;
Y	Prepara��o/Separa��o Confirmada
C	Entregue
S	Liberado para Dep�sito
N	N�o Pronto para Libera��o
R	Pronto para Libera��o
B	Com Backorder
D	Cancelado

select * from wsh_deliverables_v where DELIVERY_DETAIL_ID=256074;
select * from wsh_delivery_details where DELIVERY_DETAIL_ID = 257066;
select * from wsh_new_deliveries where DELIVERY_ID=0;
select * from wsh_trips where name = 'S200403003';
  
  mtl_txn_request_lines mtrl
where 1=1
  and wdd.move_order_line_id = mtrl.line_id
  and wdd.move_order_line_id in ('224044','224045','224043')
;


select h.*
from 
  OE_ORDER_HEADERS_all h
  OE_ORDER_LINES_V  l
where 1=1
  --and h.ORDER_NUMBER = '129'
  --and h.ORDER_TYPE   = '011_VENDA_CONTRA_ORDEM'
  --and l.LINE_NUMBER  = '1'
  and h.ORG_ID       = l.ORG_ID
  and h.HEADER_ID    = l.HEADER_ID
;


select BATCH_ID, DELIVERY_ID, sum(REQUESTED_QUANTITY) total
from WSH_TRIP_DELIVERABLES_V where trip_id = 185047
group by BATCH_ID, DELIVERY_ID
;

select cd_item, cd_subinventario, cd_endereco, nr_lote, sum(qt_item) qtd 
from xxfr_inv_vw_saldo_estoque 
where 1=1
  --and cd_item                   = '154203'
  and cd_organizacao_inventario = '358'
group by cd_item, cd_subinventario, cd_endereco, nr_lote
order by 1,2,3,4
;

--verificar reserva
select RESERVATION_ID, ORGANIZATION_ID, INVENTORY_ITEM_ID, RESERVATION_QUANTITY, SUBINVENTORY_CODE, LOCATOR_ID, LOT_NUMBER 
from MTL_RESERVATIONS_ALL_V
where 1=1
  --and ORGANIZATION_ID   = 103
  --and INVENTORY_ITEM_ID = 13630
  and DEMAND_SOURCE_LINE_ID = 178252


select 
  H.*
from 
  oe_order_headers_all     h,
  oe_order_lines_all       l,
  oe_transaction_types_tl  tt,
  wsh_delivery_details     wdd
where 1=1
  and h.header_id     = l.header_id
  And H.order_type_id = tt.transaction_type_id 
  and l.line_id       = wdd.source_line_id (+)
  and h.header_id = 188195
  and TT.LANGUAGE     = 'PTB'
;


Select distinct Ot.NAME , h.*
From 
  apps.oe_transaction_types_tl Ot, 
  apps.oe_order_headers_all    h,
  apps.oe_order_lines_all      l
Where 1=1
 and H.Order_Number in ('88','87')
 --and ot.name = '124_VENDA']
 and h.HEADER_ID = l.HEADER_ID
 and Ot.NAME ='358_VENDA'
 And H.order_type_id = ot.transaction_type_id 

;


select * from dba_dependencies
where 1=1
--and name='XXFR_OPM_PCK_INT_QUALIDADE'
and referenced_name like 'XXFR%'
order by referenced_name, referenced_type;


INTGR-09 - Manter Entrega (Processar Entrega/Confimar Entrega/Cancelar Entrega)      
XXFR_WSH_PCK_INT_ENTREGA
XXFR_WSH_PCK_TRANSACOES
XXFR_WSH_VW_INF_DA_ORDEM_VENDA
XXFR_WSH_VW_INT_CANC_ENTREGA
XXFR_WSH_VW_INT_CONF_ENTREGA
XXFR_WSH_VW_INT_PROC_ENTREGA
--
INTGR-15 - Manter Ordem de Retirada/Separa��o de Sementes (Criar/Cancelar)
XXFR_WMS_VW_INT_PROC_SEPARACAO
XXFR_WMS_PCK_INT_SEPARACAO
--
INTGR-17 - Manter Recebimento RI (Criar Lan�amento a partir do AR e Devolu��o via RI)
XXFR_RI_PCK_INT_NFDEVOLUCAO
XXFR_AR_PCK_GERA_RI
XXFR_RI_VW_INT_PROC_DEVOLUCAO
XXFR_RI_VW_INF_DA_LINHA_NFE
XXFR_RI_VW_INF_DA_NFENTRADA
--
INTGR-20 - Manter Contabilidade (Criar Lan�amento)
XXFR_GL_PCK_INT_LOTE_CONTABIL
XXFR_GL_PCK_TRANSACOES
XXFR_GL_VW_INT_LOTECONTABIL
--

C:\orant\BIN\ifrun60.EXE \\servoracle\exec-vrs6i\VRSMENU.fmx desen/pandora@bcad
\\Servoracle\exec-vrs6i

XXFR_AR_VW_INF_DA_NF_LINHA
XXFR_AR_VW_INF_DA_NF_CABECALHO
XXFR_AR_PCK_INT_SINCRO_NF
--
XXFR_F189_CHECK_HOLDS_PKG
XXFR_F189_INTERFACE_PKG
XXFR_F189_OPEN_INTERFACE_PKG
XXFR_F189_OPEN_PROCESSES_PUB
XXFR_F189_OPEN_INTERFACE_PKG

