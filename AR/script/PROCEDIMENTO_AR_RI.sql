set serveroutput on
declare
  p_customer_trx_id number;
  x_retorno         varchar2(3000);
begin 
  XXFR_AR_PCK_GERA_RI.processar(
    p_customer_trx_id   => 253033, 
    x_retorno           => x_retorno
  );
  dbms_output.put_line(x_retorno);
end ;
/

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


        select r.*
        from 
          cll_f189_validity_rules r,
          cll_f189_invoice_types  t
        where 1=1
          and t.invoice_type_id   = r.invoice_type_id
          and t.organization_id   = r.organization_id
          and t.organization_id   = 123 --r1.warehouse_id
          and t.invoice_type_code = 'CMP014' --g_invoice_type_code
          and r.VALIDITY_TYPE     = 'INVOICE SERIES'
        order by 3;     

    select INVOICE_ID, INVOICE_NUM, ENTITY_ID, ORGANIZATION_ID, LOCATION_ID, OPERATION_ID, SERIES, INVOICE_TYPE_ID, INTERFACE_INVOICE_ID 
    from cll_f189_invoices 
    where 1=1
      and INVOICE_NUM = '525001' 
      and interface_invoice_id = 96420
    order by creation_date desc;
    
    select ORGANIZATION_ID, LOCATION_ID, OPERATION_ID, STATUS 
    from CLL_F189_ENTRY_OPERATIONS where 1=1
    and SOURCE like 'XXFR%'
    and OPERATION_ID = 37
    
    select * from cll_f189_invoice_lines where 1=1
    and attribute_category like 'XXFR%'
    order by creation_date desc;


SELECT * FROM ra_customer_trx_all 
WHERE 1=1 
  --and CUSTOMER_TRX_ID = 240042
  and TRX_NUMBER = '1351'
;

select * from cll_f189_invoices_interface 
where 1=1
  and source like 'XXFR%' --_NFE_COOPERADO' 
  --and PROCESS_FLAG IN ('3','1')
order by creation_date desc;

select * from cll_f189_invoice_lines_iface 
where INTERFACE_INVOICE_ID in (select INTERFACE_INVOICE_ID from cll_f189_invoices_interface where source like 'XXFR%')
order by creation_date desc;