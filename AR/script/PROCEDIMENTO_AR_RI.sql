set serveroutput on
declare 
  p_customer_trx_id number;
  x_retorno         varchar2(3000);
begin 
  XXFR_AR_PCK_GERA_RI.main2(
    p_customer_trx_id   => 124256, 
    p_processar         => false, --  <-- Indica se processa a Interface ou n�o
    p_sequencial        => '222',
    x_retorno           => x_retorno
  );
  dbms_output.put_line(x_retorno);
end ;
/

/*
select * from xxfr_ri_vw_inf_da_nfentrada where TRX_NUMBER = '14';

select *
from cll_f189_invoices_interface 
where 1=1
  --and PROCESS_FLAG IN ('3','1')
  --and source       in ('XXFR_NFE_FORNECEDOR','XXFR_NFE_DEV_FORNECEDOR')
order by creation_date desc
;

select * from cll_f189_invoices_interface where interface_invoice_id = 81447;

select CUSTOMER_NUMBER, DOCUMENT_NUMBER, CUST_ACCT_SITE_ID from CLL_F189_QUERY_CUSTOMERS_V where document_number = '15897982953';

select * from CLL_F189_QUERY_VENDORS_V where entity_id = 17222; --document_number = '15897982953';

select object_name from all_objects where object_type='VIEW' and object_name like 'CLL_F189%';

set serveroutput on
declare
  l_retorno   varchar2(30);
begin
  l_retorno := CLL_F189_VALID_RULES_PKG.GET_GENERIC_VALIDATION_RULES(
    p_lookup_type        => 'CLL_F189_FISCAL_DOCUMENT_MODEL',
    p_code              => '55',
    p_invoice_type_id   => 9024, --REMESSA P/ DEPOSITO, MERC.COM PREVISAO DE POSTERIOR AJUSTE OU FIX.PRECO - ATO COOPERATIVO (CMP005) e (CMP014)
    p_validity_type     => 'FISCAL DOCUMENT MODEL'
  );
  dbms_output.put_line('Saida:'||nvl(l_retorno,'ERRO'));
end;
/


SELECT MEANING
FROM fnd_lookup_values_vl
WHERE 1=1
  and lookup_type = 'CLL_F189_FISCAL_DOCUMENT_MODEL'
  AND lookup_code = '55'
  AND NVL(end_date_active,SYSDATE + 1) > SYSDATE
  AND (NOT EXISTS 
    (
      SELECT 1
      FROM cll_f189_validity_rules cfvr
      WHERE 1=1
      and cfvr.invoice_type_id = 9024
      AND cfvr.validity_type   = 'FISCAL DOCUMENT MODEL'
    )
  OR lookup_code IN (
    SELECT cfvr.validity_key_1
    FROM cll_f189_validity_rules cfvr
    WHERE 1=1
      and cfvr.invoice_type_id = 9024
      AND cfvr.validity_type   = 'FISCAL DOCUMENT MODEL'
)
);



select * from cll_f189_invoices_interface
order by creation_date desc  
;

select * from q_pc_transferencia_ar_ri_v;


/*

select * from dba_objects where 1=1
  AND object_type = 'PACKAGE' 
  and object_name like 'CLL_F189%'
order by 2
;


set serveroutput on
declare
  l_holds number;
begin
  xxfr_pck_variaveis_ambiente.inicializar('CLL','UO_FRISIA','JEAN.BEJES');
  l_holds := CLL_F189_HOLDS_CUSTOM_PKG.FUNC_HOLDS_CUSTOM (
    535, --p_interface_operation_id
    123 --p_organization_id     
  );
  dbms_output.put_line('Holds:'||l_holds);
exception when others then
  dbms_output.put_line(sqlerrm);
end;
/

4003; --  NAO SE APLICA

SELECT TERM_ID, END_DATE_ACTIVE, NAME, DESCRIPTION FROM AP_TERMS;


select ds_escopo, nvl(ds_log,' ') log
from xxfr_logger_log
where 1=1
  and upper(ds_escopo) like 'XXFR_RI_PCK_INTEGRACAO_AR_%'
  and DT_CRIACAO >= sysdate -0.25
order by 
  DT_CRIACAO desc
;

select * from xxfr_ri_vw_inf_da_nfentrada
where 
CUSTOMER_TRX_ID=242033;

select * from xxfr_ri_vw_inf_da_linha_nfe
where 
CUSTOMER_TRX_ID=242033;

select PO_HEADER_ID, PO_LINE_ID from po_line_locations_all where LINE_LOCATION_ID=225098;

*/

