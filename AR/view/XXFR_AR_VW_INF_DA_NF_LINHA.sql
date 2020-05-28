create or replace view XXFR_AR_VW_INF_DA_NF_LINHA as
select distinct 
  rctla.customer_trx_id,
  rctla.line_number                          as "numeroLinha",
  msib.segment1                              as "codigoItem",
  msib.description                           as "descricaoItem",
  decode (rctla.sales_order, null, QUANTITY_INVOICED, rctla.quantity_ordered) as "quantidade",
  rctla.uom_code                             as "unidadeMedida",
  rctla.unit_selling_price                   as "valorUnitario",
  --
  wdd.lot_number                             as "codigoLote",
  --
  oe.header_id, oe.line_id,
  oe.order_number                            as "numeroOrdemVenda",
  oe.line_number                             as "numeroLinhaOrdemVenda",
  oe.shipment_number                         as "numeroEnvioLinhaOrdemVenda",
  oe.transactional_curr_code                 as "codigoMoeda",    
  --
  rctla.interface_line_attribute2       as "codigoTipoOrdemVenda",
  rctla.interface_line_attribute2||'_L' as "codigoTipoOrdemVendaLinha",
  oe.name                               as "tipoReferenciaOrigem",
  oe.orig_sys_document_ref              as "codigoReferenciaOrigem",
  oe.orig_sys_line_ref                  as "codigoReferenciaOrigemLinha",
  (
    select osl.qt_area
    from 
      xxfr_wms_ordem_separacao_lin osl
    where 1=1
      and osl.source_order_line_id   = oe.line_id  
      and osl.inventory_item_id      = msib.inventory_item_id
  ) as "areaAtendida",
  null   as "observacao"
from 
  ra_customer_trx_all            rcta,
  ra_customer_trx_lines_all      rctla,
  (
    SELECT distinct 
      oel.header_id, oel.line_id, oeh.order_number, oel.line_number, oel.shipment_number, oes.name
      ,msib.inventory_item_id
      ,msib.organization_id
      ,oel.ship_from_org_id
      ,oeh.transactional_curr_code
      ,oel.orig_sys_document_ref
      ,oel.orig_sys_line_ref
    FROM 
      oe_order_headers_all           oeh,
      oe_order_lines_all             oel,
      oe_order_sources               oes,
      mtl_system_items_b             msib
    WHERE 1=1
      and oeh.header_id                   = oel.header_id
      and oeh.order_source_id             = oes.order_source_id
      and msib.organization_id            = oel.ship_from_org_id
  ) oe,
  wsh_delivery_details           wdd,
  mtl_system_items_b             msib
where 1=1
  and rcta.customer_trx_id            = rctla.customer_trx_id
  and rctla.inventory_item_id         = msib.inventory_item_id
  and rctla.warehouse_id              = msib.organization_id
  and rctla.sales_order               = oe.order_number (+)
  and rctla.interface_line_attribute6 = oe.line_id (+)
  and oe.line_id                      = wdd.source_line_id (+)
  --and rctla.customer_trx_id = 134014
;
/


/*

select * from XXFR_AR_VW_INF_DA_NF_LINHA 
where 1=1
  and customer_trx_id = 260087
  --and line_id = 52052
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