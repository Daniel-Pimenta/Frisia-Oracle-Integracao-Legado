set serveroutput on
declare
  x_retorno             varchar2(3000);
  x_cod_retorno         number;
    l_organization_id   number := 123;
    l_operation_id      number := 236;
  
begin

  dbms_output.put_line('Chamando CLL_F189_WMS_PKG.INSERT_RCV_TABLES...');
  cll_f189_wms_pkg.insert_rcv_tables (
    p_organization_id   => l_organization_id,
    p_operation_id      => l_operation_id,
    errbuf              => x_retorno,
    retcode             => x_cod_retorno
  );
  dbms_output.put_line('Retorno    :'||x_retorno);
  dbms_output.put_line('Cod Retorno:'||x_cod_retorno);
  dbms_output.put_line('');

  dbms_output.put_line('Chamando CLL_F189_WMS_PKG.APPROVE_RECEIPT...');
  cll_f189_wms_pkg.approve_receipt (
    p_organization_id   => l_organization_id,
    p_operation_id      => l_operation_id,
    errbuf              => x_retorno,
    retcode             => x_cod_retorno
  );
  dbms_output.put_line('Retorno    :'||x_retorno);
  dbms_output.put_line('Cod Retorno:'||x_cod_retorno);
  COMMIT;
end;
/

select 
  ri.operation_id,
  ri.invoice_num,
  ril.receipt_flag,
  ril.shipment_header_id,
  ri.creation_date
from 
  cll_f189_invoices      ri, 
  cll_f189_invoice_lines ril
where 1=1
  --and ri.operation_id in (235, 236, 238)
  --and ri.organization_id = 123 
  and ri.invoice_id      = ril.invoice_id
  and exists(
    select '1'
    from rcv_transactions rcv
    where 1=1
      and rcv.shipment_header_id = ril.shipment_header_id
      --and rcv.transaction_type = 'DELIVER'
  )
order by ri.creation_date desc
;


select * from rcv_headers_interface;
select * from rcv_transactions_interface;
select * from rcv_shipment_headers order by creation_date desc;
select * from rcv_shipment_lines order by creation_date desc;
rcv_transactions         
mtl_material_transactions
