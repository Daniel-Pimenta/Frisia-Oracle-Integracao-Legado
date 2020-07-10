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
  h.order_type_id              id_tipo_ordem,
  (select name from oe_transaction_types_tl where 1=1 and LANGUAGE='PTB' and transaction_type_id = h.order_type_id) tipo_ordem,
  l.line_type_id               id_tipo_linha,
  (select name from oe_transaction_types_tl where 1=1 and LANGUAGE='PTB' and transaction_type_id = l.line_type_id) tipo_linha,
  l.flow_status_code,
  --
  h.sold_to_org_id             id_cliente,
  hca.account_number           num_cliente,  
  hp.party_name                cliente, 
  --
  wdd.organization_id          organization_id,
  (
    select ood.organization_code 
    from org_organization_definitions ood 
    where ood.organization_id=wdd.organization_id
  ) organization_code,
  --
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
  wdd.unit_price                 preco_unitario, 
  wdd.currency_code,
  --
  wnd.gross_weight               peso_pedido,
  wdd.weight_uom_code            un_peso_pedido,
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
  wdd.attribute15              referencias,
  --
  trip.trip_id, 
  trip.name                    nome_percurso,
  --
  trip.vehicle_item_id,
  trip.vehicle_number,
  trip.vehicle_organization_id,
  --
  trip.operator                nome_motorista,
  trip.attribute1              cpf_motorista,
  nvl(trip.attribute2,0)       peso_bruto,
  nvl(trip.attribute3,0)       tara,
  nvl(trip.attribute4,0)       peso_liquido,
  nvl(trip.attribute6,0)       peso_embalagem,
  trip.attribute7              placa_veiculo,
  trip.attribute5              cod_lacre_veiculo,
  trip.attribute13             tipo_referencia_origem,
  trip.attribute14             codigo_referencia_origem,
  trip.status_code             status_percurso,
  wnd.planned_flag             conteudo_firme,
  trip.planned_flag            percurso_firme,
  --
  'SACARIA'                    OM05,
  --
  trip.ATTRIBUTE8  Sacaria_Item,
  trip.ATTRIBUTE9  Sacaria_QTD,
  trip.ATTRIBUTE10 Sacaria_Cliente_Remessa,
  trip.ATTRIBUTE11 Sacaria_Endereco,
  'FIM'   Trailer
from 
  oe_order_headers_all         h,
  oe_order_lines_all           l,
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
      wdl.delivery_id     trip_delivery_id,
      wdl.delivery_leg_id,
      wt.*
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
  --
  and h.header_id            = wdd.source_header_id (+)
  and l.line_id              = wdd.source_line_id (+)
  --
  and wdd.delivery_detail_id = wnd.delivery_detail_id (+)
  and wnd.delivery_id        = trip.trip_delivery_id (+)
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
  --
  --and h.order_number = '2'
  --and l.line_number  = '1'
;
/

select * from oe_order_headers_all ;



select distinct *
--select NUMERO_ORDEM, LINHA, ENVIO, TIPO_ORDEM, LINE_RELEASED_STATUS_NAME, CLIENTE, NOME_ENTREGA, ORDERED_ITEM, ITEM_DESCRIPTION, QTD_ORIGINAL, UNIDADE_ORIGINAL, NOME_PERCURSO, CONTEUDO_FIRME, PERCURSO_FIRME
from XXFR_WSH_VW_INF_DA_ORDEM_VENDA
WHERE 1=1
  --and sacaria_item is not null
  --AND RELEASED_STATUS <> 'C'
  --AND flow_status_code NOT IN ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')
  --and RELEASED_STATUS = 'Y'
  --and MOVE_ORDER_LINE_ID is not null
  --and STATUS_PERCURSO is null
  --and PICK_STATUS_NAME like '%Back%'
  --and delivery_id  in (198024, 198025)
  --and trip_id = 53043
  and OE_HEADER = 210828
  --and oe_line in (145451, 152656)
  --AND delivery_detail_id  IN (73066)
  --and nome_percurso = 'SOL.814154.6' 
  --and ORDERED_ITEM    = '90170'  
  --and ORGANIZATION_CODE = substr('011_VENDA_CONTRA_ORDEM',1,3)
  --   Linhas:{  OE:124-2.3 / 358_VENDA_ORDEM_ADQ
  --and numero_ordem      in ('126')
  --and tipo_ordem        = '124_VENDA_FUTURA'
  --and linha             = '3'
  --and envio             = '1'
  --and organization_id = 137
  --and SPLIT_FROM_DELIVERY_DETAIL_ID is null
ORDER BY NUMERO_ORDEM, LINHA, ENVIO
;

    Percurso:{ Id Percurso        :117057

select * from XXFR_WSH_VW_INT_PROC_ENTREGA 
where 1=1
  --and nu_ordem_venda = '37'
  --AND CD_TIPO_ORDEM_VENDA = '011_VENDA'
  --and ID_INTEGRACAO_cabecalho=-90
  and ID_INTEGRACAO_detalhe=6908
  --and nm_percurso = 'SOL.790020'
;

select distinct RELEASED_STATUS, PICK_STATUS_NAME from  XXFR_WSH_VW_INF_DA_ORDEM_VENDA;
Y	Preparação/Separação Confirmada
C	Entregue
S	Liberado para Depósito
N	Não Pronto para Liberação
R	Pronto para Liberação
B	Com Backorder
D	Cancelado

select * from wsh_delivery_details where freight_terms_code is not null;
select * from wsh_new_deliveries where DELIVERY_ID=31009;
select * from wsh_trips where TRIP_ID = 49032;
  
select distinct 
  wt.trip_id, wt.name, wt.status_code
  ,a.delivery_id
  ,ov.flow_status_code, ov.conteudo_firme, ov.percurso_firme
from 
  wsh_trips wt,
  xxfr_wsh_vw_inf_da_ordem_venda ov,
  (
    select distinct wts.trip_id, wdl.delivery_id
    from 
      wsh_trip_stops    wts,
      wsh_delivery_legs wdl
    where 
      wts.stop_id = wdl.pick_up_stop_id
      or
      wts.stop_id = wdl.drop_off_stop_id
  ) a
where 1=1
  and wt.trip_id = a.trip_id (+)
  and wt.trip_id = ov.trip_id (+)
  and wt.name    ='22L_371854'
;


select * 
from oe_order_holds_all 
where 1=1
  and header_id in (96146,96149) 
  and released_flag  = 'N'
    
    
select l.*
from 
  --OE_ORDER_HEADERS_all h,
  OE_ORDER_LINES_all   l
where 1=1
  --and h.ORDER_NUMBER = '129'
  --and h.ORDER_TYPE   = '011_VENDA_CONTRA_ORDEM'
  --and l.LINE_NUMBER  = '1'
  and l.line_id = 52052
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

