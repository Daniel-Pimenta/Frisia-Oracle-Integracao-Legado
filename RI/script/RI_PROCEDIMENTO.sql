set serveroutput on;
declare
  p_retorno  clob;
  x_retorno  varchar2(3000);
begin
  --XXFR_RI_PCK_INT_NFDEVOLUCAO.processar_devolucao(-323, p_retorno);
  XXFR_RI_PCK_INT_DEV_WORK.processar_devolucao(-318, p_retorno);
  --XXFR_RI_PCK_INT_NFDEVOLUCAO.auto_invoice(14628, p_retorno);
  dbms_output.put_line(x_retorno);
end;
/

/*

Cooperado PF: Org Inventário 011 / Recebimento 238 / NF 305
Terceiro  PF: Org Inventário 011 / Recebimento 211 / NF 319
Cooperado PJ: Org Inventário 061 / Recebimento 11 / NF 259
Terceiro  PJ:

select * from XXFR_RI_VW_INF_DA_INVOICE 
where 1=1
  --and operation_id = 362
  and invoice_num       in ('22','678')
  and ORGANIZATION_CODE = '051'
  --and INVOICE_TYPE_CODE = 'CMP014'
  --and ELETRONIC_INVOICE_KEY is not null --'99999999999999999999999999999999999999999999'
;

SELECT * FROM cll_f189_invoice_lines WHERE INVOICE_ID IN (174955,159971);



select * from xxfr_ri_vw_inf_da_nfentrada 
where 1=1
  and CUSTOMER_TRX_ID=132248


begin
xxfr_pck_variaveis_ambiente.inicializar('AR','UO_FRISIA');
end;


  --
SELECT * FROM cll_f189_query_customers_v  WHERE ENTITY_ID = 23274;
SELECT * FROM cll_f189_query_vendors_v  WHERE ENTITY_ID = 23274;
SELECT 

23274
LEGAL_ENTITY_ID

select * from RA_CUSTOMER_TRX_PARTIAL_V
WHERE CUSTOMER_TRX_ID=132248
    Num NF Devolucao:15


select * from XXFR_RI_VW_INF_DA_NFENTRADA
where 1=1
  --and Customer_trx_id = 245031
  and trx_number = '49'
  --and document_number = '54043875053'
  --and VENDOR_SITE_CODE = '2243.234525'
;

select a.customer_trx_id, a.serie, a.serie_number, a.cust_trx_type_id, c.name, a.warehouse_id
from
  xxfr_ri_vw_inf_da_nfentrada a
  ,cll_f255_establishment_v   e
  ,ra_cust_trx_types_all      c
where 1=1
  and e.inventory_organization_id = a.warehouse_id
  and c.end_date                  is null
  and c.cust_trx_type_id          = a.cust_trx_type_id
  and c.org_id                    = g_org_id
  and e.registration_number       = p_nf_devolucao.linha(l).nu_cnpj_emissor
  and a.trx_number                = p_nf_devolucao.linha(l).nu_nota_fiscal
  --and a.document_number           = p_nf_devolucao.cd_fornecedor
  and a.VENDOR_SITE_CODE          = p_nf_devolucao.cd_fornecedor||'.'||p_nf_devolucao.nu_propriedade_fornecedor
;


select * from cll_f189_invoices_interface 
where 1=1
  and source = 'XXFR_NFE_DEV_FORNECEDOR'
  --and PROCESS_FLAG IN ('3','1')
order by creation_date desc
;

select ELETRONIC_INVOICE_KEY 
from cll_f189_invoices
where ELETRONIC_INVOICE_KEY is not null
group by ELETRONIC_INVOICE_KEY having count(*) > 1; 


select 
  ELETRONIC_INVOICE_KEY, INVOICE_ID, INVOICE_TYPE_ID, comments, AR_INTERFACE_FLAG
from cll_f189_invoices
where ELETRONIC_INVOICE_KEY in (
  select ELETRONIC_INVOICE_KEY 
  from cll_f189_invoices
  where ELETRONIC_INVOICE_KEY is not null
  group by ELETRONIC_INVOICE_KEY having count(*) > 1
)
order by 1
;

select * from xxfr_integracao_detalhe 
WHERE 1=1
  and CD_INTERFACE_DETALHE = 'PROCESSAR_NF_DEVOLUCAO_FORNECEDOR'
  and ID_INTEGRACAO_DETALHE = 25356
order by 1 desc
  ; 

DEVOLUCAO_NF_FORNECEDOR_10637
select * from ra_interface_salescredits_all where creation_date >= sysdate - 0.5;



select id, DS_ESCOPO, DS_LOG  
from xxfr_logger_log
where 1=1 
  and dt_criacao >= sysdate -0.25
  and upper(DS_ESCOPO) like 'DEVOLUCAO_NF_FORNECEDOR_56939'
order by id
;


*/


