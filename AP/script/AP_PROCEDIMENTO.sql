set serveroutput on;
declare
    l_retorno      varchar2(20);
    l_mensagem     varchar2(3000);
    l_invoice_id   number;
    
    cursor c1 is
      select pha.org_id, pha.currency_code, pv.vendor_name, pla.unit_meas_lookup_code, pla.unit_price, pla.quantity,
        pha.segment1, pda.po_header_id, pda.po_line_id, pda.line_location_id, pda.po_distribution_id,
        pha.vendor_id, pha.vendor_site_id, pha.ship_to_location_id, pha.terms_id,
        pda.set_of_books_id, pda.code_combination_id,
        pla.item_id, pla.item_description, 
        pv.party_id,
        pvsa.party_site_id, pvsa.accts_pay_code_combination_id
      from 
        po_headers_all       pha,
        po_distributions_all pda,
        po_lines_all         pla,
        po_vendor_sites_all  pvsa,
        po_vendors           pv
      where 1=1
        and pha.po_header_id         = pda.po_header_id
        and pha.authorization_status = 'APPROVED'
        and pda.po_line_id           = pla.po_line_id
        and pvsa.vendor_site_id      = pha.vendor_site_id
        and pha.vendor_id            = pv.vendor_id
        and pha.currency_code        = 'USD'
        and pha.segment1             in ('172','363','464') --('482','161','575','110','95','503')
      order by pv.vendor_name
    ;
    
begin
  --
  --EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE= ''AMERICAN''';
  
  xxfr_pck_variaveis_ambiente.inicializar('SQLAP','UO_FRISIA'); -- Payables Super User Resp context
  mo_global.set_policy_context('S',fnd_profile.value('ORG_ID'));
  
  for r1 in c1 loop
    xxfr_ap_cust_invoice_create (
      p_segment1     => r1.segment1,
      p_qtd          => (r1.quantity /1000),
      x_invoice_id   => l_invoice_id,
      x_retorno      => l_retorno
    );
    dbms_output.put_line('Retorno :'||l_retorno);
    dbms_output.put_line('');
    --
    if (l_retorno = 'XXX') then
      xxfr_ap_cust_invoice_payments(
        p_invoice_id   => l_invoice_id,
        p_from_date    => null,
        p_to_date      => null,
        x_status       => l_retorno,
        x_err_msg      => l_mensagem
      );
      dbms_output.put_line('Retorno :'||l_retorno);
      dbms_output.put_line('Mensagem:'||l_mensagem);
    end if;
  end loop;
end;
/

Formatar Instruções de Pagamento com Saída de Texto

/*

select * from ap_invoices_all where 1=1 and invoice_num = '202081-X';

select * from ap_invoices_all where 1=1 and invoice_id in (202081);
select * from ap_invoice_payments_all where invoice_id = 200060 order by check_id;
SELECT * FROM AP_CHECKS_ALL WHERE check_id IN (SELECT check_id FROM AP_INVOICE_PAYMENTS_ALL WHERE invoice_id=202081);
select * from ap_payment_schedules_all where invoice_id = 202081;

select * from ap_documents_payable 
where 1=1
  and calling_app_id = 200 
  --and calling_app_doc_unique_ref2=202081
order by creation_date desc;

select * from po_headers_all where segment1='110'; --46005
select * from po_lines_all where po_header_id = 46005; --48023
select * from po_distributions_all where po_header_id = 46005; --47023
select * from po_line_locations_all where po_header_id = 46005;  --47024
select * from po_vendor_sites_all where party_site_id = 164390;
select * from po_vendors; 

select * from CE_BANK_ACCT_USES_ALL;


*/
