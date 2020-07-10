create or replace view XXFR_AR_VW_INF_DA_NF_CABECALHO as
select distinct
  rcta.customer_trx_id,
  rcta.trx_number,
  rcta.interface_header_context,
  cfe.location_id,
  rctla.warehouse_id  organization_id,            
  (
    select ood.organization_code 
    from org_organization_definitions ood 
    where ood.organization_id=rctla.warehouse_id 
  )                             as "codigoOrganizacaoInventario", 
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
  )                                    as "numeroSerie",
  rbs.name                             as "codigoSerie",
  --
  rctta.cust_trx_type_id,
  rctta.name                           as "codigoOrigemTransacao",
  null                                 as "tipoDocumento",
  --
  to_char(rcta.trx_date,'YYYY-MM-DD')  as "dataEmissao",
  hca.account_number                   as "codigoCliente",
  rcta.ship_to_site_use_id             as "numeroPropriedadeEntrega",
  rcta.bill_to_site_use_id             as "numeroPropriedadeFaturamento",
  NULL                                 as "observacao",
  jbcte.electronic_inv_status          as "statusSefaz",
  jbcte.electronic_inv_access_key      as "chaveNotaFiscal"
from
  ra_customer_trx_all        rcta,
  ra_customer_trx_lines_all  rctla,
  ra_cust_trx_types_all      rctta,
  hr_operating_units         hou,
  hz_cust_accounts           hca,
  cll_f255_establishment_v   cfe,
  jl_br_customer_trx_exts    jbcte,
  ra_batch_sources_all       rbs
where 1=1
  and rcta.customer_trx_id          = rctla.customer_trx_id
  and rcta.org_id                   = hou.organization_id
  and rcta.bill_to_customer_id      = hca.cust_account_id
  and rcta.complete_flag            = 'Y'
  and rctla.line_type               = 'LINE'
  and rcta.status_trx               in ('OP','VD') 
  --
  and rctta.cust_trx_type_id        = rcta.cust_trx_type_id
  and rctta.end_date                is null
  and rctta.org_id                  = rcta.org_id 
  --
  and cfe.inventory_organization_id = rctla.warehouse_id
  and rcta.customer_trx_id          = jbcte.customer_trx_id (+) 
  and rcta.batch_source_id          = rbs.batch_source_id
  and rbs.org_id                    = rcta.org_id
  --and rcta.customer_trx_id = 77055
  --and jbcte.electronic_inv_access_key is not null
;
/

/*

select * from XXFR_AR_VW_INF_DA_NF_CABECALHO 
where 1=1
  --and "numeroNotaFiscal"='131'
  --and "codigoOrigemTransacao"='UBS_VENDA'
  --and "codigoOrganizacaoInventario" = '124'
  and customer_trx_id = 128263
order by 8 desc;

select * from ra_customer_trx_all;

*/