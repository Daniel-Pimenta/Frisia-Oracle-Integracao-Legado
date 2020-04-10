/*
{
  "idTransacao": -1,
  "versaoPayload": 1.0,
  "sistemaOrigem": "SIF.VEI",
  "codigoServico": "SINCRONIZAR_NOTA_FISCAL",
  "usuario": "renato.sampaio",
  "publicarNotaFiscal": {
    "codigoUnidadeOperacional": "UO_FRISIA",
    "numeroCnpjFilial": "7775180001",
    "dataCriacao": "2019-12-10",
    "numeroNotaFiscal": "1451512",
    "codigoSerie": "1",
    "dataEmissao": "2019-12-10",
    "codigoCliente": 957,
    "numeroPropriedadeEntrega": 415151,
    "numeroPropriedadeFaturamento": 415151,
    "observacao": "blablabla",
    "chaveSefaz": "35100700060610000695550010000000511968332259"
    "itemNotaFiscal": [
      {
        "numeroLinha":"1",
        "codigoItem":80120,
        "quantidade":100.50,
        "unidadeMedida":"KG",
        "valorUnitario":15.15,
        "codigoMoeda":"BRL",
        "codigoLote": "ABREDC/1548",
        "observacao": "blablablaLinha",
        "ordemVenda": {
          "numeroOrdemVenda": 1451,
          "codigoTipoOrdemVenda": "010_VENDA_SERVICO",
          "numeroLinha": "1.1",
          "tipoReferenciaOrigem": "SOLICITACAO_RETIRADA",
          "areaAtendida": 50.45                                                                 
        }
      }
    ]
  }
}
*/

select * from apps.HR_OPERATING_UNITS;
select * from ra_customer_trx_all;
select * from hz_cust_accounts;

select rcta.org_id,
  rcta.customer_trx_id, rcta.trx_number, rcta.cust_trx_type_id, rcta.trx_date, rcta.interface_header_context,
  wnd.SOURCE_HEADER_ID, wnd.DELIVERY_ID, wnd.NAME 
from 
  ra_customer_trx_all rcta,
  wsh_new_deliveries  wnd
where 1=1
  and rcta.interface_header_attribute3 = wnd.name
  and interface_header_context         = 'ORDER ENTRY'
;

select 
  h.header_id, h.org_id, h.order_type_id, h.order_number, h.creation_date, h.flow_status_code,
  l.line_id, l.line_number,  l.shipment_number, l.ordered_item, l.order_quantity_uom, l.ordered_quantity, l.inventory_item_id,
  w.source_header_type_name, w.customer_id, w.item_description, w.organization_id
from
  oe_order_headers_all         h,
  oe_order_lines_all           l,
  wsh_delivery_details         w
where 1=1
  and h.header_id            = l.header_id
  and h.header_id            = w.source_header_id
  and l.line_id              = w.source_line_id
  and h.flow_status_code not in ('CANCELLED','CLOSED','INVOICE_INCOMPLETE')
  --and w.source_header_type_name = '010_VENDA_SERVICO'
order by 1, 8,9
;

select * --SOURCE_HEADER_ID, DELIVERY_ID, NAME 
from WSH_NEW_DELIVERIES;

select * from ra_customer_trx_lines_all;
