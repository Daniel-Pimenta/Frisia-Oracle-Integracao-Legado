CREATE OR REPLACE PACKAGE XXFR_IBY_EXTRACT_EXT_PUB AS
  function get_pmt_ext_agg(p_payment_id in number) return xmltype;
  function get_ins_ext_agg(p_payment_instruction_id in number) return xmltype;
END XXFR_IBY_EXTRACT_EXT_PUB;
/
CREATE OR REPLACE PACKAGE BODY XXFR_IBY_EXTRACT_EXT_PUB AS

  g_escopo                varchar2(50) := 'XXFR_IBY_EXTRACT_EXT_PUB';
  
  procedure print_log(msg   in Varchar2) is
  begin
    dbms_output.put_line(msg);
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => g_escopo
    );
  end;

  FUNCTION xscn_get_pay_func_amount(p_payment_id IN NUMBER) RETURN NUMBER IS
    cursor c1 is
      SELECT 
        ipa.payment_currency_code
        ,gl.currency_code ledger_currency_code
        ,ipa.payment_amount
        ,ipa.payment_process_request_name
        ,ipa.org_id
      FROM 
        apps.iby_payments_all   ipa
        ,apps.hr_operating_units hou
        ,apps.gl_ledgers         gl
      WHERE 1=1
        and ipa.org_id          = hou.organization_id
        AND hou.set_of_books_id = gl.ledger_id
        AND ipa.payment_id      = p_payment_id
    ;
    --
    l_npayment_amount   apps.iby_payments_all.payment_amount%TYPE;
    l_nexchange_rate    apps.ap_user_exchange_rates.exchange_rate%TYPE;
    --
  BEGIN
    l_npayment_amount := NULL;
    FOR x IN c1 LOOP
      IF x.payment_currency_code <> x.ledger_currency_code THEN
        --
        -- Pagamento feito lote
        --
        BEGIN
          SELECT asia.payment_exchange_rate
          INTO l_nexchange_rate
          FROM 
            apps.ap_selected_invoices_all asia
            ,apps.gl_ledgers               gl
          WHERE 1=1
            AND asia.set_of_books_id = gl.ledger_id
            AND asia.checkrun_name = x.payment_process_request_name
            AND asia.payment_currency_code = x.payment_currency_code
            AND gl.currency_code = x.ledger_currency_code
            AND nvl(asia.org_id, x.org_id) = x.org_id
          GROUP BY asia.payment_exchange_rate;
          l_npayment_amount := round(x.payment_amount * l_nexchange_rate, 2);
        EXCEPTION
          WHEN no_data_found THEN
            -- Pagamento feito pela tela rapida
            BEGIN
              SELECT aca.base_amount, aca.exchange_rate
              INTO l_npayment_amount, l_nexchange_rate
              FROM apps.ap_checks_all aca
              WHERE aca.payment_id = p_payment_id;
            EXCEPTION
              WHEN no_data_found THEN NULL;
            END;
        END;
      END IF;
      RETURN(l_npayment_amount);
    END LOOP;
  END xscn_get_pay_func_amount;


  function get_amount(p_payment_id in number, p_payment_instruction_id in number) return xmltype is
    l_payment_currency_code       varchar2(10); 
    l_payment_exchange_rate_type  varchar2(100);
    l_payment_exchange_rate       number :=0; 
    l_amount_paid                 number :=0;
    l_brl_amount_paid             number :=0;
    l_erro                        varchar2(400);
    l_qtd                         number;
    --
    l_retorno                     xmltype;
  begin
    select count(*) into l_qtd from ap_checks_all;
    print_log('  Qtd de linhas na AP_CHECKS_ALL :'||l_qtd);
    
    if (nvl(p_payment_id,0) = 0 and nvl(p_payment_instruction_id,0) = 0) then
      print_log('  Parametros = NULL ');
      return null;
    end if;
    
    begin
      select 
        aia.payment_currency_code,
        aip.exchange_rate, 
        aip.exchange_rate_type,
        sum(aia.amount_paid) amount_paid,
        sum(aia.amount_paid * nvl(aip.exchange_rate,1)) brl_amount_paid
      into l_payment_currency_code,l_payment_exchange_rate,l_payment_exchange_rate_type,l_amount_paid,l_brl_amount_paid
      from
        ap_invoices_all         aia,
        ap_invoice_payments_all aip,
        ap_checks_all           aca
      where 1=1
        and aia.org_id                 = aip.org_id
        and aia.invoice_id             = aip.invoice_id 
        and aip.check_id               = aca.check_id
        /*
        and (
          aca.payment_instruction_id = nvl(p_payment_instruction_id, 0)
          or 
          aca.payment_id             = nvl(p_payment_id, 0)
        )
        */
        and aca.payment_id in (
          select payment_id from iby_payments_all 
          where 1=1
            and (
              payment_instruction_id = nvl(p_payment_instruction_id, 0)
              or 
              payment_id             = nvl(p_payment_id, 0)
            )
        )        
      group by  
        aia.payment_currency_code,
        aip.exchange_rate, 
        aip.exchange_rate_type
      ;
    exception
      when others then
        l_payment_currency_code := null;
        l_payment_exchange_rate := 1;
        l_erro := '['||nvl(p_payment_id, p_payment_instruction_id)||'] - '||sqlerrm;
        print_log('  Erro:'||l_erro);
    end;
    if (l_payment_currency_code is null) then
      l_payment_exchange_rate_type := l_erro;
    end if;
    --build the XML string
    select xmlconcat( 
      xmlelement (
        "XXFR", 
        xmlelement ("XXFR_MOEDA"          , l_payment_currency_code),
        xmlelement ("XXFR_TIPO_TAXA"      , l_payment_exchange_rate_type),
        xmlelement ("XXFR_TAXA_USD"       , nvl(l_payment_exchange_rate,1)),
        xmlelement ("XXFR_AMOUNT_PAID"    , l_amount_paid),
        xmlelement ("XXFR_BRL_AMOUNT_PAID", l_brl_amount_paid)
      )
    )
    into l_retorno 
    from dual;
    print_log('  --- XML de Retorno --------');
    print_log('  '||l_retorno.getstringval());
    print_log('  --- FIM XML de Retorno --------');
    return l_retorno;
  end;

  function get_pmt_ext_agg(p_payment_id in number) return xmltype is
    l_xxfr_agg              xmltype;
  begin
    print_log('----------------------------------------------------------------');
    print_log('Inicio GET_PMT_EXT_AGG - '||to_char(sysdate,'dd/mm/yyyy - hh24:mi:ss')|| ' - '|| p_payment_id);
    print_log('----------------------------------------------------------------');
    --
    l_xxfr_agg := get_amount(p_payment_id, null);
    --
    print_log('----------------------------------------------------------------');
    print_log('Fim GET_PMT_EXT_AGG - '||to_char(sysdate,'dd/mm/yyyy - hh24:mi:ss')|| ' - '|| p_payment_id);
    print_log('----------------------------------------------------------------');
    return l_xxfr_agg ;
  end;

  function get_ins_ext_agg(p_payment_instruction_id in number) return xmltype is
    l_xxfr_agg              xmltype;
  begin
    print_log('----------------------------------------------------------------');
    print_log('Inicio GET_INS_EXT_AGG - '||to_char(sysdate,'dd/mm/yyyy - hh24:mi:ss')|| ' - '|| p_payment_instruction_id);
    print_log('----------------------------------------------------------------');
    --
    l_xxfr_agg := get_amount(null, p_payment_instruction_id);
    --
    print_log('----------------------------------------------------------------');
    print_log('Fim GET_INS_EXT_AGG - '||to_char(sysdate,'dd/mm/yyyy - hh24:mi:ss')|| ' - '|| p_payment_instruction_id);
    print_log('----------------------------------------------------------------');
    return l_xxfr_agg ;
  end;
  
END XXFR_IBY_EXTRACT_EXT_PUB;
/