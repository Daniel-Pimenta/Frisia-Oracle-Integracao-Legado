SET SERVEROUTPUT ON
DECLARE
  l_request_id        number;
  l_batch_source_id   number;
  l_batch_source_name varchar2(50) := 'NFE_000108_SERIE_0_AUTO';
  w_operation_id      number := 126;
  w_organization_id   number := 123;
  ok                  boolean := true;
BEGIN
  xxfr_pck_variaveis_ambiente.inicializar('AR','UO_FRISIA','JEAN.BEJES');
  
  --xxfr_f189_interface_pkg.ar (w_operation_id, w_organization_id) ; 
  
  select batch_source_id into l_batch_source_id from ra_batch_sources_all where name = l_batch_source_name;
  
  if (ok) then
  xxfr_pck_variaveis_ambiente.inicializar('CLL','UO_FRISIA','JEAN.BEJES'); 
    l_request_id:=fnd_request.submit_request(
      APPLICATION => 'AR',
      PROGRAM     => 'RAXMTR',
      DESCRIPTION => 'Autoinvoice Master Program',
      START_TIME  => to_char(sysdate, 'DD/MM/YYYY HH:MI:SS'),
      SUB_REQUEST => FALSE,
      ARGUMENT1   => '1',
      ARGUMENT2   => 81,
      ARGUMENT3   => l_batch_source_id,
      ARGUMENT4   => l_batch_source_name,
      ARGUMENT5   => TO_CHAR(SYSDATE,'DD/MM/YYYY HH:MI:SS'),
      ARGUMENT6   => '',
      ARGUMENT7   => '',
      ARGUMENT8   => '',
      ARGUMENT9   => '',
      ARGUMENT10  => '',
      ARGUMENT11  => '',
      ARGUMENT12  => '',
      ARGUMENT13  => '',
      ARGUMENT14  => '',
      ARGUMENT15  => '',
      ARGUMENT16  => '',
      ARGUMENT17  => '',
      ARGUMENT18  => '',
      ARGUMENT19  => '',
      ARGUMENT20  => '',
      ARGUMENT21  => '',
      ARGUMENT22  => '',
      ARGUMENT23  => '',
      ARGUMENT24  => '',
      ARGUMENT25  => '',
      ARGUMENT26  => 'Y',
      ARGUMENT27  => ''
    );
    COMMIT;
  end if;
  dbms_output.put_line('l_request_id :'||l_request_id);
end;
/

/*
select
INTERFACE_INVOICE_ID, INVOICE_ID, AP_INTERFACE_FLAG, PO_INTERFACE_FLAG, FISCAL_INTERFACE_FLAG, AR_INTERFACE_FLAG, FA_INTERFACE_FLAG
from cll_f189_invoices 
where INVOICE_ID = 1903908;

select * from ra_customer_trx_all where REQUEST_ID = 1903908;


*/