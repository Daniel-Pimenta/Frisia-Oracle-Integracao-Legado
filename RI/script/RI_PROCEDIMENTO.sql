set serveroutput on;
declare
  p_retorno  clob;
  x_retorno  varchar2(3000);
begin
  XXFR_RI_PCK_INT_NFDEVOLUCAO.processar_devolucao(-13, p_retorno);
  dbms_output.put_line(x_retorno);
end;
/


select * from xxfr_ri_vw_inf_da_nfentrada 
where 1=1
  --and ACCOUNT_NUMBER = 2056
  and TRX_NUMBER = '49'


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

select l.*
from 
  ra_interface_lines_all  l
where 1=1
  and l.interface_line_context    ='CLL F189 INTEGRATED RCV'
  --and l.batch_source_name         = w_batch_source_name
order by l.creation_date desc;

/*

select * from xxfr_integracao_detalhe 
WHERE 1=1
  and CD_INTERFACE_DETALHE = 'PROCESSAR_NF_DEVOLUCAO_FORNECEDOR'
  --and ID_INTEGRACAO_DETALHE = 10637
order by 1 desc
  ; 


select * 
from xxfr_ri_vw_inf_da_nfentrada
where 1=1
  and trx_number = '1405';
  and serie = 'NFE_000108_SERIE_0_AUTO'

select * from 
xxfr_ri_vw_inf_da_linha_nfe
where customer_trx_id = 134014;


DEVOLUCAO_NF_FORNECEDOR_10637
select * from ra_interface_salescredits_all where creation_date >= sysdate - 0.5;

select id, DS_ESCOPO, DS_LOG  
from xxfr_logger_log
where 1=1 
  and dt_criacao >= sysdate -1 
  and upper(DS_ESCOPO) = 'DEVOLUCAO_NF_FORNECEDOR_379'
order by dt_criacao, id
;


*/


