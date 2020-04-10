create or replace view XXFR_AR_VW_INF_DA_NF_CABECALHO as
select
  rcta.customer_trx_id,
  rcta.interface_header_context,
  cfe.location_id,
  rctla.warehouse_id,
  hou.NAME                      as "codigoUnidadeOperacional",
  cfe.registration_number       as "numeroCnpjFilial",
  cfe.establishment_name        as "nomeFilial",
  to_char(sysdate,'YYYY-MM-DD') as "dataCriacao",
  rcta.trx_number               as "numeroNotaFiscal",
  (
  select distinct rbsa.global_attribute3
  from 
    ra_batch_sources_all     rbsa
    ,ra_customer_trx_all     rcta1
    ,jl_br_customer_trx_exts xna 
  where 1=1
    and rbsa.batch_source_id  = rcta1.batch_source_id
    and xna.customer_trx_id   = rcta1.customer_trx_id
    and rcta1.trx_number      = rcta.trx_number
    and rcta1.customer_trx_id = rcta.customer_trx_id
  )                                    as "codigoSerie",
  to_char(rcta.trx_date,'YYYY-MM-DD')  as "dataEmissao",
  hca.account_number                   as "codigoCliente",
  rcta.ship_to_site_use_id             as "numeroPropriedadeEntrega",
  rcta.bill_to_site_use_id             as "numeroPropriedadeFaturamento",
  NULL                                 as "observacao",
  jbcte.electronic_inv_status          as "statusSefaz",
  jbcte.electronic_inv_access_key      as "codigoChaveAcessoSefaz"
from
  ra_customer_trx_all        rcta,
  ra_customer_trx_lines_all  rctla,
  hr_operating_units         hou,
  hz_cust_accounts           hca,
  cll_f255_establishment_v   cfe,
  jl_br_customer_trx_exts    jbcte
where 1=1
  and rcta.customer_trx_id          = rctla.customer_trx_id
  and rcta.org_id                   = hou.organization_id
  and rcta.bill_to_customer_id      = hca.cust_account_id
  and rcta.complete_flag            = 'Y'
  and rctla.line_type               = 'LINE'
  and rcta.status_trx               in ('OP','VD') 
  and cfe.inventory_organization_id = rctla.warehouse_id
  and rcta.customer_trx_id          = jbcte.customer_trx_id (+) 
  --and rcta.customer_trx_id = 77055
  --and jbcte.electronic_inv_access_key is not null
;
/