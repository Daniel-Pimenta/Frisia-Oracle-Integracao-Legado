set serveroutput on;
declare
  p_retorno  clob;
  x_retorno  varchar2(3000);
begin
  XXFR_RI_PCK_INT_NFDEVOLUCAO.processar_devolucao(-169, p_retorno);
  dbms_output.put_line(x_retorno);
end;
/

      select ie.*
      from 
        cll_f189_invoices_interface ii,
        cll_f189_interface_errors   ie
      where 1=1
        and ii.interface_invoice_id   = ie.interface_invoice_id
        and ii.source                 = ie.source
        and ii.source                 = 'XXFR_NFE_DEV_FORNECEDOR'
        and ie.interface_operation_id = w_interface_operation_id
      order by ie.creation_date
    ;


select * 
from ar.ra_interface_lines_all 
where 1=1
  and INTERFACE_LINE_CONTEXT = 'CLL F189 INTEGRATED RCV'
  --and INTERFACE_LINE_ATTRIBUTE3 = 203934 -- Invoice_Id do RI
  --and INTERFACE_LINE_ATTRIBUTE1 = 165    -- Operation_id do RI
order by creation_date desc ;



select ri.invoice_type_id, ri.invoice_type_code, ri.organization_id, ri.ar_transaction_type_id, ri.ar_source_id, ar.name, ar.description 
from 
  cll_f189_invoice_types ri,
  ra_batch_sources_all   ar
where 1=1
  and ar.BATCH_SOURCE_ID = ri.ar_source_id 
  and ri.invoice_type_code='DCO009'
  and ri.organization_id = 123
;


select * from oe_transaction_types_all 
where 1=1
  and WAREHOUSE_ID = 123
  and TRANSACTION_TYPE_ID=24004
;

select rbs.* --distinct rbs.batch_source_id, rbs.name batch_source_name
from 
  oe_transaction_types_all tta, 
  ra_batch_sources_all     rbs
where 1=1
  and rbs.batch_source_id = tta.invoice_source_id
  and BATCH_SOURCE_ID=5001
;

select * from ra_batch_sources_all
where 1=1
  and BATCH_SOURCE_ID=5001
;

/*

select request_id 
from 
apps.fnd_concurrent_requests 
where 1=1
  and priority_request_id = 1946126
  and request_id <> priority_request_id
;

XXFR - AR - Importação da interface de transações (Conjunto de Relatórios)
XXFR - AR - Pré Processo NF                - XXFR_AR_PCK_PRE_PROCESSO_NF.prc_pre_processo
Programa-mestre de NFFs Automáticas        - RAXMTR
Programa de Importação de NFFs Automáticas - RAXTRX  
XXFR - AR - Pós Processo NF                - XXFR_AR_PCK_POS_PROCESSO_NF.prc_pos_processo


select * 
from XXFR_RI_VW_INF_DA_NFENTRADA
where 1=1
  and TRX_NUMBER = '985';
  and serie = 'NFE_000108_SERIE_0_AUTO'

select * from 
xxfr_ri_vw_inf_da_linha_nfe
where customer_trx_id = 134014;


select * --CUSTOMER_TRX_ID, TRX_DATE, INTERFACE_STATUS, REQUEST_ID, RESET_TRX_DATE_FLAG, LINE_NUMBER, interface_line_attribute1 operation_id, warehouse_id, interface_line_attribute3 invoice_id, batch_source_name, INTERFACE_LINE_CONTEXT
from ra_interface_lines_all 
where 1=1
  --and interface_line_attribute3 = '199943' --Invoice_id 
  --and request_id = 1904340
  and INTERFACE_LINE_CONTEXT = 'CLL F189 INTEGRATED RCV'
  --and BATCH_SOURCE_NAME = 'NFE_000108_SERIE_0_AUTO#[XXFR]'
order by CUSTOMER_TRX_ID, to_number(LINE_NUMBER)
;

select CUSTOMER_TRX_ID, TRX_NUMBER 
from ra_customer_trx_all 
where 1=1
  and request_id = 1904340
  and INTERFACE_HEADER_CONTEXT='CLL F189 INTEGRATED RCV'
;

select * from ra_customer_trx_lines_all where CUSTOMER_TRX_ID=216103;
select * from ra_batch_sources_all where NAME = 'NFE_000108_SERIE_0_AUTO';

select * from RA_INTERFACE_DISTRIBUTIONS_ALL;

select e.message_text, nvl(e.invalid_value,'NA') valor_invalido -- L.INTERFACE_LINE_ID, L.REQUEST_ID, L.INTERFACE_LINE_ATTRIBUTE3, L.INTERFACE_LINE_ATTRIBUTE4, L.CREATION_DATE
from 
  ra_interface_lines_all  l,
  ra_interface_errors_all e
where 1=1
  and l.interface_line_id         = e.interface_line_id
  and l.interface_line_context    ='CLL F189 INTEGRATED RCV'
  and l.batch_source_name         ='NFE_000108_SERIE_0_AUTO'
  and l.interface_line_attribute3 = 202940 -- RI Invoice_id
;


select * from ra_interface_salescredits_all where creation_date >= sysdate - 0.5;
RA_INTERFACE_LINES_ALL

select DS_ESCOPO, DS_LOG  
from xxfr_logger_logs_5_min
where 1=1 
  --and NM_UNIDADE like 'APPS.XXFR_WSH%'
  --and dt_criacao >= sysdate -1 
  and DS_ESCOPO like '%DEVOLUCAO_NF_COOPERADO%'
order by dt_criacao
;

*/


