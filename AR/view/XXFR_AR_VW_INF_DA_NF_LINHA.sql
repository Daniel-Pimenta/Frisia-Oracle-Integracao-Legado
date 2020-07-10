create or replace view XXFR_AR_VW_INF_DA_NF_LINHA as
select 
  rctla.customer_trx_id,
  rctla.customer_trx_line_id,
  oe.header_id, 
  oe.line_id,
  rctla.sales_order,
  --
  msib.inventory_item_id,
  --
  rctla.quantity_invoiced, 
  rctla.quantity_ordered,
  rctla.uom_code,
  --
  wdd.delivery_detail_id,
  wdd.released_status,
  wdd.lot_number,
  --
  wdd.requested_quantity, 
  wdd.requested_quantity_uom,
  --
  wdd.requested_quantity2,
  wdd.src_requested_quantity_uom2, 
  --
  rctla.line_number                         as "numeroLinha",
  msib.segment1                             as "codigoItem",
  msib.description                          as "descricaoItem",
  rctla.quantity_invoiced                   as "quantidade",
  rctla.uom_code                            as "unidadeMedida",
  rctla.unit_selling_price                  as "valorUnitario",
  oe.order_number                           as "numeroOrdemVenda",
  oe.line_number                            as "numeroLinhaOrdemVenda",
  oe.shipment_number                        as "numeroEnvioLinhaOrdemVenda",
  oe.transactional_curr_code                as "codigoMoeda",    
  rctla.interface_line_attribute2           as "codigoTipoOrdemVenda",
  (
    select name from oe_transaction_types_tl 
    where 1=1 
      and LANGUAGE='PTB' 
      and transaction_type_id = oe.line_type_id
  )                                         as "codigoTipoOrdemVendaLinha",
  oe.name                                   as "tipoReferenciaOrigem",
  oe.orig_sys_document_ref                  as "codigoReferenciaOrigem",
  nvl(
    json_value(oe.ATTRIBUTE19, '$.codigoReferenciaOrigemLinha'), oe.orig_sys_line_ref
  )                                         as "codigoReferenciaOrigemLinha",
  json_value(
    oe.ATTRIBUTE19, '$.tipoReferenciaOrigemLinha'
  )                                         as "tipoReferenciaOrigemLinha",
  null                                      as "observacao",
  oe.attribute14                            as oe_reference_line
from 
  ra_customer_trx_all            rcta,
  ra_customer_trx_lines_all      rctla,
  (
    SELECT distinct 
      oel.header_id, oel.line_id, oeh.order_number, oel.line_number, oel.shipment_number, oes.name, oel.attribute14, oel.attribute19
      ,oel.ship_from_org_id
      ,oeh.transactional_curr_code
      ,oel.orig_sys_document_ref
      ,oel.orig_sys_line_ref
      ,oel.line_type_id
    FROM 
      oe_order_headers_all           oeh,
      oe_order_lines_all             oel,
      oe_order_sources               oes
    WHERE 1=1
      and oeh.header_id                   = oel.header_id
      and oeh.order_source_id             = oes.order_source_id
  ) oe,
  wsh_delivery_details           wdd,
  mtl_system_items_b             msib
where 1=1
  and rcta.customer_trx_id            = rctla.customer_trx_id
  and rctla.inventory_item_id         = msib.inventory_item_id
  and rctla.warehouse_id              = msib.organization_id
  and rctla.interface_line_attribute6 = oe.line_id 
  and nvl(wdd.released_status,'C')    <> 'D'
  and oe.line_id                      = wdd.source_line_id (+)
  --and oe.line_id                      = wos.source_order_line_id (+)
  --
  --and rcta.customer_trx_id in (151269)
;
/


--select attribute19 from oe_order_lines_all where attribute19 is not null;

/*

select * from XXFR_AR_VW_INF_DA_NF_LINHA 
where 1=1
  and customer_trx_id in (128263) 
  --and line_id = 174496
order by 1,2 ;


      select distinct
        l.source_order_line_id, h.DELIVERY_ID, l.id_ordem_separacao_hdr, l.id_ordem_separacao_lin, l.inventory_item_id, 
        --t.primary_quantity, t.lot_number, t.qt_area,
        'FIM' fim
        --sum(t.qt_area) qt_area
      from 
        xxfr_wms_ordem_separacao_tran t,
        xxfr_wms_ordem_separacao_hdr  h,
        xxfr_wms_ordem_separacao_lin  l
      where 1=1
        and h.ID_ORDEM_SEPARACAO_HDR = l.ID_ORDEM_SEPARACAO_HDR
        --and t.id_ordem_separacao_lin = l.id_ordem_separacao_lin
        and l.source_order_line_id   = 116610
    ;





select * from wsh_delivery_details where delivery_detail_id=132222;

select * from ra_customer_trx_lines_all
where customer_trx_id = 244250
;

select *
from XXFR_integracao_detalhe i
where i.cd_interface_detalhe = 'SINCRONIZAR_NOTA_FISCAL'
--and id_integracao_detalhe = '17710'
ORDER BY DT_CRIACAO DESC;



select qt_area from xxfr_wms_ordem_separacao_tran
where id_ordem_separacao_lin in (
  select id_ordem_separacao_lin
  from 
    xxfr_wms_ordem_separacao_lin osl
  where 1=1
    --and osl.source_order_line_id   = oe.line_id  
    --and osl.inventory_item_id      = msib.inventory_item_id
);


select distinct * from XXFR_AR_VW_INF_DA_NF_LINHA 
where 1=1
  and customer_trx_id in (108220,108221)
  --and line_id = 52052
order by 1,2
;

SELECT oel.header_id, oel.line_id, msib.inventory_item_id, msib.organization_id, oel.ship_from_org_id, oeh.transactional_curr_code
FROM 
  oe_order_headers_all           oeh,
  oe_order_lines_all             oel,
  oe_order_sources               oes,
  mtl_system_items_b             msib
WHERE 1=1
  and oeh.header_id                   = oel.header_id
  and oeh.order_source_id             = oes.order_source_id
  and msib.organization_id            = oel.ship_from_org_id
;


select * from ra_customer_trx_lines_all where 1=1 and customer_trx_id = 134014;

*/