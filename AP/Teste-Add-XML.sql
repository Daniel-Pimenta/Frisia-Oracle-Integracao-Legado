set SERVEROUTPUT ON;
declare
  
  ok         boolean;
  l_xml      xmltype;

  function get_pmt_ext_agg (p_payment_id in number) return xmltype
  is
    l_payment_currency_code  varchar2(10); 
    l_exchange_rate          number; 
    l_base_amount            number;
    l_taxa_usd               xmltype;
    
  begin
    begin
      select payment_currency_code,   exchange_rate,   base_amount 
      into   l_payment_currency_code, l_exchange_rate, l_base_amount
      from ap_invoices_all
      where invoice_id in (
        select distinct invoice_id 
        from ap_invoice_payments_all 
        where check_id in (
          select check_id from ap_checks_all where payment_id = p_payment_id
        )
      );
    exception
      when others then
        l_payment_currency_code := null;
    end;
    if (l_payment_currency_code = 'USD') then
      --build the XML string
      select xmlconcat( 
        xmlelement (
          "extend", 
          xmlelement ("exchangeRate", l_exchange_rate),
          xmlelement ("baseAmount", l_base_amount)
        )
      )
      into l_taxa_usd 
      from dual;
    else 
      return null;
    end if;
    return l_taxa_usd;
  end get_pmt_ext_agg;
  
begin
  l_xml := get_pmt_ext_agg(99008);
  dbms_output.put_line('XML:'||l_xml.getstringval() );
end;
/